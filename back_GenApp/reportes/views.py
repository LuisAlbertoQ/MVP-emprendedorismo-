from decimal import Decimal
from rest_framework import permissions
from rest_framework.views import APIView
from django.db.models import Sum, Count
from django.http import HttpResponse
from drf_spectacular.utils import extend_schema, OpenApiParameter
import csv
import io
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
)

from animales.models import Animal, Produccion, Empadre, Parto, Costo, VentaFibra
from animales.utils import calcular_categoria_edad, calcular_coeficiente_consanguinidad
from .renderers import CSVRenderer, PDFRenderer


class IsPaidPlan(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.plan in ['basico', 'criador']


def _build_pdf(title, subtitle, headers, rows, col_widths, is_landscape=True):
    buffer = io.BytesIO()
    page_size = landscape(letter) if is_landscape else letter
    doc = SimpleDocTemplate(
        buffer, pagesize=page_size,
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
    cell_style = ParagraphStyle('Cell', fontSize=7.5, leading=10)

    elements = []
    elements.append(Paragraph('GeneApp Andina', title_style))
    elements.append(Paragraph(title, subtitle_style))
    elements.append(Paragraph(
        f'Generado: {datetime.now().strftime("%d/%m/%Y %H:%M")}  |  {subtitle}',
        subtitle_style
    ))
    elements.append(Spacer(1, 0.2*inch))

    table_data = [headers]
    for row in rows:
        table_data.append([Paragraph(str(c), cell_style) for c in row])

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
    response['Content-Disposition'] = f'attachment; filename="{title.lower().replace(" ", "_")}.pdf"'
    return response


class BaseReporteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsPaidPlan]
    renderer_classes = [CSVRenderer, PDFRenderer]

    def perform_content_negotiation(self, request, force_format=None):
        fmt = request.query_params.get('format', 'csv')
        for renderer in self.renderer_classes:
            if renderer.format == fmt:
                return (renderer, renderer.media_type)
        return (self.renderer_classes[0], self.renderer_classes[0].media_type)


class ReporteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsPaidPlan]
    renderer_classes = [CSVRenderer, PDFRenderer]

    def perform_content_negotiation(self, request, force_format=None):
        fmt = request.query_params.get('format', 'csv')
        for renderer in self.renderer_classes:
            if renderer.format == fmt:
                return (renderer, renderer.media_type)
        return (self.renderer_classes[0], self.renderer_classes[0].media_type)

    def _get_categoria(self, animal):
        return calcular_categoria_edad(animal.especie, animal.fecha_nacimiento)

    def _get_costo_total(self, animal):
        return Costo.objects.filter(animal=animal).aggregate(total=Sum('monto'))['total'] or Decimal('0')

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
        writer.writerow([
            'Arete', 'Nombre', 'Especie', 'Raza', 'Sexo', 'Categoría Edad',
            'Fecha Nacimiento', 'Peso Nac. (kg)', 'Padre', 'Madre',
            'Costo Total (S/)', 'Total Esquilas', 'Observaciones'
        ])

        for animal in queryset:
            writer.writerow([
                animal.arete,
                animal.nombre,
                animal.get_especie_display(),
                animal.raza,
                animal.get_sexo_display(),
                self._get_categoria(animal),
                animal.fecha_nacimiento.isoformat() if animal.fecha_nacimiento else '',
                str(animal.peso_nacimiento_kg) if animal.peso_nacimiento_kg else '',
                animal.padre.arete if animal.padre else 'N/A',
                animal.madre.arete if animal.madre else 'N/A',
                f'{self._get_costo_total(animal):.2f}',
                animal.producciones_count,
                animal.observaciones,
            ])
        return response

    def _generate_pdf(self, queryset):
        headers = ['Arete', 'Nombre', 'Especie', 'Raza', 'Sexo', 'Categoría', 'F. Nac.', 'Peso (kg)', 'Padre', 'Madre', 'Costo S/.']
        rows = []
        for animal in queryset:
            rows.append([
                animal.arete, animal.nombre[:18],
                animal.get_especie_display(), animal.raza or '-',
                animal.get_sexo_display(), self._get_categoria(animal),
                animal.fecha_nacimiento.strftime('%d/%m/%Y') if animal.fecha_nacimiento else '-',
                f'{animal.peso_nacimiento_kg:.2f}' if animal.peso_nacimiento_kg else '-',
                animal.padre.arete if animal.padre else '-',
                animal.madre.arete if animal.madre else '-',
                f'S/{self._get_costo_total(animal):.2f}',
            ])
        col_widths = [0.5*inch, 0.9*inch, 0.55*inch, 0.55*inch, 0.4*inch, 0.7*inch, 0.65*inch, 0.55*inch, 0.6*inch, 0.6*inch, 0.6*inch]
        return _build_pdf('Reporte de Animales', f'Total: {queryset.count()} animales', headers, rows, col_widths)


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
            'Arete', 'Nombre', 'Especie', 'Fecha Esquila',
            'P. Sucio (kg)', 'P. Limpio (kg)', 'N°',
            'Rend. (%)', 'Diámetro (µ)', 'Confort (%)', 'Medulación (%)',
            'Observaciones'
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
                str(p.diametro_fibra_micras) if p.diametro_fibra_micras else '',
                str(p.factor_confort) if p.factor_confort else '',
                str(p.medulacion_pct) if p.medulacion_pct else '',
                p.observaciones,
            ])
        return response

    def _generate_pdf(self, queryset):
        headers = ['Arete', 'Nombre', 'Especie', 'Fecha', 'P. Sucio', 'P. Limpio', 'N°', 'Rend.%', 'Diám.(µ)', 'Conf.%', 'Med.%']
        rows = []
        for p in queryset:
            rows.append([
                p.animal.arete, p.animal.nombre[:16],
                p.animal.get_especie_display(),
                p.fecha_esquila.strftime('%d/%m/%Y'),
                f'{p.peso_vellon_sucio_kg:.2f}',
                f'{p.peso_vellon_limpio_kg:.2f}' if p.peso_vellon_limpio_kg else '-',
                str(p.numero_esquila) if p.numero_esquila else '-',
                f'{p.rendimiento_pct:.1f}' if p.rendimiento_pct else '-',
                str(p.diametro_fibra_micras) if p.diametro_fibra_micras else '-',
                str(p.factor_confort) if p.factor_confort else '-',
                str(p.medulacion_pct) if p.medulacion_pct else '-',
            ])
        col_widths = [0.45*inch, 0.8*inch, 0.5*inch, 0.6*inch, 0.5*inch, 0.5*inch, 0.3*inch, 0.4*inch, 0.45*inch, 0.45*inch, 0.45*inch]
        return _build_pdf('Reporte de Esquilas (Producción)', f'Total: {queryset.count()} registros', headers, rows, col_widths)


class ReporteEmpadreView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = Empadre.objects.filter(hembra__usuario=request.user).select_related('hembra', 'macho').order_by('-fecha_empadre')
        if fmt == 'csv':
            return self._generate_csv(qs)
        return self._generate_pdf(qs)

    def _generate_csv(self, qs):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="empadres.csv"'
        w = csv.writer(r)
        w.writerow(['Hembra', 'Macho', 'Fecha Empadre', 'Fecha DX', 'Resultado', 'Observaciones'])
        for e in qs:
            w.writerow([
                e.hembra.arete, e.macho.arete,
                e.fecha_empadre.strftime('%d/%m/%Y'),
                e.fecha_dx_gestacion.strftime('%d/%m/%Y') if e.fecha_dx_gestacion else '',
                e.get_resultado_display(), e.observaciones,
            ])
        return r

    def _generate_pdf(self, qs):
        headers = ['Hembra', 'Macho', 'F. Empadre', 'F. DX', 'Resultado', 'Obs.']
        rows = [[e.hembra.arete, e.macho.arete,
                 e.fecha_empadre.strftime('%d/%m/%Y'),
                 e.fecha_dx_gestacion.strftime('%d/%m/%Y') if e.fecha_dx_gestacion else '-',
                 e.get_resultado_display(), e.observaciones[:30]] for e in qs]
        widths = [0.7*inch, 0.7*inch, 0.7*inch, 0.7*inch, 0.9*inch, 1.8*inch]
        return _build_pdf('Reporte de Empadres', f'Total: {qs.count()} registros', headers, rows, widths)


class ReportePartoView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = Parto.objects.filter(hembra__usuario=request.user).select_related('hembra', 'empadre').order_by('-fecha_parto')
        if fmt == 'csv':
            return self._generate_csv(qs)
        return self._generate_pdf(qs)

    def _generate_csv(self, qs):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="partos.csv"'
        w = csv.writer(r)
        w.writerow(['Hembra', 'F. Parto', 'N° Crías', 'Incidencias', 'Empadre', 'Observaciones'])
        for p in qs:
            w.writerow([
                p.hembra.arete,
                p.fecha_parto.strftime('%d/%m/%Y'),
                p.numero_crias, p.incidencias or '',
                p.empadre.arete if p.empadre else 'N/A', p.observaciones,
            ])
        return r

    def _generate_pdf(self, qs):
        headers = ['Hembra', 'F. Parto', 'Crías', 'Incidencias', 'Empadre', 'Obs.']
        rows = [[p.hembra.arete, p.fecha_parto.strftime('%d/%m/%Y'),
                 str(p.numero_crias), p.incidencias or '-',
                 p.empadre.hembra.arete if p.empadre else 'N/A', p.observaciones[:30]] for p in qs]
        widths = [0.7*inch, 0.7*inch, 0.4*inch, 1.0*inch, 0.7*inch, 1.8*inch]
        return _build_pdf('Reporte de Partos', f'Total: {qs.count()} registros', headers, rows, widths)


class ReporteCostoView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = Costo.objects.filter(animal__usuario=request.user).select_related('animal').order_by('-fecha')
        if fmt == 'csv':
            return self._generate_csv(qs)
        return self._generate_pdf(qs)

    def _generate_csv(self, qs):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="costos.csv"'
        w = csv.writer(r)
        w.writerow(['Animal', 'Especie', 'Tipo', 'Monto (S/)', 'Fecha', 'Descripción'])
        for c in qs:
            w.writerow([
                c.animal.arete, c.animal.get_especie_display(),
                c.get_tipo_display(), f'{c.monto:.2f}',
                c.fecha.strftime('%d/%m/%Y'), c.descripcion,
            ])
        return r

    def _generate_pdf(self, qs):
        headers = ['Animal', 'Especie', 'Tipo', 'Monto S/.', 'Fecha', 'Descripción']
        rows = [[c.animal.arete, c.animal.get_especie_display(),
                 c.get_tipo_display(), f'{c.monto:.2f}',
                 c.fecha.strftime('%d/%m/%Y'), c.descripcion[:40]] for c in qs]
        widths = [0.7*inch, 0.6*inch, 0.9*inch, 0.6*inch, 0.7*inch, 1.9*inch]
        return _build_pdf('Reporte de Costos', f'Total: {qs.count()} registros', headers, rows, widths)


class ReporteVentaFibraView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = VentaFibra.objects.filter(animal__usuario=request.user).select_related('animal').order_by('-fecha_venta')
        if fmt == 'csv':
            return self._generate_csv(qs)
        return self._generate_pdf(qs)

    def _generate_csv(self, qs):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="ventas_fibra.csv"'
        w = csv.writer(r)
        w.writerow(['Animal', 'Especie', 'Kg Vendidos', 'Precio Kg (S/)', 'Ingreso Total (S/)', 'Comprador', 'Fecha Venta'])
        for v in qs:
            w.writerow([
                v.animal.arete, v.animal.get_especie_display(),
                str(v.kg_vendidos), f'{v.precio_kg:.2f}',
                f'{v.ingreso_total:.2f}', v.comprador or '',
                v.fecha_venta.strftime('%d/%m/%Y'),
            ])
        return r

    def _generate_pdf(self, qs):
        headers = ['Animal', 'Especie', 'Kg', 'P. Kg', 'Total S/.', 'Comprador', 'F. Venta']
        rows = [[v.animal.arete, v.animal.get_especie_display(),
                 str(v.kg_vendidos), f'{v.precio_kg:.2f}',
                 f'{v.ingreso_total:.2f}', v.comprador or '-',
                 v.fecha_venta.strftime('%d/%m/%Y')] for v in qs]
        widths = [0.6*inch, 0.6*inch, 0.5*inch, 0.5*inch, 0.6*inch, 1.0*inch, 0.7*inch]
        return _build_pdf('Reporte de Ventas de Fibra', f'Total: {qs.count()} registros', headers, rows, widths)


class ReporteRankingFibraView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = Animal.objects.filter(usuario=request.user).prefetch_related('producciones')
        ranking = []
        for animal in qs:
            ultima = animal.producciones.order_by('-fecha_esquila').first()
            if not ultima or not ultima.diametro_fibra_micras:
                continue
            ranking.append({
                'arete': animal.arete,
                'nombre': animal.nombre or '',
                'especie': animal.get_especie_display(),
                'diametro': float(ultima.diametro_fibra_micras),
                'confort': float(ultima.factor_confort) if ultima.factor_confort else None,
                'medulacion': float(ultima.medulacion_pct) if ultima.medulacion_pct else None,
                'rendimiento': float(ultima.rendimiento_pct) if ultima.rendimiento_pct else None,
            })
        ranking.sort(key=lambda x: x['diametro'])
        if fmt == 'csv':
            return self._generate_csv(ranking)
        return self._generate_pdf(ranking)

    def _generate_csv(self, ranking):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="ranking_fibra.csv"'
        w = csv.writer(r)
        w.writerow(['Pos.', 'Arete', 'Nombre', 'Especie', 'Diámetro (µ)', 'Confort (%)', 'Medulación (%)', 'Rendimiento (%)'])
        for i, a in enumerate(ranking, 1):
            w.writerow([
                i, a['arete'], a['nombre'], a['especie'],
                f'{a["diametro"]:.2f}',
                f'{a["confort"]:.2f}' if a['confort'] else '',
                f'{a["medulacion"]:.2f}' if a['medulacion'] else '',
                f'{a["rendimiento"]:.2f}' if a['rendimiento'] else '',
            ])
        return r

    def _generate_pdf(self, ranking):
        headers = ['#', 'Arete', 'Nombre', 'Especie', 'Diám.(µ)', 'Conf.%', 'Med.%', 'Rend.%']
        rows = []
        for i, a in enumerate(ranking, 1):
            rows.append([
                str(i), a['arete'], a['nombre'][:18], a['especie'],
                f'{a["diametro"]:.2f}',
                f'{a["confort"]:.1f}' if a['confort'] else '-',
                f'{a["medulacion"]:.1f}' if a['medulacion'] else '-',
                f'{a["rendimiento"]:.1f}' if a['rendimiento'] else '-',
            ])
        widths = [0.3*inch, 0.6*inch, 0.9*inch, 0.6*inch, 0.6*inch, 0.5*inch, 0.5*inch, 0.5*inch]
        return _build_pdf('Ranking de Fibra', f'Total: {len(ranking)} animales', headers, rows, widths)


class ReporteConsanguinidadView(BaseReporteView):
    @extend_schema(
        parameters=[OpenApiParameter(name='format', type=str)],
        responses={200: {'type': 'file'}}
    )
    def get(self, request):
        fmt = request.query_params.get('format', 'csv')
        qs = Animal.objects.filter(
            usuario=request.user,
            padre__isnull=False,
            madre__isnull=False
        ).select_related('padre', 'madre')
        if fmt == 'csv':
            return self._generate_csv(qs)
        return self._generate_pdf(qs)

    def _generate_csv(self, qs):
        r = HttpResponse(content_type='text/csv')
        r['Content-Disposition'] = 'attachment; filename="consanguinidad.csv"'
        w = csv.writer(r)
        w.writerow(['Animal', 'Nombre', 'Coeficiente', 'Padre', 'Madre'])
        for a in qs:
            w.writerow([
                a.arete, a.nombre or '',
                f'{calcular_coeficiente_consanguinidad(a):.4f}',
                a.padre.arete, a.madre.arete,
            ])
        return r

    def _generate_pdf(self, qs):
        headers = ['Animal', 'Nombre', 'Coeficiente', 'Padre', 'Madre']
        rows = [[a.arete, a.nombre[:20] if a.nombre else '-',
                 f'{calcular_coeficiente_consanguinidad(a):.4f}',
                 a.padre.arete, a.madre.arete] for a in qs]
        widths = [0.6*inch, 1.2*inch, 1.0*inch, 0.7*inch, 0.7*inch]
        return _build_pdf('Reporte de Consanguinidad', f'Total: {qs.count()} animales', headers, rows, widths, is_landscape=False)
