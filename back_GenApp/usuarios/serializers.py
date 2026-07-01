import uuid
from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import Usuario, SolicitudPago, ConfiguracionPago


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    nombre = serializers.CharField(write_only=True, source='first_name')

    class Meta:
        model = Usuario
        fields = ['telefono', 'nombre', 'password']

    def create(self, validated_data):
        nombre = validated_data.pop('first_name')
        password = validated_data.pop('password')
        user = Usuario(
            username=validated_data['telefono'],
            telefono=validated_data['telefono'],
            first_name=nombre
        )
        user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    telefono = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        telefono = data.get('telefono')
        password = data.get('password')

        if telefono and password:
            user = authenticate(username=telefono, password=password)
            if not user:
                raise serializers.ValidationError('Credenciales inválidas')
            if not user.is_active:
                raise serializers.ValidationError('Usuario desactivado')
        else:
            raise serializers.ValidationError('Se requiere teléfono y contraseña')

        data['user'] = user
        return data


class PerfilSerializer(serializers.ModelSerializer):
    limite_animales = serializers.IntegerField(read_only=True)
    animales_count = serializers.IntegerField(read_only=True)
    generations_allowed = serializers.IntegerField(read_only=True)
    solicitud_pendiente = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
            'id', 'telefono', 'first_name', 'plan',
            'limite_animales', 'animales_count', 'generations_allowed',
            'solicitud_pendiente', 'created_at'
        ]
        read_only_fields = ['id', 'telefono', 'plan', 'created_at']

    def get_solicitud_pendiente(self, obj):
        qs = obj.solicitudes_pago.filter(estado=SolicitudPago.Estado.PENDIENTE)
        if not qs.exists():
            return None
        s = qs.first()
        return {
            'uid': str(s.uid),
            'plan_solicitado': s.plan_solicitado,
            'monto': str(s.monto),
            'created_at': s.created_at.isoformat(),
        }


class CambioPlanSerializer(serializers.Serializer):
    plan = serializers.ChoiceField(choices=Usuario.plan.field.choices)

    def validate_plan(self, value):
        if value == 'gratuito':
            raise serializers.ValidationError('No se puede cambiar a plan gratuito')
        return value


class SolicitudPagoSerializer(serializers.ModelSerializer):
    comprobante = serializers.ImageField()
    numero_operacion = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = SolicitudPago
        fields = ['plan_solicitado', 'comprobante', 'numero_operacion']

    def validate_plan_solicitado(self, value):
        if value == 'gratuito':
            raise serializers.ValidationError('No se puede solicitar plan gratuito')
        return value

    def validate(self, data):
        user = self.context['request'].user
        if SolicitudPago.objects.filter(usuario=user, estado=SolicitudPago.Estado.PENDIENTE).exists():
            raise serializers.ValidationError('Ya tienes una solicitud de pago pendiente')
        return data

    def create(self, validated_data):
        user = self.context['request'].user
        config = ConfiguracionPago.obtener()
        monto = config.monto_criador if validated_data['plan_solicitado'] == 'criador' else config.monto_basico
        return SolicitudPago.objects.create(
            uid=uuid.uuid4(),
            usuario=user,
            plan_solicitado=validated_data['plan_solicitado'],
            monto=monto,
            comprobante=validated_data['comprobante'],
            numero_operacion=validated_data.get('numero_operacion', ''),
        )


class ConfiguracionPagoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConfiguracionPago
        fields = ['celular', 'qr', 'monto_basico', 'monto_criador']