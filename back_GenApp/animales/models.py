from django.core.exceptions import ValidationError
from django.db import models
from django.conf import settings
import uuid


class Especie(models.TextChoices):
    ALPACA = 'alpaca', 'Alpaca'
    LLAMA = 'llama', 'Llama'
    OVINEO = 'ovino', 'Ovino'


class Sexo(models.TextChoices):
    HEMBRA = 'hembra', 'Hembra'
    MACHO = 'macho', 'Macho'


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
    activo = models.BooleanField(default=True)
    sync_status = models.CharField(max_length=15, choices=SyncStatus.choices, default=SyncStatus.SIC)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)

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

    def save(self, *args, **kwargs):
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