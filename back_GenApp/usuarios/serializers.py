from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import Usuario


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

    class Meta:
        model = Usuario
        fields = [
            'id', 'telefono', 'first_name', 'plan',
            'limite_animales', 'animales_count', 'generations_allowed',
            'created_at'
        ]
        read_only_fields = ['id', 'telefono', 'plan', 'created_at']


class CambioPlanSerializer(serializers.Serializer):
    plan = serializers.ChoiceField(choices=Usuario.plan.field.choices)

    def validate_plan(self, value):
        if value == 'gratuito':
            raise serializers.ValidationError('No se puede cambiar a plan gratuito')
        return value