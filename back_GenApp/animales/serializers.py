from rest_framework import serializers
from .models import Animal, Especie, Sexo


class AnimalSerializer(serializers.ModelSerializer):
    padre_uid = serializers.UUIDField(source='padre.uid', read_only=True, allow_null=True)
    madre_uid = serializers.UUIDField(source='madre.uid', read_only=True, allow_null=True)
    usuario = serializers.HiddenField(default=serializers.CurrentUserDefault())

    class Meta:
        model = Animal
        fields = [
            'uid', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre', 'madre', 'padre_uid', 'madre_uid',
            'foto', 'observaciones', 'activo', 'sync_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['uid', 'sync_status', 'created_at', 'updated_at']

    def validate(self, data):
        usuario = data.get('usuario') or (self.instance.usuario if self.instance else None)
        if not usuario:
            raise serializers.ValidationError('Usuario no encontrado')

        limite = usuario.limite_animales
        if usuario.animales_count >= limite:
            if self.instance is None or data.get('activo', True):
                raise serializers.ValidationError(
                    f'Has alcanzado el límite de {limite} animales de tu plan {usuario.plan}'
                )

        return data

    def validate_padre(self, value):
        if value:
            usuario = self.context['request'].user
            if value.usuario != usuario:
                raise serializers.ValidationError('El padre debe pertenecer al mismo usuario')
            if self.instance and value.id == self.instance.id:
                raise serializers.ValidationError('Un animal no puede ser su propio padre')
        return value

    def validate_madre(self, value):
        if value:
            usuario = self.context['request'].user
            if value.usuario != usuario:
                raise serializers.ValidationError('La madre debe pertenecer al mismo usuario')
            if self.instance and value.id == self.instance.id:
                raise serializers.ValidationError('Un animal no puede ser su propia madre')
        return value


class AnimalListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo', 'fecha_nacimiento', 'foto']


class SyncChangeSerializer(serializers.Serializer):
    uid = serializers.UUIDField(required=False)
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

    class Meta:
        model = Animal
        fields = [
            'uid', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre_uid', 'madre_uid',
            'observaciones', 'activo', 'sync_status', 'updated_at', 'deleted_at'
        ]


class ReporteSerializer(serializers.Serializer):
    format = serializers.ChoiceField(choices=['csv', 'pdf'], default='csv')