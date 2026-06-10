from datetime import date
from rest_framework import serializers
from django.db import IntegrityError
from .models import Animal, Especie, Sexo
from .utils import calcular_categoria_edad


class UidToAnimalField(serializers.Field):
    def to_internal_value(self, data):
        if not data:
            return None
        try:
            return Animal.objects.get(uid=data, usuario=self.context['request'].user)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Animal no encontrado')
        except ValueError:
            raise serializers.ValidationError('UID inválido')

    def to_representation(self, value):
        if value is None:
            return None
        nombre = f' - {value.nombre}' if value.nombre else ''
        return f'{value.arete}{nombre}'


class AnimalSerializer(serializers.ModelSerializer):
    padre_uid = serializers.UUIDField(source='padre.uid', read_only=True, allow_null=True)
    madre_uid = serializers.UUIDField(source='madre.uid', read_only=True, allow_null=True)
    padre = UidToAnimalField(required=False, allow_null=True)
    madre = UidToAnimalField(required=False, allow_null=True)
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = [
            'uid', 'usuario', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre', 'madre', 'padre_uid', 'madre_uid',
            'foto', 'observaciones', 'activo', 'sync_status',
            'created_at', 'updated_at', 'categoria_edad'
        ]
        read_only_fields = ['uid', 'usuario', 'sync_status', 'created_at', 'updated_at', 'categoria_edad']

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)

    def validate_fecha_nacimiento(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de nacimiento no puede ser futura')
        return value

    def validate(self, data):
        usuario = self.context['request'].user
        if not usuario:
            raise serializers.ValidationError('Usuario no encontrado')

        limite = usuario.limite_animales
        if usuario.animales_count >= limite:
            if self.instance is None:
                raise serializers.ValidationError(
                    f'Has alcanzado el límite de {limite} animales de tu plan {usuario.plan}'
                )
            if not self.instance.activo and data.get('activo', True):
                raise serializers.ValidationError(
                    f'Has alcanzado el límite de {limite} animales de tu plan {usuario.plan}'
                )

        especie = data.get('especie', self.instance.especie if self.instance else None)
        padre = data.get('padre', self.instance.padre if self.instance else None)
        madre = data.get('madre', self.instance.madre if self.instance else None)
        fecha_nac = data.get('fecha_nacimiento', self.instance.fecha_nacimiento if self.instance else None)

        if padre:
            if padre.sexo != 'macho':
                raise serializers.ValidationError({'padre': 'El padre debe ser un animal de sexo macho'})
            if especie and padre.especie != especie:
                raise serializers.ValidationError({'padre': f'El padre debe ser de la misma especie ({padre.get_especie_display()} != {dict(Especie.choices).get(especie, especie)})'})
            if fecha_nac and padre.fecha_nacimiento >= fecha_nac:
                raise serializers.ValidationError({'padre': 'El padre debe ser mayor que el animal'})

        if madre:
            if madre.sexo != 'hembra':
                raise serializers.ValidationError({'madre': 'La madre debe ser un animal de sexo hembra'})
            if especie and madre.especie != especie:
                raise serializers.ValidationError({'madre': f'La madre debe ser de la misma especie ({madre.get_especie_display()} != {dict(Especie.choices).get(especie, especie)})'})
            if fecha_nac and madre.fecha_nacimiento >= fecha_nac:
                raise serializers.ValidationError({'madre': 'La madre debe ser mayor que el animal'})

        return data

    def validate_arete(self, value):
        usuario = self.context['request'].user
        if self.instance is None:
            if Animal.objects.filter(usuario=usuario, arete=value).exists():
                raise serializers.ValidationError(
                    f'Ya existe un animal registrado con el arete "{value}".'
                )
        return value

    def create(self, validated_data):
        try:
            return super().create(validated_data)
        except IntegrityError:
            raise serializers.ValidationError({
                'arete': f'Ya existe un animal con el arete "{validated_data.get("arete")}".'
            })


class AnimalListSerializer(serializers.ModelSerializer):
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo', 'fecha_nacimiento', 'foto', 'categoria_edad']

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)


class SyncChangeSerializer(serializers.Serializer):
    uid = serializers.UUIDField(required=True)
    arete = serializers.CharField()
    especie = serializers.ChoiceField(choices=Especie.choices)
    sexo = serializers.ChoiceField(choices=Sexo.choices)
    fecha_nacimiento = serializers.DateField()
    nombre = serializers.CharField(required=False, default='')
    raza = serializers.CharField(required=False, default='')
    padre_uid = serializers.UUIDField(required=False, allow_null=True)
    madre_uid = serializers.UUIDField(required=False, allow_null=True)
    observaciones = serializers.CharField(required=False, default='')
    activo = serializers.BooleanField(required=False, default=True)
    action = serializers.ChoiceField(choices=['create', 'update', 'delete'], default='create')
    local_updated_at = serializers.DateTimeField(required=False, allow_null=True)


class SyncInputSerializer(serializers.Serializer):
    last_sync = serializers.DateTimeField(required=False, allow_null=True)
    changes = SyncChangeSerializer(many=True, required=False, default=list)


class SyncOutputAnimalSerializer(serializers.ModelSerializer):
    padre_uid = serializers.UUIDField(source='padre.uid', allow_null=True)
    madre_uid = serializers.UUIDField(source='madre.uid', allow_null=True)
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = [
            'uid', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre_uid', 'madre_uid',
            'observaciones', 'activo', 'sync_status', 'updated_at', 'deleted_at',
            'categoria_edad'
        ]

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)


class CandidatoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo']


class ReporteSerializer(serializers.Serializer):
    format = serializers.ChoiceField(choices=['csv', 'pdf'], default='csv')