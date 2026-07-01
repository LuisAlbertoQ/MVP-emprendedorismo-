from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.utils.html import format_html
from .models import Usuario, SolicitudPago, ConfiguracionPago, Notificacion
from animales.models import Animal


class AnimalInline(admin.TabularInline):
    model = Animal
    extra = 0
    fields = ['arete', 'nombre', 'especie', 'sexo', 'estado', 'created_at']
    readonly_fields = ['arete', 'nombre', 'especie', 'sexo', 'estado', 'created_at']
    ordering = ['-created_at']
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(Usuario)
class UsuarioAdmin(BaseUserAdmin):
    list_display = ['telefono', 'first_name', 'plan', 'animales_count', 'is_active', 'created_at']
    list_filter = ['plan', 'is_active']
    search_fields = ['telefono', 'first_name']
    ordering = ['-created_at']
    inlines = [AnimalInline]

    fieldsets = (
        (None, {'fields': ('telefono', 'password')}),
        ('Información personal', {'fields': ('first_name',)}),
        ('Plan', {'fields': ('plan',)}),
        ('Estado', {'fields': ('is_active',)}),
        ('Fechas', {'fields': ('created_at', 'updated_at'), 'classes': ('collapse',)}),
    )
    readonly_fields = ['created_at', 'updated_at']
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('telefono', 'first_name', 'password1', 'password2'),
        }),
    )

    def animales_count(self, obj):
        return obj.animales.filter(estado='VIVO').count()
    animales_count.short_description = 'Animales'

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(SolicitudPago)
class SolicitudPagoAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'plan_solicitado', 'monto', 'estado', 'comprobante_preview', 'created_at']
    list_filter = ['estado', 'plan_solicitado']
    search_fields = ['usuario__telefono', 'usuario__first_name']
    ordering = ['-created_at']
    readonly_fields = ['uid', 'usuario', 'plan_solicitado', 'monto', 'comprobante_preview', 'numero_operacion', 'created_at']
    actions = ['aprobar_solicitud', 'rechazar_solicitud']

    def comprobante_preview(self, obj):
        if obj.comprobante:
            return format_html('<a href="{}" target="_blank"><img src="{}" width="200" /></a>',
                               obj.comprobante.url, obj.comprobante.url)
        return 'Sin comprobante'
    comprobante_preview.short_description = 'Comprobante'

    def _crear_notificacion(self, s, tipo, mensaje):
        Notificacion.objects.create(usuario=s.usuario, tipo=tipo, mensaje=mensaje)

    def aprobar_solicitud(self, request, queryset):
        for s in queryset.filter(estado=SolicitudPago.Estado.PENDIENTE):
            s.usuario.plan = s.plan_solicitado
            s.usuario.save()
            s.estado = SolicitudPago.Estado.APROBADO
            s.save()
            label = 'Criador' if s.plan_solicitado == 'criador' else 'Básico'
            self._crear_notificacion(
                s, Notificacion.Tipo.SOLICITUD_APROBADA,
                f'¡Tu plan {label} ha sido activado!'
            )
        self.message_user(request, f'{queryset.count()} solicitud(es) aprobada(s)')
    aprobar_solicitud.short_description = 'Aprobar solicitudes seleccionadas'

    def rechazar_solicitud(self, request, queryset):
        for s in queryset.filter(estado=SolicitudPago.Estado.PENDIENTE):
            s.estado = SolicitudPago.Estado.RECHAZADO
            s.save()
            label = 'Criador' if s.plan_solicitado == 'criador' else 'Básico'
            self._crear_notificacion(
                s, Notificacion.Tipo.SOLICITUD_RECHAZADA,
                f'Tu solicitud del plan {label} fue rechazada.'
            )
        self.message_user(request, f'{queryset.count()} solicitud(es) rechazada(s)')
    rechazar_solicitud.short_description = 'Rechazar solicitudes seleccionadas'

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(ConfiguracionPago)
class ConfiguracionPagoAdmin(admin.ModelAdmin):
    list_display = ['celular', 'monto_basico', 'monto_criador']

    def has_add_permission(self, request):
        if ConfiguracionPago.objects.exists():
            return False
        return True