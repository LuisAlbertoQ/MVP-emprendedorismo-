# GeneApp Andina - Backend

API REST para gestión de criadores de alpacas, llamas y ovinos en la región andina. Incluye clasificación etaria automática y validación parental por edad real.

## Tecnologías

- **Python 3.12+**
- **Django 4.2 LTS**
- **Django REST Framework 3.14+**
- **MySQL 8.0+** (Laragon)
- **SimpleJWT** - Autenticación por tokens
- **drf-spectacular** - Documentación OpenAPI
- **ReportLab** - Generación de PDF
- **Pillow** - Manejo de imágenes

## Requisitos

- Python 3.12+
- MySQL 8.0+ (Laragon)
- Entorno virtual (venv) - ya creado en `env/`

## Instalación

### 1. Activar entorno virtual

```bash
cd back_GenApp
.\env\Scripts\python.exe -m pip install -r requirements.txt
```

> Si la ejecución de scripts está deshabilitada, usa directamente el Python del venv:
> `.\env\Scripts\python.exe manage.py <comando>`

### 2. Configurar base de datos

Crear la base de datos en Laragon (MySQL):

```sql
CREATE DATABASE geneapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Variables de entorno

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

### 4. Migraciones

```bash
.\env\Scripts\python.exe manage.py migrate
```

### 5. Iniciar servidor

```bash
.\env\Scripts\python.exe manage.py runserver
```

Servidor disponible en: `http://localhost:8000`

### 6. Correr tests

```bash
.\env\Scripts\python.exe manage.py test
```

Servidor disponible en: `http://localhost:8000`

## Endpoints de la API

### Autenticación (prefix: `/api/v1/auth/`)

| Método | Endpoint | Descripción | Planes |
|--------|----------|-------------|--------|
| POST | `register/` | Registro (teléfono, nombre, password) | Todos |
| POST | `login/` | Login (teléfono, password) → access + refresh | Todos |
| POST | `refresh/` | Refrescar token JWT | Todos |
| GET | `perfil/` | Perfil + plan + animales usados | Todos |
| POST | `cambiar-plan/` | Cambiar plan (basico/criador) | Todos |
| POST | `webhook-yape/` | Webhook para pagos Yape (stub) | Todos |

### Animales (prefix: `/api/v1/animales/`)

| Método | Endpoint | Descripción | Planes |
|--------|----------|-------------|--------|
| GET | `/` | Listar (paginado, ?especie=&sexo=&activo=&search=) — incluye `categoria_edad` | Todos |
| POST | `/` | Crear animal | Todos (limite) |
| GET | `/{uid}/` | Detalle — incluye `categoria_edad` | Todos |
| PUT | `/{uid}/` | Actualizar (completo) | Todos |
| PATCH | `/{uid}/` | Actualizar (parcial) | Todos |
| DELETE | `/{uid}/` | Eliminar (soft delete) | Todos |
| GET | `/{uid}/arbol/` | Árbol genealógico (2-3 gen) — incluye `categoria_edad` por nodo | Todos |
| GET | `/candidatos/` | Lista para selector de padres — incluye `categoria_edad`, acepta `?especie=` | Todos |
| GET | `/resumen/` | Stats (total, machos, hembras, especies) | Todos |

### Sincronización (prefix: `/api/v1/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `sync/` | Sincronización offline (envía y recibe cambios) — incluye `categoria_edad` |

### Reportes (prefix: `/api/v1/reporte/`)

| Método | Endpoint | Descripción | Planes |
|--------|----------|-------------|--------|
| GET | `animales/?format=csv` | Descargar CSV | Básico/Criador |
| GET | `animales/?format=pdf` | Descargar PDF | Básico/Criador |

### Documentación

| Endpoint | Descripción |
|----------|-------------|
| `/api/schema/` | Schema OpenAPI (JSON) |
| `/api/docs/` | Swagger UI |

## Estado de Implementación

| Funcionalidad | Estado |
|---------------|--------|
| Registro y login JWT | ✅ Completo |
| Perfil de usuario | ✅ Completo |
| Planes (Gratuito/Básico/Criador) | ✅ Completo |
| CRUD de animales | ✅ Completo |
| Validación padre/madre (especie, sexo, edad en meses) | ✅ Completo |
| Categoría de edad automática (cría/tui_menor/tui_mayor/borrego/adulto) | ✅ Completo |
| Límite de animales por plan | ✅ Completo |
| Árbol genealógico (2-3 gen) | ✅ Completo |
| Sincronización offline | ✅ Completo |
| Reportes CSV/PDF | ✅ Completo |
| Búsqueda por arete/nombre | ✅ Completo |
| Filtros (especie, sexo, activo, search) | ✅ Completo |
| Candidatos con categoría de edad y filtro especie | ✅ Completo |
| Soft delete | ✅ Completo |
| Webhook Yape | ⚠️ Stub básico |
| Notificaciones push | ❌ Futura versión |
| Exportación PDF/Excel | ✅ CSV y PDF |

## Modelos de Datos

### Usuario
- `telefono` - Identificador único (login)
- `plan` - Gratuito / Básico / Criador
- `first_name` - Nombre completo
- `limite_animales` - Propiedad calculada según plan
- `animales_count` - Propiedad calculada

### Animal
- `uid` - UUID único (identificador para API)
- `arete` - Código único por usuario
- `especie` - alpaca / llama / ovino
- `sexo` - hembra / macho
- `fecha_nacimiento` - Fecha de nacimiento (usada para calcular categoría de edad)
- `nombre` - Opcional
- `raza` - Opcional
- `padre` / `madre` - Relaciones autopreferenciales
- `foto` - Imagen del animal (ImageField)
- `activo` - Borrado lógico
- `sync_status` - sincronizado / pendiente / error
- `created_at` / `updated_at` / `deleted_at`

### Categoría de Edad (calculada, no almacenada)
La categoría se calcula en `animales/utils.py` mediante `calcular_categoria_edad(especie, fecha_nacimiento)`:

| Especie | Cría | Juvenil 1 | Juvenil 2 | Adulto |
|---------|------|-----------|-----------|--------|
| Alpaca/Llama | < 8 meses | Tui Menor (8-12m) | Tui Mayor (12-24m) | ≥ 24 meses |
| Ovino | < 4 meses | Borrego (4-18m) | — | ≥ 18 meses |

Presente en todos los endpoints de animales como campo de solo lectura `categoria_edad`. La validación parental usa meses reales (`_edad_en_meses`) en lugar de comparación directa de fechas.

## Planes de Suscripción

| Plan | Precio | Límite Animales | Generaciones Árbol | Sincronización | Reportes |
|------|--------|:---------------:|:------------------:|:--------------:|:--------:|
| Gratuito | Gratis | 20 | 2 | Local | ❌ |
| Básico | S/ 7.90/mes | 150 | 3 | Nube | ❌ |
| Criador | S/ 19.90/mes | 500 | 3 | Nube | ✅ CSV/PDF |

## Flujo de Pruebas en Postman

### 1. Registro
```
POST http://localhost:8000/api/v1/auth/register/
{
  "telefono": "999888777",
  "nombre": "Juan Pérez",
  "password": "123456"
}
```

### 2. Login (obtener token)
```
POST http://localhost:8000/api/v1/auth/login/
{
  "telefono": "999888777",
  "password": "123456"
}
```
→ Copiar `access` token → Auth: Bearer Token

### 3. Ver perfil
```
GET http://localhost:8000/api/v1/auth/perfil/
```

### 4. Crear animales
```
POST http://localhost:8000/api/v1/animales/
{
  "arete": "PADRE-001",
  "especie": "alpaca",
  "sexo": "macho",
  "fecha_nacimiento": "2022-06-15",
  "nombre": "Relámpago",
  "raza": "Suri"
}
```

### 5. Crear hijo con padres
```
POST http://localhost:8000/api/v1/animales/
{
  "arete": "HIJO-001",
  "especie": "alpaca",
  "sexo": "macho",
  "fecha_nacimiento": "2024-01-10",
  "nombre": "Tormenta",
  "raza": "Huacaya",
  "padre": "<uid_padre>",
  "madre": "<uid_madre>"
}
```

### 6. Listar con filtros
```
GET http://localhost:8000/api/v1/animales/?especie=alpaca&sexo=macho
```

### 7. Detalle, actualizar, árbol
```
GET     /api/v1/animales/{uid}/
PATCH   /api/v1/animales/{uid}/   {"nombre": "Nuevo nombre"}
GET     /api/v1/animales/{uid}/arbol/
```

### 8. Sincronización
```
POST http://localhost:8000/api/v1/sync/
{
  "last_sync": null,
  "changes": [
    {
      "uid": "<nuevo-uuid>",
      "arete": "SYNC-001",
      "especie": "ovino",
      "sexo": "macho",
      "fecha_nacimiento": "2024-02-15",
      "action": "create"
    }
  ]
}
```

### 9. Cambiar plan y reportes
```
POST http://localhost:8000/api/v1/auth/cambiar-plan/
{"plan": "basico"}

GET http://localhost:8000/api/v1/reporte/animales/?format=csv
```

## Tests

```bash
.\env\Scripts\python.exe manage.py test
```

61 tests — modelos, serializers, views, límites por plan, árbol genealógico, validación padre/madre, categoría de edad (11 tests).

## Estructura del Proyecto

```
back_GenApp/
├── geneapp/              # Configuración del proyecto
│   ├── settings.py       # Configuración Django
│   └── urls.py           # Rutas principales
├── usuarios/             # App de usuarios
│   ├── models.py         # Modelo Usuario (AbstractUser)
│   ├── serializers.py    # Register, Login, Perfil, CambioPlan
│   ├── views.py          # RegisterView, LoginView, PerfilView, etc.
│   └── urls.py           # Rutas de usuarios
├── animales/             # App de animales
│   ├── models.py         # Modelo Animal (con relaciones)
│   ├── serializers.py    # CRUD, Sync, Reporte serializers (con categoria_edad)
│   ├── views.py          # AnimalViewSet, SyncView, ReporteView
│   ├── utils.py          # calcular_categoria_edad, _edad_en_meses
│   └── urls.py           # Rutas de animales
├── env/                  # Entorno virtual Python 3.12
├── media/                # Archivos subidos (fotos)
│   └── animales/         # Fotos de animales
├── requirements.txt      # Dependencias Python
├── .env                  # Variables de entorno
└── README.md             # Este archivo
```

## Dependencias

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

## Comandos Útiles

```bash
# Activar entorno virtual (con python directo sin policy)
.\env\Scripts\python.exe manage.py <comando>

# Crear migraciones
.\env\Scripts\python.exe manage.py makemigrations

# Aplicar migraciones
.\env\Scripts\python.exe manage.py migrate

# Crear superusuario
.\env\Scripts\python.exe manage.py createsuperuser

# Verificar configuración
.\env\Scripts\python.exe manage.py check

# Shell interactivo
.\env\Scripts\python.exe manage.py shell

# Iniciar servidor
.\env\Scripts\python.exe manage.py runserver
```

## Producción

Para deploy en producción:

```bash
pip install -r requirements.txt
python manage.py collectstatic
gunicorn geneapp.wsgi:application
```

Configurar Nginx como proxy reverso y habilitar HTTPS con Let's Encrypt.