from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import RegisterView, LoginView, PerfilView, CambioPlanView, WebhookYapeView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('perfil/', PerfilView.as_view(), name='perfil'),
    path('cambiar-plan/', CambioPlanView.as_view(), name='cambiar_plan'),
    path('webhook-yape/', WebhookYapeView.as_view(), name='webhook_yape'),
]