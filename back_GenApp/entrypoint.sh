#!/bin/sh

set -e

echo "Esperando a MySQL..."
MAX_RETRIES=30
RETRY_COUNT=0
until python -c "
import MySQLdb, os, sys
try:
    MySQLdb.connect(host=os.environ['DB_HOST'], user=os.environ['DB_USER'], password=os.environ['DB_PASSWORD'], database=os.environ['DB_NAME'], connect_timeout=5)
    sys.exit(0)
except MySQLdb.OperationalError as e:
    sys.exit(1 if 'Access denied' in str(e) else 2)
except Exception:
    sys.exit(2)
"; do
    CODE=$?
    if [ $CODE -eq 1 ]; then
        echo "ERROR: Credenciales MySQL incorrectas. Verifica DB_USER y DB_PASSWORD."
        exit 1
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: MySQL no disponible después de $MAX_RETRIES intentos."
        exit 1
    fi
    echo "MySQL no disponible aún (intento $RETRY_COUNT/$MAX_RETRIES)..."
    sleep 2
done
echo "MySQL listo."

echo "Corriendo migraciones..."
python manage.py migrate --noinput

echo "Recolectando archivos estáticos..."
python manage.py collectstatic --noinput

echo "Iniciando servidor..."
exec gunicorn geneapp.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120
