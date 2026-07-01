import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models


class Plan(models.TextChoices):
    GRATUITO = 'gratuito', 'Gratuito'
    BASICO = 'basico', 'Básico'
    CRIADOR = 'criador', 'Criador'


class Usuario(AbstractUser):
    telefono = models.CharField(max_length=15, unique=True)
    plan = models.CharField(max_length=20, choices=Plan.choices, default=Plan.GRATUITO)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'telefono'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'usuarios'

    def __str__(self):
        return f"{self.telefono} - {self.plan}"

    @property
    def limite_animales(self):
        limites = {
            Plan.GRATUITO: 20,
            Plan.BASICO: 150,
            Plan.CRIADOR: 500,
        }
        return limites.get(self.plan, 20)

    @property
    def animales_count(self):
        return self.animales.filter(estado='VIVO').count()

    @property
    def generations_allowed(self):
        if self.plan == Plan.GRATUITO:
            return 2
        return 3


class SolicitudPago(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'pendiente', 'Pendiente'
        APROBADO = 'aprobado', 'Aprobado'
        RECHAZADO = 'rechazado', 'Rechazado'

    uid = models.UUIDField(unique=True, editable=False)
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='solicitudes_pago')
    plan_solicitado = models.CharField(max_length=20, choices=Plan.choices)
    monto = models.DecimalField(max_digits=10, decimal_places=2)
    comprobante = models.ImageField(upload_to='comprobantes/')
    numero_operacion = models.CharField(max_length=50, blank=True, default='')
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'solicitudes_pago'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.usuario.telefono} - {self.plan_solicitado} - {self.estado}"


class ConfiguracionPago(models.Model):
    celular = models.CharField(max_length=15, default='999888777')
    qr = models.ImageField(upload_to='pagos/', blank=True, null=True)
    monto_basico = models.DecimalField(max_digits=10, decimal_places=2, default=7.90)
    monto_criador = models.DecimalField(max_digits=10, decimal_places=2, default=19.90)

    class Meta:
        db_table = 'configuracion_pago'
        verbose_name = 'Configuración de Pago'
        verbose_name_plural = 'Configuración de Pago'

    def __str__(self):
        return f'Configuración Pago - {self.celular}'

    @classmethod
    def obtener(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class Notificacion(models.Model):
    class Tipo(models.TextChoices):
        SOLICITUD_APROBADA = 'solicitud_aprobada', 'Solicitud Aprobada'
        SOLICITUD_RECHAZADA = 'solicitud_rechazada', 'Solicitud Rechazada'
        SISTEMA = 'sistema', 'Sistema'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='notificaciones')
    mensaje = models.CharField(max_length=255)
    tipo = models.CharField(max_length=30, choices=Tipo.choices, default=Tipo.SISTEMA)
    leido = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notificaciones'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.usuario.telefono} - {self.mensaje[:30]}"