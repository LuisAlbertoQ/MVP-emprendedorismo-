from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('animales', '0005_alter_produccion_options_alter_animal_estado'),
    ]

    operations = [
        migrations.RunSQL(
            "ALTER TABLE producciones MODIFY COLUMN numero_esquila INT NULL",
            reverse_sql="ALTER TABLE producciones MODIFY COLUMN numero_esquila INT NOT NULL",
        ),
    ]
