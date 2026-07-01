from django.contrib import admin
from django.contrib.admin import SimpleListFilter
from .models import Animal
from usuarios.models import Usuario


class UsuarioFiltro(SimpleListFilter):
    title = 'usuario'
    parameter_name = 'usuario'

    def lookups(self, request, model_admin):
        usuarios = Usuario.objects.all().values_list('id', 'telefono', 'first_name')
        return [(u[0], f'{u[1]} - {u[2]}') for u in usuarios]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(usuario_id=self.value())
        return queryset


@admin.register(Animal)
class AnimalAdmin(admin.ModelAdmin):
    list_display = ['arete', 'nombre', 'especie', 'sexo', 'usuario', 'estado', 'created_at']
    list_filter = [UsuarioFiltro, 'especie', 'sexo', 'estado', 'sync_status']
    search_fields = ['arete', 'nombre', 'usuario__telefono', 'usuario__first_name']
    raw_id_fields = ['padre', 'madre']
    ordering = ['-created_at']