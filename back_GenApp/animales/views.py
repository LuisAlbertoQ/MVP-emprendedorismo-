from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.utils import timezone
from django.http import HttpResponse
from drf_spectacular.utils import extend_schema, OpenApiParameter
import csv
import io
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle

from .models import Animal, SyncStatus
from .serializers import (
    AnimalSerializer, AnimalListSerializer,
    SyncInputSerializer, SyncOutputAnimalSerializer,
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
        return queryset.select_related('padre', 'madre')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user, sync_status=SyncStatus.SIC)

    @extend_schema(
        parameters=[
            OpenApiParameter(name='especie', type=str),
            OpenApiParameter(name='sexo', type=str),
            OpenApiParameter(name='activo', type=bool),
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
            }
            if depth < max_generations:
                node['padre'] = build_tree(a.padre, depth + 1) if a.padre else None
                node['madre'] = build_tree(a.madre, depth + 1) if a.madre else None
            return node

        tree = build_tree(animal)
        return Response(tree)


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
                    if change.get('local_updated_at') and animal.updated_at < change['local_updated_at']:
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

        queryset = Animal.objects.filter(usuario=request.user)
        if last_sync:
            queryset = queryset.filter(updated_at__gt=last_sync)

        serializer = SyncOutputAnimalSerializer(queryset, many=True)

        return Response({
            'server_changes': serializer.data,
            'sync_timestamp': timezone.now().isoformat(),
            'processed': processed_uids
        })


class ReporteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsPaidPlan]

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
        writer.writerow(['Arete', 'Nombre', 'Especie', 'Sexo', 'Fecha Nacimiento', 'Padre', 'Madre', 'Observaciones'])

        for animal in queryset:
            writer.writerow([
                animal.arete,
                animal.nombre,
                animal.especie,
                animal.sexo,
                animal.fecha_nacimiento.isoformat() if animal.fecha_nacimiento else '',
                animal.padre.arete if animal.padre else 'N/A',
                animal.madre.arete if animal.madre else 'N/A',
                animal.observaciones
            ])
        return response

    def _generate_pdf(self, queryset):
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        elements = []

        data = [['Arete', 'Nombre', 'Especie', 'Sexo', 'F. Nacimiento']]
        for animal in queryset:
            data.append([
                animal.arete,
                animal.nombre[:20],
                animal.especie,
                animal.sexo,
                animal.fecha_nacimiento.isoformat() if animal.fecha_nacimiento else ''
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