from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from drf_spectacular.utils import extend_schema

from .serializers import (
    RegisterSerializer, LoginSerializer, PerfilSerializer,
    CambioPlanSerializer, SolicitudPagoSerializer, ConfiguracionPagoSerializer,
)
from .models import ConfiguracionPago, Notificacion


class RegisterView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        request=RegisterSerializer,
        responses={201: {'type': 'object', 'properties': {'message': {'type': 'string'}}}}
    )
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'message': 'Usuario registrado correctamente'}, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        request=LoginSerializer,
        responses={200: {'type': 'object', 'properties': {'access': {'type': 'string'}, 'refresh': {'type': 'string'}}}}
    )
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        })


class PerfilView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses={200: PerfilSerializer})
    def get(self, request):
        serializer = PerfilSerializer(request.user)
        return Response(serializer.data)


class CambioPlanView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=CambioPlanSerializer,
        responses={200: {'type': 'object', 'properties': {'message': {'type': 'string'}}}}
    )
    def post(self, request):
        serializer = CambioPlanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        request.user.plan = serializer.validated_data['plan']
        request.user.save()
        return Response({'message': 'Plan actualizado correctamente'})


class DatosPagoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        config = ConfiguracionPago.obtener()
        serializer = ConfiguracionPagoSerializer(config)
        return Response(serializer.data)


class SolicitarPagoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SolicitudPagoSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'message': 'Solicitud enviada correctamente'}, status=status.HTTP_201_CREATED)


class MisSolicitudesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = request.user.solicitudes_pago.all()
        data = []
        for s in qs:
            data.append({
                'uid': str(s.uid),
                'plan_solicitado': s.plan_solicitado,
                'monto': str(s.monto),
                'estado': s.estado,
                'numero_operacion': s.numero_operacion,
                'created_at': s.created_at.isoformat(),
            })
        return Response(data)



class NotificacionesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = request.user.notificaciones.all()
        data = []
        for n in qs:
            data.append({
                'id': n.pk,
                'mensaje': n.mensaje,
                'tipo': n.tipo,
                'leido': n.leido,
                'created_at': n.created_at.isoformat(),
            })
        return Response(data)

    def patch(self, request):
        notif_id = request.data.get('id')
        if notif_id:
            request.user.notificaciones.filter(pk=notif_id).update(leido=True)
        else:
            request.user.notificaciones.update(leido=True)
        return Response({'message': 'ok'})


class NotificacionesNoLeidasView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = request.user.notificaciones.filter(leido=False).count()
        return Response({'count': count})


@method_decorator(csrf_exempt, name='dispatch')
class WebhookYapeView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        request={'type': 'object'},
        responses={200: {'type': 'object', 'properties': {'status': {'type': 'string'}}}}
    )
    def post(self, request):
        return Response({'status': 'received'})