from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AnimalViewSet, ProduccionViewSet, SyncView,
    ConsanguinidadViewSet, EmpadreViewSet, PartoViewSet, CostoViewSet,
    VentaFibraViewSet, RankingFibraView,
)

router = DefaultRouter()
router.register(r'animales', AnimalViewSet, basename='animal')
router.register(r'producciones', ProduccionViewSet, basename='produccion')
router.register(r'consanguinidad', ConsanguinidadViewSet, basename='consanguinidad')
router.register(r'empadres', EmpadreViewSet, basename='empadre')
router.register(r'partos', PartoViewSet, basename='parto')
router.register(r'costos', CostoViewSet, basename='costo')
router.register(r'ventas-fibra', VentaFibraViewSet, basename='ventafibra')

urlpatterns = [
    path('', include(router.urls)),
    path('sync/', SyncView.as_view(), name='sync'),
    path('ranking-fibra/', RankingFibraView.as_view(), name='ranking_fibra'),
]
