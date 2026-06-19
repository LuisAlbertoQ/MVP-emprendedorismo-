from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.renderers import BaseRenderer
from django.db.models import Q, Count, Value, IntegerField
from django.utils import timezone
from django.http import HttpResponse
from drf_spectacular.utils import extend_schema, OpenApiParameter
import csv
import io
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak,
    PageTemplate, Frame, BaseDocTemplate
)


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

        queryset = Animal.objects.filter(usuario=request.user, estado='VIVO').annotate(
            producciones_count=Count('producciones')
        ).select_related('padre', 'madre')
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
                animal.producciones_count
            ])
        return response

    def _generate_pdf(self, queryset):
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer, pagesize=landscape(letter),
            leftMargin=0.5*inch, rightMargin=0.5*inch,
            topMargin=0.75*inch, bottomMargin=0.75*inch
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle', parent=styles['Title'],
            fontSize=18, spaceAfter=4, textColor=colors.HexColor('#2E7D32')
        )
        subtitle_style = ParagraphStyle(
            'Subtitle', parent=styles['Normal'],
            fontSize=9, textColor=colors.grey, alignment=TA_CENTER, spaceAfter=6
        )
        header_style = ParagraphStyle(
            'Header', fontSize=8, fontName='Helvetica-Bold',
            textColor=colors.white, alignment=TA_CENTER
        )
        cell_style = ParagraphStyle(
            'Cell', fontSize=7.5, leading=10
        )

        elements = []

        elements.append(Paragraph('GeneApp Andina', title_style))
        elements.append(Paragraph('Reporte de Animales', subtitle_style))
        elements.append(Paragraph(
            f'Generado: {datetime.now().strftime("%d/%m/%Y %H:%M")}  |  '
            f'Total: {queryset.count()} animales',
            subtitle_style
        ))
        elements.append(Spacer(1, 0.2*inch))

        table_data = [[
            'Arete', 'Nombre', 'Especie', 'Sexo', 'F. Nacimiento',
            'Padre', 'Madre', 'Observaciones', 'Esquilas'
        ]]
        for animal in queryset:
            table_data.append([
                Paragraph(animal.arete, cell_style),
                Paragraph(animal.nombre[:25], cell_style),
                Paragraph(animal.get_especie_display(), cell_style),
                Paragraph(animal.get_sexo_display(), cell_style),
                Paragraph(
                    animal.fecha_nacimiento.strftime('%d/%m/%Y')
                    if animal.fecha_nacimiento else '-', cell_style
                ),
                Paragraph(animal.padre.arete if animal.padre else '-', cell_style),
                Paragraph(animal.madre.arete if animal.madre else '-', cell_style),
                Paragraph(animal.observaciones[:30], cell_style),
                Paragraph(str(animal.producciones_count), ParagraphStyle(
                    'CountCell', parent=cell_style, alignment=TA_CENTER
                )),
            ])

        col_widths = [0.6*inch, 1.2*inch, 0.7*inch, 0.6*inch, 0.8*inch, 0.8*inch, 0.8*inch, 1.2*inch, 0.6*inch]
        table = Table(table_data, colWidths=col_widths, repeatRows=1)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2E7D32')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 8),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('TOPPADDING', (0, 0), (-1, 0), 8),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F5F5F5')),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.HexColor('#FFFFFF'), colors.HexColor('#F5F5F5')]),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CCCCCC')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 1), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))
        elements.append(table)

        elements.append(Spacer(1, 0.3*inch))
        elements.append(Paragraph(
            'GeneApp Andina - Gestión de Criadores de Alpacas, Llamas y Ovinos',
            ParagraphStyle('Footer', parent=styles['Normal'], fontSize=7,
                           textColor=colors.grey, alignment=TA_CENTER)
        ))

        doc.build(elements)
        buffer.seek(0)
        response = HttpResponse(buffer.read(), content_type='application/pdf')
        response['Content-Disposition'] = 'attachment; filename="animales.pdf"'
        return response


class ReporteProduccionView(APIView):
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
        queryset = Produccion.objects.filter(
            animal__usuario=request.user
        ).select_related('animal').order_by('-fecha_esquila')

        if fmt == 'csv':
            return self._generate_csv(queryset)
        return self._generate_pdf(queryset)

    def _generate_csv(self, queryset):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="esquilas.csv"'

        writer = csv.writer(response)
        writer.writerow([
            'Arete Animal', 'Nombre Animal', 'Especie', 'Fecha Esquila',
            'Peso Sucio (kg)', 'Peso Limpio (kg)', 'N° Esquila',
            'Rendimiento (%)', 'Observaciones'
        ])
        for p in queryset:
            writer.writerow([
                p.animal.arete,
                p.animal.nombre,
                p.animal.get_especie_display(),
                p.fecha_esquila.strftime('%d/%m/%Y'),
                str(p.peso_vellon_sucio_kg),
                str(p.peso_vellon_limpio_kg) if p.peso_vellon_limpio_kg else '',
                str(p.numero_esquila) if p.numero_esquila else '',
                f'{p.rendimiento_pct:.2f}' if p.rendimiento_pct is not None else '',
                p.observaciones,
            ])
        return response

    def _generate_pdf(self, queryset):
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer, pagesize=landscape(letter),
            leftMargin=0.5*inch, rightMargin=0.5*inch,
            topMargin=0.75*inch, bottomMargin=0.75*inch
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle', parent=styles['Title'],
            fontSize=18, spaceAfter=4, textColor=colors.HexColor('#2E7D32')
        )
        subtitle_style = ParagraphStyle(
            'Subtitle', parent=styles['Normal'],
            fontSize=9, textColor=colors.grey, alignment=TA_CENTER, spaceAfter=6
        )
        cell_style = ParagraphStyle('Cell', fontSize=8, leading=11)

        elements = []
        elements.append(Paragraph('GeneApp Andina', title_style))
        elements.append(Paragraph('Reporte de Esquilas (Producción)', subtitle_style))
        elements.append(Paragraph(
            f'Generado: {datetime.now().strftime("%d/%m/%Y %H:%M")}  |  '
            f'Total: {queryset.count()} registros',
            subtitle_style
        ))
        elements.append(Spacer(1, 0.2*inch))

        table_data = [[
            'Arete', 'Nombre', 'Especie', 'Fecha Esquila',
            'P. Sucio', 'P. Limpio', 'N°', 'Rend.%', 'Obs.'
        ]]
        for p in queryset:
            table_data.append([
                Paragraph(p.animal.arete, cell_style),
                Paragraph(p.animal.nombre[:20], cell_style),
                Paragraph(p.animal.get_especie_display(), cell_style),
                Paragraph(p.fecha_esquila.strftime('%d/%m/%Y'), cell_style),
                Paragraph(f'{p.peso_vellon_sucio_kg:.2f}', ParagraphStyle(
                    'NumCell', parent=cell_style, alignment=TA_CENTER
                )),
                Paragraph(
                    f'{p.peso_vellon_limpio_kg:.2f}' if p.peso_vellon_limpio_kg else '-',
                    ParagraphStyle('NumCell2', parent=cell_style, alignment=TA_CENTER)
                ),
                Paragraph(
                    str(p.numero_esquila) if p.numero_esquila else '-',
                    ParagraphStyle('NumCell3', parent=cell_style, alignment=TA_CENTER)
                ),
                Paragraph(
                    f'{p.rendimiento_pct:.1f}' if p.rendimiento_pct else '-',
                    ParagraphStyle('PctCell', parent=cell_style, alignment=TA_CENTER)
                ),
                Paragraph(p.observaciones[:30], cell_style),
            ])

        col_widths = [0.6*inch, 1.0*inch, 0.6*inch, 0.8*inch, 0.55*inch, 0.55*inch, 0.4*inch, 0.5*inch, 1.4*inch]
        table = Table(table_data, colWidths=col_widths, repeatRows=1)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2E7D32')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 8),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('TOPPADDING', (0, 0), (-1, 0), 8),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1),
             [colors.HexColor('#FFFFFF'), colors.HexColor('#F5F5F5')]),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CCCCCC')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 1), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))
        elements.append(table)

        elements.append(Spacer(1, 0.3*inch))
        elements.append(Paragraph(
            'GeneApp Andina - Gestión de Criadores de Alpacas, Llamas y Ovinos',
            ParagraphStyle('Footer', parent=styles['Normal'], fontSize=7,
                           textColor=colors.grey, alignment=TA_CENTER)
        ))
        doc.build(elements)
        buffer.seek(0)
        response = HttpResponse(buffer.read(), content_type='application/pdf')
        response['Content-Disposition'] = 'attachment; filename="esquilas.pdf"'
        return response