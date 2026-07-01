from decimal import Decimal
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q, Count, Value, IntegerField, OuterRef, Subquery, Avg, Sum
from django.utils import timezone
from django.http import HttpResponse
from drf_spectacular.utils import extend_schema, OpenApiParameter

from .models import Animal, Produccion, SyncStatus, Empadre, Parto, Costo, VentaFibra, RAZAS_POR_ESPECIE
from .utils import calcular_categoria_edad, calcular_coeficiente_consanguinidad
from .serializers import (
    AnimalSerializer, AnimalListSerializer, CandidatoSerializer,
    SyncInputSerializer, SyncOutputAnimalSerializer,
    SyncOutputSerializer,
    ProduccionSerializer,
    SyncOutputProduccionSerializer,
    ConsanguinidadSerializer,
    EmpadreSerializer, EmpadreListSerializer,
    PartoSerializer, PartoListSerializer,
    CostoSerializer, CostoListSerializer,
    VentaFibraSerializer, VentaFibraListSerializer,
    RankingFibraSerializer,
)


class AnimalViewSet(viewsets.ModelViewSet):
    serializer_class = AnimalSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'uid'
    lookup_url_kwarg = 'pk'

    def get_serializer_class(self):
        if self.action == 'list':
            return AnimalListSerializer
        if self.action == 'candidatos':
            return CandidatoSerializer
        return AnimalSerializer

    def get_queryset(self):
        queryset = Animal.objects.filter(usuario=self.request.user)
        if self.action == 'list':
            especie = self.request.query_params.get('especie')
            if especie:
                queryset = queryset.filter(especie=especie)
            sexo = self.request.query_params.get('sexo')
            if sexo:
                queryset = queryset.filter(sexo=sexo)
            estado = self.request.query_params.get('estado')
            if estado:
                queryset = queryset.filter(estado=estado.upper())
            search = self.request.query_params.get('search')
            if search:
                queryset = queryset.filter(
                    Q(arete__icontains=search) | Q(nombre__icontains=search)
                )
        return queryset.select_related('padre', 'madre')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user, sync_status=SyncStatus.SIC)

    def perform_destroy(self, instance):
        instance.estado = 'VENDIDO'
        instance.save()

    @extend_schema(
        parameters=[
            OpenApiParameter(name='especie', type=str),
            OpenApiParameter(name='sexo', type=str),
            OpenApiParameter(name='estado', type=str),
            OpenApiParameter(name='search', type=str),
        ]
    )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    @action(detail=True, methods=['get'])
    def arbol(self, request, pk=None):
        animal = self.get_object()
        max_generations = request.user.generations_allowed

        def build_tree(a, depth=0):
            if a is None or depth > max_generations:
                return None
            node = {
                'uid': str(a.uid),
                'arete': a.arete,
                'nombre': a.nombre,
                'especie': a.especie,
                'sexo': a.sexo,
                'estado': a.estado,
                'fecha_nacimiento': a.fecha_nacimiento.isoformat() if a.fecha_nacimiento else None,
                'foto': request.build_absolute_uri(a.foto.url) if a.foto else None,
                'categoria_edad': calcular_categoria_edad(a.especie, a.fecha_nacimiento),
            }
            if depth < max_generations:
                node['padre'] = build_tree(a.padre, depth + 1) if a.padre else None
                node['madre'] = build_tree(a.madre, depth + 1) if a.madre else None
            return node

        tree = build_tree(animal)
        return Response(tree)

    @action(detail=False, methods=['get'])
    def candidatos(self, request):
        queryset = Animal.objects.filter(
            usuario=request.user, estado='VIVO'
        ).order_by('arete')
        especie = request.query_params.get('especie')
        if especie:
            queryset = queryset.filter(especie=especie)
        sexo = request.query_params.get('sexo')
        if sexo:
            queryset = queryset.filter(sexo=sexo)
        include_uids = request.query_params.get('include_uids')
        if include_uids:
            uids = [u.strip() for u in include_uids.split(',') if u.strip()]
            extra = Animal.objects.filter(usuario=request.user, uid__in=uids)
            queryset = (queryset | extra).distinct()
        serializer = CandidatoSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get', 'post'])
    def producciones(self, request, pk=None):
        animal = self.get_object()
        if request.method == 'POST':
            serializer = ProduccionSerializer(
                data=request.data,
                context={'request': request, 'animal': animal}
            )
            serializer.is_valid(raise_exception=True)
            serializer.save(animal=animal, sync_status=SyncStatus.SIC)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        queryset = animal.producciones.all()
        serializer = ProduccionSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def resumen(self, request):
        qs = Animal.objects.filter(usuario=request.user, estado='VIVO')
        total = qs.count()
        machos = qs.filter(sexo='macho').count()
        hembras = qs.filter(sexo='hembra').count()
        alpaca = qs.filter(especie='alpaca').count()
        llama = qs.filter(especie='llama').count()
        ovino = qs.filter(especie='ovino').count()
        user = request.user
        return Response({
            'total': total,
            'machos': machos,
            'hembras': hembras,
            'alpaca': alpaca,
            'llama': llama,
            'ovino': ovino,
            'plan': user.plan,
            'limite': user.limite_animales,
        })

    @action(detail=False, methods=['get'])
    def razas_por_especie(self, request):
        return Response(RAZAS_POR_ESPECIE)


class ProduccionViewSet(viewsets.ModelViewSet):
    serializer_class = ProduccionSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'uid'
    lookup_url_kwarg = 'pk'
    http_method_names = ['get', 'put', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return Produccion.objects.filter(
            animal__usuario=self.request.user
        ).select_related('animal')

    def perform_destroy(self, instance):
        instance.delete()


class SyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        request=SyncInputSerializer,
        responses={200: {'type': 'object'}}
    )
    def post(self, request):
        serializer = SyncInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        last_sync = serializer.validated_data.get('last_sync')
        changes = serializer.validated_data.get('changes', [])

        created_or_updated_uids = {}
        processed_uids = []

        user = request.user

        for change in changes:
            action = change.get('action', 'create')
            uid = change.get('uid')

            if action == 'delete':
                try:
                    animal = Animal.objects.get(uid=uid, usuario=user)
                    animal.estado = 'VENDIDO'
                    animal.sync_status = SyncStatus.SIC
                    animal.save()
                    processed_uids.append(str(uid))
                except Animal.DoesNotExist:
                    pass
                continue

            if action == 'create' and Animal.objects.filter(uid=uid, usuario=user).count() == 0:
                if user.animales_count >= user.limite_animales:
                    continue

            animal_data = {
                'arete': change['arete'],
                'especie': change['especie'],
                'sexo': change['sexo'],
                'fecha_nacimiento': change['fecha_nacimiento'],
                'nombre': change.get('nombre', ''),
                'raza': change.get('raza', ''),
                'observaciones': change.get('observaciones', ''),
                'estado': change.get('estado', 'VIVO'),
                'sync_status': SyncStatus.SIC,
            }

            if action == 'create':
                existing = Animal.objects.filter(uid=uid, usuario=user).first()
                if existing:
                    if change.get('local_updated_at') and existing.updated_at < change['local_updated_at']:
                        for key, value in animal_data.items():
                            setattr(existing, key, value)
                        existing.save()
                        created_or_updated_uids[uid] = existing
                else:
                    animal = Animal.objects.create(uid=uid, usuario=user, **animal_data)
                    created_or_updated_uids[uid] = animal
                processed_uids.append(str(uid))

            elif action == 'update':
                try:
                    animal = Animal.objects.get(uid=uid, usuario=user)
                    local_updated = change.get('local_updated_at')
                    if not local_updated or animal.updated_at < local_updated:
                        for key, value in animal_data.items():
                            setattr(animal, key, value)
                        animal.save()
                        created_or_updated_uids[uid] = animal
                    else:
                        created_or_updated_uids[uid] = animal
                    processed_uids.append(str(uid))
                except Animal.DoesNotExist:
                    pass

        for change in changes:
            uid = change.get('uid')
            if uid not in created_or_updated_uids:
                continue
            animal = created_or_updated_uids[uid]

            padre_uid = change.get('padre_uid')
            madre_uid = change.get('madre_uid')

            if padre_uid and padre_uid in created_or_updated_uids:
                animal.padre = created_or_updated_uids[padre_uid]
            elif padre_uid:
                padre = Animal.objects.filter(uid=padre_uid, usuario=user).first()
                if padre and padre.sexo != 'macho':
                    padre = None
                animal.padre = padre

            if madre_uid and madre_uid in created_or_updated_uids:
                animal.madre = created_or_updated_uids[madre_uid]
            elif madre_uid:
                madre = Animal.objects.filter(uid=madre_uid, usuario=user).first()
                if madre and madre.sexo != 'hembra':
                    madre = None
                animal.madre = madre

            animal.save()

        produccion_changes = serializer.validated_data.get('produccion_changes', [])

        for change in produccion_changes:
            action = change.get('action', 'create')
            uid = change.get('uid')
            animal_uid = change.get('animal_uid')

            if action == 'delete':
                Produccion.objects.filter(uid=uid, animal__usuario=user).delete()
                continue

            prod_data = {
                'fecha_esquila': change['fecha_esquila'],
                'peso_vellon_sucio_kg': change['peso_vellon_sucio_kg'],
                'peso_vellon_limpio_kg': change.get('peso_vellon_limpio_kg'),
                'numero_esquila': change.get('numero_esquila'),
                'observaciones': change.get('observaciones', ''),
                'sync_status': SyncStatus.SIC,
            }

            animal = Animal.objects.filter(uid=animal_uid, usuario=user).first()
            if not animal:
                continue

            if action == 'create':
                existing = Produccion.objects.filter(uid=uid).first()
                if not existing:
                    Produccion.objects.create(uid=uid, animal=animal, **prod_data)

            elif action == 'update':
                try:
                    prod = Produccion.objects.get(uid=uid, animal__usuario=user)
                    local_updated = change.get('local_updated_at')
                    if not local_updated or prod.updated_at < local_updated:
                        for key, value in prod_data.items():
                            setattr(prod, key, value)
                        prod.save()
                except Produccion.DoesNotExist:
                    pass

        animal_qs = Animal.objects.filter(usuario=request.user)
        prod_qs = Produccion.objects.filter(animal__usuario=request.user)
        if last_sync:
            animal_qs = animal_qs.filter(updated_at__gt=last_sync)
            prod_qs = prod_qs.filter(updated_at__gt=last_sync)

        animal_ser = SyncOutputAnimalSerializer(animal_qs, many=True)
        prod_ser = SyncOutputProduccionSerializer(prod_qs, many=True)

        return Response({
            'server_changes': animal_ser.data,
            'produccion_changes': prod_ser.data,
            'sync_timestamp': timezone.now().isoformat(),
            'processed': processed_uids
        })





class ConsanguinidadViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ConsanguinidadSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return Animal.objects.filter(
            usuario=self.request.user,
            padre__isnull=False,
            madre__isnull=False
        ).select_related('padre', 'madre')

    @action(detail=False, methods=['get'])
    def arbol(self, request):
        uid = request.query_params.get('uid')
        if not uid:
            return Response({'error': 'Se requiere el parámetro uid'}, status=400)
        try:
            animal = Animal.objects.get(uid=uid, usuario=request.user)
        except Animal.DoesNotExist:
            return Response({'error': 'Animal no encontrado'}, status=404)

        def build_tree(a, depth=0, max_depth=5):
            if a is None or depth > max_depth:
                return None
            hijo = calcular_coeficiente_consanguinidad(a)
            return {
                'uid': str(a.uid),
                'arete': a.arete,
                'nombre': a.nombre or '',
                'estado': a.estado,
                'coeficiente_consanguinidad': hijo,
                'padre': build_tree(a.padre, depth + 1, max_depth),
                'madre': build_tree(a.madre, depth + 1, max_depth),
            }

        return Response(build_tree(animal))


class EmpadreViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    lookup_field = 'uid'

    def get_serializer_class(self):
        if self.action == 'list':
            return EmpadreListSerializer
        return EmpadreSerializer

    def get_queryset(self):
        qs = Empadre.objects.filter(
            hembra__usuario=self.request.user
        ).select_related('hembra', 'macho').order_by('-fecha_empadre')
        hembra_uid = self.request.query_params.get('hembra_uid')
        if hembra_uid:
            qs = qs.filter(hembra__uid=hembra_uid)
        resultado = self.request.query_params.get('resultado')
        if resultado:
            qs = qs.filter(resultado=resultado)
        return qs

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)


class PartoViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    lookup_field = 'uid'

    def get_serializer_class(self):
        if self.action == 'list':
            return PartoListSerializer
        return PartoSerializer

    def get_queryset(self):
        return Parto.objects.filter(
            hembra__usuario=self.request.user
        ).select_related('hembra', 'empadre').order_by('-fecha_parto')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)


class CostoViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    lookup_field = 'uid'

    def get_serializer_class(self):
        if self.action == 'list':
            return CostoListSerializer
        return CostoSerializer

    def get_queryset(self):
        return Costo.objects.filter(
            animal__usuario=self.request.user
        ).select_related('animal').order_by('-fecha')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)


class VentaFibraViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None
    lookup_field = 'uid'

    def get_serializer_class(self):
        if self.action == 'list':
            return VentaFibraListSerializer
        return VentaFibraSerializer

    def get_queryset(self):
        return VentaFibra.objects.filter(
            animal__usuario=self.request.user
        ).select_related('animal', 'produccion').order_by('-fecha_venta')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)


class RankingFibraView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Animal.objects.filter(usuario=request.user).prefetch_related('producciones')
        ranking = []
        for animal in qs:
            ultima = animal.producciones.order_by('-fecha_esquila').first()
            if not ultima or not ultima.diametro_fibra_micras:
                continue
            ranking.append({
                'uid': str(animal.uid),
                'arete': animal.arete,
                'nombre': animal.nombre or '',
                'especie': animal.especie,
                'categoria_edad': calcular_categoria_edad(animal.especie, animal.fecha_nacimiento),
                'diametro_fibra_micras': float(ultima.diametro_fibra_micras),
                'factor_confort': float(ultima.factor_confort) if ultima.factor_confort else None,
                'medulacion_pct': float(ultima.medulacion_pct) if ultima.medulacion_pct else None,
                'rendimiento_pct': float(ultima.rendimiento_pct) if ultima.rendimiento_pct else None,
                'fecha_esquila': ultima.fecha_esquila,
                'numero_esquila': ultima.numero_esquila,
            })
        ranking.sort(key=lambda x: (x['diametro_fibra_micras'] is None, x['diametro_fibra_micras']))
        return Response(ranking[:100])


