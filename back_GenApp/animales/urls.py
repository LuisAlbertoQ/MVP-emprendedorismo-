from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AnimalViewSet, ProduccionViewSet, SyncView, ReporteView

router = DefaultRouter()
router.register(r'animales', AnimalViewSet, basename='animal')
router.register(r'producciones', ProduccionViewSet, basename='produccion')

urlpatterns = [
    path('', include(router.urls)),
    path('sync/', SyncView.as_view(), name='sync'),
    path('reporte/animales/', ReporteView.as_view(), name='reporte_animales'),
]