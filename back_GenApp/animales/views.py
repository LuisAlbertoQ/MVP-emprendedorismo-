from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.renderers import BaseRenderer
from django.db.models import Q, Count
from django.utils import timezone
from django.http import HttpResponse
from drf_spectacular.utils import extend_schema, OpenApiParameter
import csv
import io
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle


class CSVRenderer(BaseRenderer):
    media_type = 'text/csv'
    format = 'csv'

    def render(self, data, media_type=None, renderer_context=None):
        return data


class PDFRenderer(BaseRenderer):
    media_type = 'application/pdf'
    format = 'pdf'

    def render(self, data, media_type=None, renderer_context=None):
        return data

from .models import Animal, Produccion, SyncStatus
from .utils import calcular_categoria_edad
from .serializers import (
    AnimalSerializer, AnimalListSerializer, CandidatoSerializer,
    SyncInputSerializer, SyncOutputAnimalSerializer,
    SyncOutputSerializer,
    ProduccionSerializer,
    SyncOutputProduccionSerializer,
    ReporteSerializer
)


class IsPaidPlan(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.plan in ['basico', 'criador']


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
            queryset = queryset.filter(activo=True)
            especie = self.request.query_params.get('especie')
            if especie:
                queryset = queryset.filter(especie=especie)
            sexo = self.request.query_params.get('sexo')
            if sexo:
                queryset = queryset.filter(sexo=sexo)
            activo = self.request.query_params.get('activo')
            if activo is not None:
                queryset = queryset.filter(activo=activo.lower() == 'true')
            search = self.request.query_params.get('search')
            if search:
                queryset = queryset.filter(
                    Q(arete__icontains=search) | Q(nombre__icontains=search)
                )
        return queryset.select_related('padre', 'madre')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user, sync_status=SyncStatus.SIC)

    def perform_destroy(self, instance):
        instance.activo = False
        instance.deleted_at = timezone.now()
        instance.save()

    @extend_schema(
        parameters=[
            OpenApiParameter(name='especie', type=str),
            OpenApiParameter(name='sexo', type=str),
            OpenApiParameter(name='activo', type=bool),
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
            usuario=request.user, activo=True
        ).order_by('arete')
        especie = request.query_params.get('especie')
        if especie:
            queryset = queryset.filter(especie=especie)
        serializer = CandidatoSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get', 'post'])
    def producciones(self, request, pk=None):
        animal = self.get_object()
        if request.method == 'POST':
            serializer = ProduccionSerializer(
                data=request.data,
                context={'request': request}
            )
            serializer.is_valid(raise_exception=True)
            serializer.save(animal=animal, sync_status=SyncStatus.SIC)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        queryset = animal.producciones.all()
        serializer = ProduccionSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def resumen(self, request):
        qs = Animal.objects.filter(usuario=request.user, activo=True)
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

        for change in changes:
            action = change.get('action', 'create')
            uid = change.get('uid')

            if action == 'delete':
                try:
                    animal = Animal.objects.get(uid=uid, usuario=request.user)
                    animal.activo = False
                    animal.deleted_at = timezone.now()
                    animal.sync_status = SyncStatus.SIC
                    animal.save()
                    processed_uids.append(str(uid))
                except Animal.DoesNotExist:
                    pass
                continue

            animal_data = {
                'arete': change['arete'],
                'especie': change['especie'],
                'sexo': change['sexo'],
                'fecha_nacimiento': change['fecha_nacimiento'],
                'nombre': change.get('nombre', ''),
                'raza': change.get('raza', ''),
                'observaciones': change.get('observaciones', ''),
                'activo': change.get('activo', True),
                'sync_status': SyncStatus.SIC,
            }

            if action == 'create':
                existing = Animal.objects.filter(uid=uid, usuario=request.user).first()
                if existing:
                    if change.get('local_updated_at') and existing.updated_at < change['local_updated_at']:
                        for key, value in animal_data.items():
                            setattr(existing, key, value)
                        existing.save()
                        created_or_updated_uids[uid] = existing
                else:
                    animal = Animal.objects.create(uid=uid, usuario=request.user, **animal_data)
                    created_or_updated_uids[uid] = animal
                processed_uids.append(str(uid))

            elif action == 'update':
                try:
                    animal = Animal.objects.get(uid=uid, usuario=request.user)
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
                animal.padre = Animal.objects.filter(uid=padre_uid, usuario=request.user).first()

            if madre_uid and madre_uid in created_or_updated_uids:
                animal.madre = created_or_updated_uids[madre_uid]
            elif madre_uid:
                animal.madre = Animal.objects.filter(uid=madre_uid, usuario=request.user).first()

            animal.save()

        produccion_changes = serializer.validated_data.get('produccion_changes', [])

        for change in produccion_changes:
            action = change.get('action', 'create')
            uid = change.get('uid')
            animal_uid = change.get('animal_uid')

            if action == 'delete':
                Produccion.objects.filter(uid=uid, animal__usuario=request.user).delete()
                continue

            prod_data = {
                'fecha_esquila': change['fecha_esquila'],
                'peso_vellon_kg': change['peso_vellon_kg'],
                'rendimiento_pct': change.get('rendimiento_pct'),
                'observaciones': change.get('observaciones', ''),
                'sync_status': SyncStatus.SIC,
            }

            animal = Animal.objects.filter(uid=animal_uid, usuario=request.user).first()
            if not animal:
                continue

            if action == 'create':
                existing = Produccion.objects.filter(uid=uid).first()
                if not existing:
                    Produccion.objects.create(uid=uid, animal=animal, **prod_data)

            elif action == 'update':
                try:
                    prod = Produccion.objects.get(uid=uid, animal__usuario=request.user)
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


class ReporteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsPaidPlan]
    renderer_classes = [CSVRenderer, PDFRenderer]

    def perform_content_negotiation(self, request, force_format=None):
        fmt = request.query_params.get('format', 'csv')
        for renderer in self.renderer_classes:
            if renderer.format == fmt:
                return (renderer, renderer.media_type)
        return (self.renderer_classes[0], self.renderer_classes[0].media_type)

    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        especie = request.query_params.get('especie')
        sexo = request.query_params.get('sexo')

        queryset = Animal.objects.filter(usuario=request.user, activo=True)
        if especie:
            queryset = queryset.filter(especie=especie)
        if sexo:
            queryset = queryset.filter(sexo=sexo)

        if fmt == 'csv':
            return self._generate_csv(queryset)
        return self._generate_pdf(queryset)

    def _generate_csv(self, queryset):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="animales.csv"'

        writer = csv.writer(response)
        writer.writerow(['Arete', 'Nombre', 'Especie', 'Sexo', 'Fecha Nacimiento', 'Padre', 'Madre', 'Observaciones', 'Total Esquilas'])

        for animal in queryset:
            writer.writerow([
                animal.arete,
                animal.nombre,
                animal.especie,
                animal.sexo,
                animal.fecha_nacimiento.isoformat() if animal.fecha_nacimiento else '',
                animal.padre.arete if animal.padre else 'N/A',
                animal.madre.arete if animal.madre else 'N/A',
                animal.observaciones,
                animal.producciones.count()
            ])
        return response

    def _generate_pdf(self, queryset):
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        elements = []

        data = [['Arete', 'Nombre', 'Especie', 'Sexo', 'F. Nacimiento', 'Padre', 'Madre', 'Observaciones', 'Total Esquilas']]
        for animal in queryset:
            data.append([
                animal.arete,
                animal.nombre[:20],
                animal.especie,
                animal.sexo,
                animal.fecha_nacimiento.isoformat() if animal.fecha_nacimiento else '',
                animal.padre.arete if animal.padre else 'N/A',
                animal.madre.arete if animal.madre else 'N/A',
                animal.observaciones,
                str(animal.producciones.count())
            ])

        table = Table(data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.darkgreen),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        elements.append(table)
        doc.build(elements)

        buffer.seek(0)
        response = HttpResponse(buffer.read(), content_type='application/pdf')
        response['Content-Disposition'] = 'attachment; filename="animales.pdf"'
        return response