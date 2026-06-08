from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AnimalViewSet, SyncView, ReporteView

router = DefaultRouter()
router.register(r'animales', AnimalViewSet, basename='animal')

urlpatterns = [
    path('', include(router.urls)),
    path('sync/', SyncView.as_view(), name='sync'),
    path('reporte/animales/', ReporteView.as_view(), name='reporte_animales'),
]