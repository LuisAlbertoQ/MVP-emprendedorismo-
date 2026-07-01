from django.urls import path
from .views import (
    ReporteView, ReporteProduccionView,
    ReporteEmpadreView, ReportePartoView, ReporteCostoView,
    ReporteVentaFibraView, ReporteRankingFibraView, ReporteConsanguinidadView,
)

urlpatterns = [
    path('animales/', ReporteView.as_view(), name='reporte_animales'),
    path('esquilas/', ReporteProduccionView.as_view(), name='reporte_esquilas'),
    path('empadres/', ReporteEmpadreView.as_view(), name='reporte_empadres'),
    path('partos/', ReportePartoView.as_view(), name='reporte_partos'),
    path('costos/', ReporteCostoView.as_view(), name='reporte_costos'),
    path('ventas-fibra/', ReporteVentaFibraView.as_view(), name='reporte_ventas_fibra'),
    path('ranking-fibra/', ReporteRankingFibraView.as_view(), name='reporte_ranking_fibra'),
    path('consanguinidad/', ReporteConsanguinidadView.as_view(), name='reporte_consanguinidad'),
]
