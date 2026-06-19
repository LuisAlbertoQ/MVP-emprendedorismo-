from django.core.exceptions import ValidationError
from django.db import models
from django.conf import settings
from django.utils import timezone
import uuid


class Especie(models.TextChoices):
    ALPACA = 'alpaca', 'Alpaca'
    LLAMA = 'llama', 'Llama'
    OVINEO = 'ovino', 'Ovino'


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
        if self.peso_vellon_sucio_kg and self.peso_vellon_limpio_kg:
            raw = (self.peso_vellon_limpio_kg / self.peso_vellon_sucio_kg) * 100
            return round(raw, 2)
        return None

    def __str__(self):
        return f"{self.animal.arete} - {self.fecha_esquila} - {self.peso_vellon_sucio_kg}kg"