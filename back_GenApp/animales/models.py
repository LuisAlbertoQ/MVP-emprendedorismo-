from django.core.exceptions import ValidationError
from django.db import models
from django.conf import settings
from django.utils import timezone
import uuid


class Especie(models.TextChoices):
    ALPACA = 'alpaca', 'Alpaca'
    LLAMA = 'llama', 'Llama'
    OVINEO = 'ovino', 'Ovino'


class Raza(models.TextChoices):
    HUACAYA = 'huacaya', 'Huacaya'
    SURI = 'suri', 'Suri'
    KARA = 'kara', "K'ara"
    CHAQU = 'chaqu', 'Chaqu'
    CRIOLLO = 'criollo', 'Criollo'
    CORRIEDALE = 'corriedale', 'Corriedale'
    JUNIN = 'junin', 'Junín'
    HAMPSHIRE_DOWN = 'hampshire_down', 'Hampshire Down'
    BLACK_BELLY = 'black_belly', 'Black Belly'
    ASSAF = 'assaf', 'Assaf'


RAZAS_POR_ESPECIE = {
    'alpaca': ['huacaya', 'suri'],
    'llama': ['kara', 'chaqu'],
    'ovino': ['criollo', 'corriedale', 'junin', 'hampshire_down', 'black_belly', 'assaf'],
}


class Sexo(models.TextChoices):
    HEMBRA = 'hembra', 'Hembra'
    MACHO = 'macho', 'Macho'


class EstadoAnimal(models.TextChoices):
    VIVO = 'VIVO', 'Vivo'
    VENDIDO = 'VENDIDO', 'Vendido'
    MUERTO = 'MUERTO', 'Muerto'


class SyncStatus(models.TextChoices):
    PEN = 'pendiente', 'Pendiente'
    SIC = 'sincronizado', 'Sincronizado'
    ERR = 'error', 'Error'


class Animal(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='animales')
    arete = models.CharField(max_length=50)
    especie = models.CharField(max_length=10, choices=Especie.choices)
    sexo = models.CharField(max_length=10, choices=Sexo.choices)
    fecha_nacimiento = models.DateField()
    nombre = models.CharField(max_length=100, blank=True, default='')
    raza = models.CharField(max_length=50, blank=True, default='')
    padre = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='hijos_paternos')
    madre = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='hijos_maternos')
    foto = models.ImageField(upload_to='animales/', null=True, blank=True)
    observaciones = models.TextField(blank=True, default='')
    estado = models.CharField(max_length=10, choices=EstadoAnimal.choices, default=EstadoAnimal.VIVO)
    fecha_estado = models.DateTimeField(null=True, blank=True)
    motivo_estado = models.TextField(blank=True, default='')
    peso_nacimiento_kg = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    sync_status = models.CharField(max_length=15, choices=SyncStatus.choices, default=SyncStatus.SIC)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'animales'
        verbose_name = 'Animal'
        verbose_name_plural = 'Animales'
        ordering = ['-created_at']
        unique_together = ['usuario', 'arete']

    def __str__(self):
        return f"{self.arete} - {self.nombre or self.especie}"

    def clean(self):
        if self.padre and self.padre.id == self.id:
            raise ValidationError({'padre': 'Un animal no puede ser su propio padre'})
        if self.madre and self.madre.id == self.id:
            raise ValidationError({'madre': 'Un animal no puede ser su propia madre'})
        self.verificar_padres()

    def save(self, *args, **kwargs):
        if self.pk:
            try:
                old = Animal.objects.get(pk=self.pk)
                if old.estado != self.estado:
                    self.fecha_estado = timezone.now()
            except Animal.DoesNotExist:
                pass
        elif self.estado == EstadoAnimal.VIVO:
            self.fecha_estado = timezone.now()
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def padre_arete(self):
        return self.padre.arete if self.padre else None

    @property
    def madre_arete(self):
        return self.madre.arete if self.madre else None

    def puede_tener_padres_de(self, otro_animal):
        if self.pk == otro_animal.pk:
            return False
        if self.padre and self.padre.pk == otro_animal.pk:
            return False
        if self.madre and self.madre.pk == otro_animal.pk:
            return False
        return True

    def verificar_padres(self):
        if self.padre and self.padre.usuario != self.usuario:
            raise ValidationError({'padre': 'El padre debe pertenecer al mismo usuario'})
        if self.madre and self.madre.usuario != self.usuario:
            raise ValidationError({'madre': 'La madre debe pertenecer al mismo usuario'})


class Produccion(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='producciones')
    fecha_esquila = models.DateField()
    peso_vellon_sucio_kg = models.DecimalField(max_digits=6, decimal_places=2)
    peso_vellon_limpio_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    numero_esquila = models.PositiveIntegerField(null=True, blank=True)
    diametro_fibra_micras = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Diámetro de fibra (micras)')
    factor_confort = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Factor de confort (%)')
    medulacion_pct = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Medulación (%)')
    observaciones = models.TextField(blank=True, default='')
    sync_status = models.CharField(max_length=15, choices=SyncStatus.choices, default=SyncStatus.SIC)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'producciones'
        verbose_name = 'Producción'
        verbose_name_plural = 'Producciones'
        ordering = ['animal', 'numero_esquila']
        constraints = [
            models.UniqueConstraint(fields=['animal', 'numero_esquila'], name='uq_animal_numero_esquila')
        ]
        indexes = [
            models.Index(fields=['animal', 'fecha_esquila'], name='idx_producciones_animal_fecha'),
        ]

    @property
    def rendimiento_pct(self):
        if self.peso_vellon_sucio_kg and self.peso_vellon_sucio_kg > 0 and self.peso_vellon_limpio_kg:
            raw = (self.peso_vellon_limpio_kg / self.peso_vellon_sucio_kg) * 100
            return round(raw, 2)
        return None

    def __str__(self):
        return f"{self.animal.arete} - {self.fecha_esquila} - {self.peso_vellon_sucio_kg}kg"


class ResultadoGestacion(models.TextChoices):
    PENDIENTE = 'pendiente', 'Pendiente'
    POSITIVO = 'positivo', 'Positivo'
    NEGATIVO = 'negativo', 'Negativo'
    NO_REVISADO = 'no_revisado', 'No revisado'


class Empadre(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    hembra = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='empadres_hembra')
    macho = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='empadres_macho')
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='empadres')
    fecha_empadre = models.DateField()
    fecha_dx_gestacion = models.DateField(null=True, blank=True)
    resultado = models.CharField(max_length=20, choices=ResultadoGestacion.choices, default=ResultadoGestacion.PENDIENTE)
    observaciones = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'empadres'
        verbose_name = 'Empadre'
        verbose_name_plural = 'Empadres'
        ordering = ['-fecha_empadre']

    def __str__(self):
        return f"{self.hembra.arete} x {self.macho.arete} - {self.fecha_empadre}"


class Parto(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    empadre = models.ForeignKey(Empadre, on_delete=models.SET_NULL, null=True, blank=True, related_name='partos')
    hembra = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='partos')
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='partos')
    fecha_parto = models.DateField()
    fecha_probable = models.DateField(null=True, blank=True)
    numero_crias = models.PositiveSmallIntegerField(default=1)
    incidencias = models.TextField(blank=True, default='')
    observaciones = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'partos'
        verbose_name = 'Parto'
        verbose_name_plural = 'Partos'
        ordering = ['-fecha_parto']

    def __str__(self):
        return f"Parto de {self.hembra.arete} - {self.fecha_parto}"


class TipoCosto(models.TextChoices):
    ALIMENTACION = 'alimentacion', 'Alimentación'
    SANIDAD = 'sanidad', 'Sanidad'
    ESQUILA = 'esquila', 'Esquila'
    TRANSPORTE = 'transporte', 'Transporte'
    OTRO = 'otro', 'Otro'


class Costo(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='costos')
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='costos')
    tipo = models.CharField(max_length=20, choices=TipoCosto.choices)
    monto = models.DecimalField(max_digits=10, decimal_places=2)
    fecha = models.DateField()
    descripcion = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'costos'
        verbose_name = 'Costo'
        verbose_name_plural = 'Costos'
        ordering = ['-fecha']

    def __str__(self):
        return f"{self.animal.arete} - {self.tipo} - S/{self.monto}"


class VentaFibra(models.Model):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    produccion = models.ForeignKey(Produccion, on_delete=models.SET_NULL, null=True, blank=True, related_name='ventas')
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='ventas_fibra')
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ventas_fibra')
    kg_vendidos = models.DecimalField(max_digits=8, decimal_places=2)
    precio_kg = models.DecimalField(max_digits=10, decimal_places=2)
    comprador = models.CharField(max_length=200, blank=True, default='')
    fecha_venta = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ventas_fibra'
        verbose_name = 'Venta de fibra'
        verbose_name_plural = 'Ventas de fibra'
        ordering = ['-fecha_venta']

    @property
    def ingreso_total(self):
        return round(self.kg_vendidos * self.precio_kg, 2)

    def __str__(self):
        return f"{self.animal.arete} - {self.kg_vendidos}kg x S/{self.precio_kg}"