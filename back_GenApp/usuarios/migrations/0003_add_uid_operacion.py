import uuid
from django.db import migrations, models


def gen_uuid(apps, schema_editor):
    SolicitudPago = apps.get_model('usuarios', 'SolicitudPago')
    for row in SolicitudPago.objects.all():
        row.uid = uuid.uuid4()
        row.save(update_fields=['uid'])


class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0002_configuracionpago_solicitudpago'),
    ]

    operations = [
        migrations.AddField(
            model_name='solicitudpago',
            name='numero_operacion',
            field=models.CharField(blank=True, default='', max_length=50),
        ),
        migrations.AddField(
            model_name='solicitudpago',
            name='uid',
            field=models.UUIDField(null=True, editable=False),
        ),
        migrations.RunPython(gen_uuid, reverse_code=migrations.RunPython.noop),
        migrations.AlterField(
            model_name='solicitudpago',
            name='uid',
            field=models.UUIDField(unique=True, editable=False, null=False),
        ),
    ]
