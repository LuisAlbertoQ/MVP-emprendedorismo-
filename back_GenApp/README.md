# GeneApp Andina - Backend

API REST para gestión de criadores de alpacas, llamas y ovinos en la región andina.

## Tecnologías

- **Python 3.12+**
- **Django 4.2 LTS**
- **Django REST Framework 3.14+**
- **MySQL 8.0+** (Laragon)
- **SimpleJWT** - Autenticación por tokens
- **drf-spectacular** - Documentación OpenAPI

## Requisitos

- Python 3.12+
- MySQL 8.0+ (Laragon)
- Entorno virtual (venv)

## Instalación

### 1. Activar entorno virtual

```bash
cd back_GenApp
.\env\Scripts\Activate.ps1
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Configurar base de datos

Crear la base de datos en Laragon (MySQL):

```sql
CREATE DATABASE geneapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 4. Variables de entorno

Editar `.env` en la raíz del proyecto:

```env
SECRET_KEY=tu-clave-secreta-aqui
DEBUG=True
DB_NAME=geneapp
DB_USER=root
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=3306
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:8000,http://127.0.0.1:8000
```

### 5. Ejecutar migraciones

```bash
python manage.py migrate
```

### 6. Iniciar servidor

```bash
python manage.py runserver
```

El servidor estará disponible en: `http://localhost:8000`

## Endpoints de la API

### Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/auth/register/` | Registro de usuario |
| POST | `/api/v1/auth/login/` | Login (retorna access/refresh token) |
| POST | `/api/v1/auth/refresh/` | Refrescar token JWT |
| GET | `/api/v1/auth/perfil/` | Obtener perfil y plan |
| POST | `/api/v1/auth/cambiar-plan/` | Cambiar plan (basico/criador) |

### Animales

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/animales/` | Listar animales (paginado) |
| POST | `/api/v1/animales/` | Crear animal |
| GET | `/api/v1/animales/{uid}/` | Detalle de animal |
| PUT/PATCH | `/api/v1/animales/{uid}/` | Actualizar animal |
| DELETE | `/api/v1/animales/{uid}/` | Eliminar (soft delete) |
| GET | `/api/v1/animales/{uid}/arbol/` | Árbol genealógico |

### Sincronización

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/sync/` | Sincronizar cambios offline |

### Reportes (solo planes pagos)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/reporte/animales/?format=csv` | Descargar CSV |
| GET | `/api/v1/reporte/animales/?format=pdf` | Descargar PDF |

### Documentación

| Endpoint | Descripción |
|----------|-------------|
| `/api/schema/` | Schema OpenAPI (JSON) |
| `/api/docs/` | Swagger UI |

## Modelos de Datos

### Usuario
- `telefono` - Identificador único (login)
- `plan` - Gratuito, Básico, Criador
- `first_name` - Nombre completo

### Animal
- `uid` - UUID único
- `arete` - Código único por usuario
- `especie` - alpaca, llama, ovino
- `sexo` - hembra, macho
- `fecha_nacimiento` - Fecha de nacimiento
- `nombre` - Nombre opcional
- `raza` - Raza opcional
- `padre` / `madre` - Relaciones a otros animales
- `foto` - Imagen del animal
- `activo` - Soft delete
- `sync_status` - Estado de sincronización

## Planes de Suscripción

| Plan | Límite Animales | Generaciones Árbol |
|------|-----------------|-------------------|
| Gratuito | 20 | 2 |
| Básico | 150 | 3 |
| Criador | 500 | 3 |

## Ejemplos de Uso

### Registro
```bash
curl -X POST http://localhost:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"telefono": "999888777", "nombre": "Juan Perez", "password": "123456"}'
```

### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"telefono": "999888777", "password": "123456"}'
```

### Crear Animal
```bash
curl -X POST http://localhost:8000/api/v1/animales/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "arete": "ARE-001",
    "especie": "alpaca",
    "sexo": "macho",
    "fecha_nacimiento": "2024-01-15",
    "nombre": "Trueno"
  }'
```

### Ver Árbol Genealógico
```bash
curl -X GET http://localhost:8000/api/v1/animales/{uid}/arbol/ \
  -H "Authorization: Bearer <token>"
```

## Estructura del Proyecto

```
back_GenApp/
├── geneapp/              # Configuración del proyecto
│   ├── settings.py       # Configuración Django
│   └── urls.py           # Rutas principales
├── usuarios/             # App de usuarios
│   ├── models.py         # Modelo Usuario
│   ├── serializers.py    # Serializers de autenticación
│   ├── views.py          # Vistas de autenticación
│   └── urls.py           # Rutas de usuarios
├── animales/            # App de animales
│   ├── models.py         # Modelo Animal
│   ├── serializers.py    # Serializers de animales
│   ├── views.py          # Vistas y ViewSets
│   └── urls.py           # Rutas de animales
├── media/               # Archivos subidos
│   └── animales/         # Fotos de animales
├── requirements.txt     # Dependencias Python
└── .env                 # Variables de entorno
```

## Comandos Útiles

```bash
# Crear migraciones
python manage.py makemigrations

# Aplicar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Verificar configuración
python manage.py check

#shell interactivo
python manage.py shell
```

##_LIBRERIAS

```
Django==4.2.11
djangorestframework==3.14.0
djangorestframework-simplejwt==5.3.1
django-cors-headers==4.3.1
drf-spectacular==0.26.5
Pillow==10.0.0
python-decouple==3.8
mysqlclient==2.2.4
gunicorn==21.2.0
reportlab==4.0.0
```

## Producción

Para deploy en producción:

```bash
pip install -r requirements.txt
python manage.py collectstatic
gunicorn geneapp.wsgi:application
```

Configurar Nginx como proxy reverso y habilitar HTTPS con Let's Encrypt.