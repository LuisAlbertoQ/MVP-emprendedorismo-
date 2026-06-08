from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from drf_spectacular.utils import extend_schema

from .serializers import RegisterSerializer, LoginSerializer, PerfilSerializer, CambioPlanSerializer


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


@method_decorator(csrf_exempt, name='dispatch')
class WebhookYapeView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        request={'type': 'object'},
        responses={200: {'type': 'object', 'properties': {'status': {'type': 'string'}}}}
    )
    def post(self, request):
        return Response({'status': 'received'})