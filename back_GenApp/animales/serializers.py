from datetime import date
from rest_framework import serializers
from django.db import IntegrityError
from .models import Animal, Especie, Sexo, EstadoAnimal, Produccion
from .utils import calcular_categoria_edad, _edad_en_meses


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
    foto = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = [
            'uid', 'usuario', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre', 'madre', 'padre_uid', 'madre_uid',
            'foto', 'observaciones', 'estado', 'fecha_estado', 'motivo_estado',
            'peso_nacimiento_kg', 'sync_status',
            'created_at', 'updated_at', 'categoria_edad'
        ]
        read_only_fields = ['uid', 'usuario', 'sync_status', 'created_at', 'updated_at', 'categoria_edad', 'fecha_estado']

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)

    def get_foto(self, obj):
        if obj.foto:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.foto.url)
            return obj.foto.url
        return None

    def validate_fecha_nacimiento(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de nacimiento no puede ser futura')
        return value

    def validate(self, data):
        usuario = self.context['request'].user
        if not usuario:
            raise serializers.ValidationError('Usuario no encontrado')

        estado = data.get('estado', self.instance.estado if self.instance else 'VIVO')
        limite = usuario.limite_animales
        if self.instance is None:
            if usuario.animales_count >= limite:
                raise serializers.ValidationError(
                    f'Has alcanzado el límite de {limite} animales de tu plan {usuario.plan}'
                )
        else:
            old_estado = Animal.objects.get(pk=self.instance.pk).estado
            if old_estado != 'VIVO' and estado == 'VIVO' and usuario.animales_count >= limite:
                raise serializers.ValidationError(
                    f'Has alcanzado el límite de {limite} animales de tu plan {usuario.plan}. No puedes reactivar más animales.'
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
                raise serializers.ValidationError({'padre': 'El padre debe haber nacido antes que el animal'})

        if madre:
            if madre.sexo != 'hembra':
                raise serializers.ValidationError({'madre': 'La madre debe ser un animal de sexo hembra'})
            if especie and madre.especie != especie:
                raise serializers.ValidationError({'madre': f'La madre debe ser de la misma especie ({madre.get_especie_display()} != {dict(Especie.choices).get(especie, especie)})'})
            if fecha_nac and madre.fecha_nacimiento >= fecha_nac:
                raise serializers.ValidationError({'madre': 'La madre debe haber nacido antes que el animal'})

        return data

    def validate_arete(self, value):
        usuario = self.context['request'].user
        if self.instance is None:
            if Animal.objects.filter(usuario=usuario, arete=value).exists():
                raise serializers.ValidationError(
                    f'Ya existe un animal registrado con el arete "{value}".'
                )
        elif value != self.instance.arete:
            raise serializers.ValidationError('El arete no puede modificarse después de creado')
        if len(value) > 50:
            raise serializers.ValidationError('El arete no puede tener más de 50 caracteres')
        return value

    def validate_peso_nacimiento_kg(self, value):
        if value is not None:
            if value <= 0:
                raise serializers.ValidationError('El peso al nacer debe ser mayor a 0')
            if value > 999.99:
                raise serializers.ValidationError('El peso al nacer no puede superar 999.99 kg')
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
    foto = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo', 'fecha_nacimiento', 'foto', 'categoria_edad', 'estado']

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)

    def get_foto(self, obj):
        if obj.foto:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.foto.url)
            return obj.foto.url
        return None


class SyncChangeSerializer(serializers.Serializer):
    uid = serializers.UUIDField(required=True)
    arete = serializers.CharField(max_length=50)
    especie = serializers.ChoiceField(choices=Especie.choices)
    sexo = serializers.ChoiceField(choices=Sexo.choices)
    fecha_nacimiento = serializers.DateField()
    nombre = serializers.CharField(required=False, default='', max_length=100)
    raza = serializers.CharField(required=False, default='', max_length=50)
    padre_uid = serializers.UUIDField(required=False, allow_null=True)
    madre_uid = serializers.UUIDField(required=False, allow_null=True)
    observaciones = serializers.CharField(required=False, default='')
    estado = serializers.ChoiceField(choices=EstadoAnimal.choices, required=False, default='VIVO')
    action = serializers.ChoiceField(choices=['create', 'update', 'delete'], default='create')
    local_updated_at = serializers.DateTimeField(required=False, allow_null=True)


class SyncProduccionChangeSerializer(serializers.Serializer):
    uid = serializers.UUIDField(required=True)
    animal_uid = serializers.UUIDField(required=True)
    fecha_esquila = serializers.DateField()
    peso_vellon_sucio_kg = serializers.DecimalField(max_digits=6, decimal_places=2)
    peso_vellon_limpio_kg = serializers.DecimalField(max_digits=6, decimal_places=2, required=False, allow_null=True)
    numero_esquila = serializers.IntegerField(required=False, allow_null=True)
    observaciones = serializers.CharField(required=False, default='')
    action = serializers.ChoiceField(choices=['create', 'update', 'delete'], default='create')
    local_updated_at = serializers.DateTimeField(required=False, allow_null=True)


class SyncInputSerializer(serializers.Serializer):
    last_sync = serializers.DateTimeField(required=False, allow_null=True)
    changes = SyncChangeSerializer(many=True, required=False, default=list)
    produccion_changes = SyncProduccionChangeSerializer(many=True, required=False, default=list)


class SyncOutputAnimalSerializer(serializers.ModelSerializer):
    padre_uid = serializers.UUIDField(source='padre.uid', allow_null=True)
    madre_uid = serializers.UUIDField(source='madre.uid', allow_null=True)
    categoria_edad = serializers.SerializerMethodField()
    foto = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = [
            'uid', 'arete', 'especie', 'sexo', 'fecha_nacimiento',
            'nombre', 'raza', 'padre_uid', 'madre_uid',
            'observaciones', 'estado', 'fecha_estado', 'motivo_estado',
            'peso_nacimiento_kg', 'sync_status', 'updated_at',
            'categoria_edad', 'foto'
        ]

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)

    def get_foto(self, obj):
        if obj.foto:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.foto.url)
            return obj.foto.url
        return None


class SyncOutputProduccionSerializer(serializers.ModelSerializer):
    animal_uid = serializers.UUIDField(source='animal.uid', read_only=True)
    rendimiento_pct = serializers.SerializerMethodField()

    class Meta:
        model = Produccion
        fields = [
            'uid', 'animal_uid', 'fecha_esquila', 'peso_vellon_sucio_kg',
            'peso_vellon_limpio_kg', 'numero_esquila',
            'rendimiento_pct', 'observaciones', 'sync_status',
            'updated_at'
        ]

    def get_rendimiento_pct(self, obj):
        return obj.rendimiento_pct


class SyncOutputSerializer(serializers.Serializer):
    server_changes = SyncOutputAnimalSerializer(many=True)
    produccion_changes = SyncOutputProduccionSerializer(many=True)
    sync_timestamp = serializers.DateTimeField()


class CandidatoSerializer(serializers.ModelSerializer):
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo', 'fecha_nacimiento', 'categoria_edad']

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)


class ProduccionSerializer(serializers.ModelSerializer):
    animal_uid = serializers.SerializerMethodField()
    rendimiento_pct = serializers.SerializerMethodField()

    class Meta:
        model = Produccion
        fields = [
            'uid', 'animal_uid', 'fecha_esquila', 'peso_vellon_sucio_kg',
            'peso_vellon_limpio_kg', 'numero_esquila',
            'rendimiento_pct', 'observaciones', 'sync_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['uid', 'animal_uid', 'sync_status', 'created_at', 'updated_at', 'rendimiento_pct']

    def get_animal_uid(self, obj):
        return str(obj.animal.uid)

    def get_rendimiento_pct(self, obj):
        return obj.rendimiento_pct

    def validate_fecha_esquila(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de esquila no puede ser futura')
        return value

    def validate_peso_vellon_sucio_kg(self, value):
        if value <= 0:
            raise serializers.ValidationError('El peso del vellón sucio debe ser mayor a 0')
        if value > 9999.99:
            raise serializers.ValidationError('El peso del vellón sucio no puede superar 9999.99 kg')
        return value

    def validate_peso_vellon_limpio_kg(self, value):
        if value is not None:
            if value <= 0:
                raise serializers.ValidationError('El peso del vellón limpio debe ser mayor a 0')
            if value > 9999.99:
                raise serializers.ValidationError('El peso del vellón limpio no puede superar 9999.99 kg')
        return value

    def validate_numero_esquila(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('El número de esquila debe ser un entero positivo')
        return value

    def validate(self, data):
        limpio = data.get('peso_vellon_limpio_kg', self.instance.peso_vellon_limpio_kg if self.instance else None)
        sucio = data.get('peso_vellon_sucio_kg', self.instance.peso_vellon_sucio_kg if self.instance else None)
        if limpio is not None and sucio is not None and limpio > sucio:
            raise serializers.ValidationError({
                'peso_vellon_limpio_kg': 'El peso del vellón limpio no puede ser mayor al peso del vellón sucio'
            })

        animal = (
            data.get('animal')
            or (self.instance.animal if self.instance else None)
            or self.context.get('animal')
        )
        fecha_esquila = data.get('fecha_esquila', self.instance.fecha_esquila if self.instance else None)
        if animal and fecha_esquila and animal.fecha_nacimiento and fecha_esquila < animal.fecha_nacimiento:
            raise serializers.ValidationError({
                'fecha_esquila': 'La fecha de esquila no puede ser anterior a la fecha de nacimiento del animal'
            })

        if animal:
            numero_esquila = data.get('numero_esquila', self.instance.numero_esquila if self.instance else None)
            if numero_esquila is not None:
                qs = Produccion.objects.filter(animal=animal, numero_esquila=numero_esquila)
                if self.instance:
                    qs = qs.exclude(pk=self.instance.pk)
                if qs.exists():
                    raise serializers.ValidationError({
                        'numero_esquila': f'El animal ya tiene una esquila registrada con el número {numero_esquila}'
                    })

        return data


class ReporteSerializer(serializers.Serializer):
    format = serializers.ChoiceField(choices=['csv', 'pdf'], default='csv')