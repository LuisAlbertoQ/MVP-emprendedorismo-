from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, PerfilView, CambioPlanView,
    WebhookYapeView, DatosPagoView, SolicitarPagoView, MisSolicitudesView,
    NotificacionesView, NotificacionesNoLeidasView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('perfil/', PerfilView.as_view(), name='perfil'),
    path('cambiar-plan/', CambioPlanView.as_view(), name='cambiar_plan'),
    path('datos-pago/', DatosPagoView.as_view(), name='datos_pago'),
    path('solicitar-pago/', SolicitarPagoView.as_view(), name='solicitar_pago'),
    path('mis-solicitudes/', MisSolicitudesView.as_view(), name='mis_solicitudes'),
    path('notificaciones/', NotificacionesView.as_view(), name='notificaciones'),
    path('notificaciones/no-leidas/', NotificacionesNoLeidasView.as_view(), name='notificaciones_no_leidas'),
    path('webhook-yape/', WebhookYapeView.as_view(), name='webhook_yape'),
]