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