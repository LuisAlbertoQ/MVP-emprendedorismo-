from django.contrib import admin
from .models import Animal


@admin.register(Animal)
class AnimalAdmin(admin.ModelAdmin):
    list_display = ['arete', 'nombre', 'especie', 'sexo', 'usuario', 'estado', 'created_at']
    list_filter = ['especie', 'sexo', 'estado', 'sync_status']
    search_fields = ['arete', 'nombre', 'usuario__telefono']
    raw_id_fields = ['padre', 'madre']
    ordering = ['-created_at']