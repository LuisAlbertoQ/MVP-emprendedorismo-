from datetime import date
from rest_framework import serializers
from django.db import IntegrityError
from .models import (
    Animal, Especie, Raza, Sexo, EstadoAnimal, Produccion,
    Empadre, Parto, Costo, VentaFibra, ResultadoGestacion, TipoCosto,
    RAZAS_POR_ESPECIE,
)
from .utils import calcular_categoria_edad, _edad_en_meses, calcular_coeficiente_consanguinidad, calcular_fecha_probable_parto


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
    raza = serializers.ChoiceField(choices=Raza.choices, required=False, allow_blank=True, default='')

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

        raza = data.get('raza', self.instance.raza if self.instance else '')
        if raza:
            valid_razas = RAZAS_POR_ESPECIE.get(especie, [])
            if valid_razas and raza not in valid_razas:
                valid_labels = ', '.join(dict(Raza.choices)[r] for r in valid_razas)
                raise serializers.ValidationError({
                    'raza': f'"{raza}" no es una raza válida para {especie}. Razas válidas: {valid_labels}'
                })

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
    raza = serializers.ChoiceField(choices=Raza.choices, required=False, allow_blank=True, default='')
    padre_uid = serializers.UUIDField(required=False, allow_null=True)
    madre_uid = serializers.UUIDField(required=False, allow_null=True)
    observaciones = serializers.CharField(required=False, default='')
    estado = serializers.ChoiceField(choices=EstadoAnimal.choices, required=False, default='VIVO')
    action = serializers.ChoiceField(choices=['create', 'update', 'delete'], default='create')
    local_updated_at = serializers.DateTimeField(required=False, allow_null=True)

    def validate(self, data):
        raza = data.get('raza', '')
        especie = data.get('especie')
        if raza and especie:
            valid_razas = RAZAS_POR_ESPECIE.get(especie, [])
            if valid_razas and raza not in valid_razas:
                valid_labels = ', '.join(dict(Raza.choices)[r] for r in valid_razas)
                raise serializers.ValidationError({
                    'raza': f'"{raza}" no es una raza válida para {especie}. Razas válidas: {valid_labels}'
                })
        return data


class SyncProduccionChangeSerializer(serializers.Serializer):
    uid = serializers.UUIDField(required=True)
    animal_uid = serializers.UUIDField(required=True)
    fecha_esquila = serializers.DateField()
    peso_vellon_sucio_kg = serializers.DecimalField(max_digits=6, decimal_places=2)
    peso_vellon_limpio_kg = serializers.DecimalField(max_digits=6, decimal_places=2, required=False, allow_null=True)
    numero_esquila = serializers.IntegerField(required=False, allow_null=True)
    diametro_fibra_micras = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, allow_null=True)
    factor_confort = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, allow_null=True)
    medulacion_pct = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, allow_null=True)
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
            'diametro_fibra_micras', 'factor_confort', 'medulacion_pct',
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
            'diametro_fibra_micras', 'factor_confort', 'medulacion_pct',
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


class ConsanguinidadSerializer(serializers.ModelSerializer):
    coeficiente = serializers.SerializerMethodField()
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'sexo', 'fecha_nacimiento', 'categoria_edad', 'coeficiente']

    def get_coeficiente(self, obj):
        return calcular_coeficiente_consanguinidad(obj)

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)


class EmpadreListSerializer(serializers.ModelSerializer):
    hembra_arete = serializers.CharField(source='hembra.arete', read_only=True)
    macho_arete = serializers.CharField(source='macho.arete', read_only=True)
    fecha_probable_parto = serializers.SerializerMethodField()

    class Meta:
        model = Empadre
        fields = '__all__'

    def get_fecha_probable_parto(self, obj):
        if not obj.fecha_empadre:
            return None
        return calcular_fecha_probable_parto(obj.hembra.especie, obj.fecha_empadre)


class EmpadreSerializer(serializers.ModelSerializer):
    hembra_uid = serializers.UUIDField(source='hembra.uid', read_only=True)
    macho_uid = serializers.UUIDField(source='macho.uid', read_only=True)
    hembra_write_uid = serializers.UUIDField(write_only=True, required=False)
    macho_write_uid = serializers.UUIDField(write_only=True, required=False)
    hembra_arete = serializers.CharField(source='hembra.arete', read_only=True)
    macho_arete = serializers.CharField(source='macho.arete', read_only=True)
    hembra_nombre = serializers.CharField(source='hembra.nombre', read_only=True, default='')
    macho_nombre = serializers.CharField(source='macho.nombre', read_only=True, default='')
    hembra_especie = serializers.CharField(source='hembra.especie', read_only=True)
    macho_especie = serializers.CharField(source='macho.especie', read_only=True)
    fecha_probable_parto = serializers.SerializerMethodField()

    class Meta:
        model = Empadre
        fields = [
            'uid', 'hembra', 'hembra_uid', 'macho', 'macho_uid',
            'hembra_write_uid', 'macho_write_uid',
            'hembra_arete', 'macho_arete', 'hembra_nombre', 'macho_nombre',
            'hembra_especie', 'macho_especie',
            'usuario', 'fecha_empadre', 'fecha_dx_gestacion',
            'resultado', 'fecha_probable_parto', 'observaciones',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'uid', 'hembra', 'macho', 'hembra_uid', 'macho_uid',
            'hembra_arete', 'macho_arete', 'hembra_nombre', 'macho_nombre',
            'hembra_especie', 'macho_especie',
            'usuario', 'fecha_probable_parto', 'created_at', 'updated_at'
        ]

    def get_fecha_probable_parto(self, obj):
        if not obj.fecha_empadre:
            return None
        return calcular_fecha_probable_parto(obj.hembra.especie, obj.fecha_empadre)

    def validate_hembra_write_uid(self, value):
        try:
            animal = Animal.objects.get(uid=value)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Hembra no encontrada')
        if animal.sexo != 'hembra':
            raise serializers.ValidationError('Debe ser una hembra')
        return value

    def validate_macho_write_uid(self, value):
        try:
            animal = Animal.objects.get(uid=value)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Macho no encontrado')
        if animal.sexo != 'macho':
            raise serializers.ValidationError('Debe ser un macho')
        return value

    def validate_fecha_empadre(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de empadre no puede ser futura')
        return value

    def validate(self, data):
        hembra_write_uid = data.get('hembra_write_uid')
        macho_write_uid = data.get('macho_write_uid')
        if hembra_write_uid and macho_write_uid:
            if hembra_write_uid == macho_write_uid:
                raise serializers.ValidationError('La hembra y el macho no pueden ser el mismo animal')
            try:
                hembra = Animal.objects.get(uid=hembra_write_uid)
                macho = Animal.objects.get(uid=macho_write_uid)
            except Animal.DoesNotExist:
                raise serializers.ValidationError('Animal no encontrado')
            if hembra.especie != macho.especie:
                raise serializers.ValidationError(
                    f'La hembra ({hembra.get_especie_display()}) y el macho '
                    f'({macho.get_especie_display()}) deben ser de la misma especie'
                )
            if hembra.sexo != 'hembra':
                raise serializers.ValidationError(
                    {'hembra_write_uid': 'El animal seleccionado como hembra debe ser de sexo hembra'}
                )
            if macho.sexo != 'macho':
                raise serializers.ValidationError(
                    {'macho_write_uid': 'El animal seleccionado como macho debe ser de sexo macho'}
                )
            activo = Empadre.objects.filter(
                hembra=hembra,
                resultado__in=['pendiente', 'positivo'],
            ).exclude(uid=self.instance.uid if self.instance else None).first()
            if activo:
                raise serializers.ValidationError(
                    f'La hembra ya tiene un empadre {activo.get_resultado_display()} '
                    f'del {activo.fecha_empadre}'
                )
        return data

    def create(self, validated_data):
        hembra = Animal.objects.get(uid=validated_data.pop('hembra_write_uid'))
        macho = Animal.objects.get(uid=validated_data.pop('macho_write_uid'))
        return Empadre.objects.create(
            hembra=hembra,
            macho=macho,
            **validated_data
        )


class PartoListSerializer(serializers.ModelSerializer):
    hembra_arete = serializers.CharField(source='hembra.arete', read_only=True)

    class Meta:
        model = Parto
        fields = '__all__'


class PartoSerializer(serializers.ModelSerializer):
    hembra_write_uid = serializers.UUIDField(write_only=True)
    empadre_write_uid = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    hembra_uid = serializers.UUIDField(source='hembra.uid', read_only=True)
    empadre_uid = serializers.UUIDField(source='empadre.uid', read_only=True, allow_null=True)
    hembra_arete = serializers.CharField(source='hembra.arete', read_only=True)
    hembra_nombre = serializers.CharField(source='hembra.nombre', read_only=True, default='')
    hembra_especie = serializers.CharField(source='hembra.especie', read_only=True)

    class Meta:
        model = Parto
        fields = [
            'uid', 'hembra', 'hembra_uid', 'hembra_write_uid',
            'empadre', 'empadre_uid', 'empadre_write_uid',
            'hembra_arete', 'hembra_nombre', 'hembra_especie',
            'usuario', 'fecha_parto', 'fecha_probable',
            'numero_crias', 'incidencias', 'observaciones',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'uid', 'hembra', 'hembra_uid', 'empadre', 'empadre_uid',
            'hembra_arete', 'hembra_nombre', 'hembra_especie',
            'usuario', 'created_at', 'updated_at'
        ]

    def validate_hembra_write_uid(self, value):
        try:
            animal = Animal.objects.get(uid=value)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Hembra no encontrada')
        if animal.sexo != 'hembra':
            raise serializers.ValidationError('Debe ser una hembra')
        return value

    def validate_fecha_parto(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de parto no puede ser futura')
        return value

    def validate(self, data):
        hembra_write_uid = data.get('hembra_write_uid')
        empadre_write_uid = data.get('empadre_write_uid')
        if empadre_write_uid and hembra_write_uid:
            try:
                empadre = Empadre.objects.get(uid=empadre_write_uid)
            except Empadre.DoesNotExist:
                raise serializers.ValidationError('Empadre no encontrado')
            if str(empadre.hembra.uid) != str(hembra_write_uid):
                hembra = Animal.objects.get(uid=hembra_write_uid)
                raise serializers.ValidationError(
                    f'El empadre seleccionado corresponde a la hembra '
                    f'{empadre.hembra.arete}, no a {hembra.arete}'
                )
        return data

    def create(self, validated_data):
        hembra = Animal.objects.get(uid=validated_data.pop('hembra_write_uid'))
        empadre_write_uid = validated_data.pop('empadre_write_uid', None)
        empadre = Empadre.objects.get(uid=empadre_write_uid) if empadre_write_uid else None
        return Parto.objects.create(
            hembra=hembra,
            empadre=empadre,
            **validated_data
        )


class CostoListSerializer(serializers.ModelSerializer):
    animal_arete = serializers.CharField(source='animal.arete', read_only=True)

    class Meta:
        model = Costo
        fields = '__all__'


class CostoSerializer(serializers.ModelSerializer):
    animal_write_uid = serializers.UUIDField(write_only=True)
    animal_uid = serializers.UUIDField(source='animal.uid', read_only=True)
    animal_arete = serializers.CharField(source='animal.arete', read_only=True)
    animal_nombre = serializers.CharField(source='animal.nombre', read_only=True, default='')
    animal_especie = serializers.CharField(source='animal.especie', read_only=True)

    class Meta:
        model = Costo
        fields = [
            'uid', 'animal', 'animal_uid', 'animal_write_uid',
            'animal_arete', 'animal_nombre', 'animal_especie',
            'usuario', 'tipo', 'monto', 'fecha', 'descripcion',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'uid', 'animal', 'animal_uid', 'animal_arete',
            'animal_nombre', 'animal_especie',
            'usuario', 'created_at', 'updated_at'
        ]

    def validate_animal_write_uid(self, value):
        try:
            Animal.objects.get(uid=value)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Animal no encontrado')
        return value

    def validate_fecha(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha no puede ser futura')
        return value

    def create(self, validated_data):
        animal = Animal.objects.get(uid=validated_data.pop('animal_write_uid'))
        return Costo.objects.create(animal=animal, **validated_data)


class VentaFibraListSerializer(serializers.ModelSerializer):
    animal_arete = serializers.CharField(source='animal.arete', read_only=True)
    ingreso_total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = VentaFibra
        fields = '__all__'


class VentaFibraSerializer(serializers.ModelSerializer):
    animal_write_uid = serializers.UUIDField(write_only=True)
    produccion_write_uid = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    animal_uid = serializers.UUIDField(source='animal.uid', read_only=True)
    produccion_uid = serializers.UUIDField(source='produccion.uid', read_only=True, allow_null=True)
    animal_arete = serializers.CharField(source='animal.arete', read_only=True)
    animal_nombre = serializers.CharField(source='animal.nombre', read_only=True, default='')
    animal_especie = serializers.CharField(source='animal.especie', read_only=True)

    class Meta:
        model = VentaFibra
        fields = [
            'uid', 'produccion', 'produccion_uid', 'produccion_write_uid',
            'animal', 'animal_uid', 'animal_write_uid',
            'animal_arete', 'animal_nombre', 'animal_especie',
            'usuario', 'kg_vendidos', 'precio_kg', 'comprador',
            'fecha_venta', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'uid', 'produccion', 'produccion_uid', 'animal', 'animal_uid',
            'animal_arete', 'animal_nombre', 'animal_especie',
            'usuario', 'created_at', 'updated_at'
        ]

    def validate_animal_write_uid(self, value):
        try:
            Animal.objects.get(uid=value)
        except Animal.DoesNotExist:
            raise serializers.ValidationError('Animal no encontrado')
        return value

    def validate_fecha_venta(self, value):
        if value > date.today():
            raise serializers.ValidationError('La fecha de venta no puede ser futura')
        return value

    def create(self, validated_data):
        animal = Animal.objects.get(uid=validated_data.pop('animal_write_uid'))
        produccion_write_uid = validated_data.pop('produccion_write_uid', None)
        produccion = Produccion.objects.filter(uid=produccion_write_uid).first() if produccion_write_uid else None
        return VentaFibra.objects.create(animal=animal, produccion=produccion, **validated_data)


class RankingFibraSerializer(serializers.ModelSerializer):
    rendimiento_pct = serializers.SerializerMethodField()
    categoria_edad = serializers.SerializerMethodField()

    class Meta:
        model = Animal
        fields = ['uid', 'arete', 'nombre', 'especie', 'categoria_edad',
                  'diametro_fibra_micras', 'factor_confort', 'medulacion_pct',
                  'rendimiento_pct']

    def get_rendimiento_pct(self, obj):
        return obj.rendimiento_pct

    def get_categoria_edad(self, obj):
        return calcular_categoria_edad(obj.especie, obj.fecha_nacimiento)


class ReporteSerializer(serializers.Serializer):
    format = serializers.ChoiceField(choices=['csv', 'pdf'], default='csv')