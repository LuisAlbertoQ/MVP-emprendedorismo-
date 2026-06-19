from django.db import migrations, models


def migrar_activo_a_estado(apps, schema_editor):
    Animal = apps.get_model('animales', 'Animal')
    for animal in Animal.objects.all():
        animal.estado = 'VIVO' if animal.activo else 'VENDIDO'
        animal.save(update_fields=['estado'])


def reverse_migrar_estado(apps, schema_editor):
    Animal = apps.get_model('animales', 'Animal')
    for animal in Animal.objects.all():
        animal.activo = animal.estado == 'VIVO'
        animal.save(update_fields=['activo'])


class Migration(migrations.Migration):

    dependencies = [
        ('animales', '0003_produccion'),
    ]

    operations = [
        migrations.AddField(
            model_name='animal',
            name='estado',
            field=models.CharField(choices=[('VIVO', 'Vivo'), ('VENDIDO', 'Vendido'), ('MUERTO', 'Muerto')], default='VIVO', max_length=10),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='animal',
            name='fecha_estado',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='animal',
            name='motivo_estado',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='animal',
            name='peso_nacimiento_kg',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True),
        ),
        migrations.RenameField(
            model_name='produccion',
            old_name='peso_vellon_kg',
            new_name='peso_vellon_sucio_kg',
        ),
        migrations.AddField(
            model_name='produccion',
            name='peso_vellon_limpio_kg',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=6, null=True),
        ),
        migrations.AddField(
            model_name='produccion',
            name='numero_esquila',
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
        migrations.RemoveField(
            model_name='produccion',
            name='rendimiento_pct',
        ),
        migrations.RunPython(migrar_activo_a_estado, reverse_migrar_estado),
        migrations.RemoveField(
            model_name='animal',
            name='activo',
        ),
        migrations.RemoveField(
            model_name='animal',
            name='deleted_at',
        ),
    ]
