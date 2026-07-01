# GeneApp Andina — Backend

API REST para gestión de criadores de alpacas, llamas y ovinos. Cubre registro genealógico, control reproductivo (empadres/partos), gestión financiera (costos/ventas de fibra), producción (esquilas) y reportes.

## Tecnologías

- **Python 3.13** / **Django 4.2 LTS**
- **Django REST Framework 3.14** — API REST
- **MySQL 8.0+** — Base de datos
- **SimpleJWT** — Autenticación por tokens
- **Gunicorn** — Servidor WSGI para producción
- **Whitenoise** — Servir archivos estáticos
- **drf-spectacular** — Documentación OpenAPI
- **ReportLab** — Generación de PDF
- **Pillow** — Manejo de imágenes

## Requisitos (desarrollo local)

- Python 3.13+
- MySQL 8.0+
- Entorno virtual en `env/`

## Instalación local

```bash
cd back_GenApp
.\env\Scripts\python.exe -m pip install -r requirements.txt
```

Crear base de datos:
```sql
CREATE DATABASE geneapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Editar `.env`:
```env
SECRET_KEY=tu-clave-secreta
DEBUG=True
DB_NAME=geneapp
DB_USER=root
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=3306
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:8000,http://127.0.0.1:8000
```

Migrar e iniciar:
```bash
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py runserver
```

Servidor en `http://localhost:8000`. Swagger en `http://localhost:8000/api/docs/`.

## Despliegue con Docker (EC2 / producción)

```bash
# Clonar y entrar
cd back_GenApp

# Crear .env
cat > .env << EOF
SECRET_KEY=<python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())">
DEBUG=False
DB_NAME=geneapp
DB_USER=root
DB_PASSWORD=<contraseña_segura>
DB_HOST=db
DB_PORT=3306
ALLOWED_HOSTS=localhost,127.0.0.1,<IP_PUBLICA_EC2>
MYSQL_ROOT_PASSWORD=<contraseña_segura>
EOF

# Iniciar
docker compose up -d --build

# Ver logs
docker compose logs -f

# Verificar
curl http://localhost:8000/api/v1/
```

La API queda en `http://<IP_EC2>:8000/api/v1/`. Para HTTPS, agregar Nginx como proxy reverso + Let's Encrypt.

### Notas de producción

- **Media files**: `urls.py` usa `django.views.static.serve` (no `static()`) para servir archivos subidos (`/media/`) incluso con `DEBUG=False`. Sin Nginx, Gunicorn sirve media directamente — suficiente para MVP.

### Archivos de despliegue

| Archivo | Propósito |
|---------|-----------|
| `Dockerfile` | Imagen Python 3.13-slim con dependencias |
| `docker-compose.yml` | MySQL 8.0 + backend con healthcheck |
| `entrypoint.sh` | Espera MySQL, corre migraciones, collectstatic, arranca Gunicorn |
| `.dockerignore` | Excluye env, media, __pycache__ |

## Endpoints de la API

### Autenticación (`/api/v1/auth/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `register/` | Registro (teléfono, nombre, password) |
| POST | `login/` | Login → access + refresh tokens |
| POST | `refresh/` | Refrescar token |
| GET | `perfil/` | Perfil + plan + animales + solicitud_pendiente |
| POST | `cambiar-plan/` | Cambiar plan (solo gratuito, los demás vía pago) |
| GET | `datos-pago/` | QR + celular + montos (ConfiguracionPago) |
| POST | `solicitar-pago/` | Subir comprobante + plan → crea SolicitudPago |
| GET | `mis-solicitudes/` | Historial de solicitudes de pago |
| GET | `notificaciones/` | Lista de notificaciones del usuario |
| PATCH | `notificaciones/` | Marcar como leída (una o todas) |
| GET | `notificaciones/no-leidas/` | Conteo de no leídas |
| POST | `webhook-yape/` | Webhook pagos Yape (stub) |

### Animales (`/api/v1/animales/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Listar (paginado, ?especie=&sexo=&estado=&search=) |
| POST | `/` | Crear animal (con límite por plan) |
| GET | `/{uid}/` | Detalle con categoría_edad |
| PATCH | `/{uid}/` | Actualizar parcial (incl. foto multipart) |
| DELETE | `/{uid}/` | Soft delete (estado=VENDIDO) |
| GET | `/{uid}/arbol/` | Árbol genealógico (2-3 gen) |
| GET | `/{uid}/producciones/` | Listar esquilas del animal |
| POST | `/{uid}/producciones/` | Crear esquila |
| GET | `/{uid}/consanguinidad/{otro_uid}/` | Coeficiente de consanguinidad |
| GET | `/candidatos/` | Lista para selectores (?especie=&include_uids=) |
| GET | `/razas-por-especie/` | Mapa de especies → razas válidas |
| GET | `/resumen/` | Stats (total, machos, hembras, especies) |

### Empadres (`/api/v1/empadres/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Listar (?hembra_uid=&resultado=) |
| POST | `/` | Crear empadre |
| GET | `/{uid}/` | Detalle con hembra/macho display fields |
| PATCH | `/{uid}/` | Actualizar |
| DELETE | `/{uid}/` | Eliminar |

### Partos (`/api/v1/partos/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Listar |
| POST | `/` | Crear parto (opcional: vinculado a empadre) |
| GET | `/{uid}/` | Detalle con hembra display fields |
| PATCH | `/{uid}/` | Actualizar |
| DELETE | `/{uid}/` | Eliminar |

### Costos (`/api/v1/costos/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Listar |
| POST | `/` | Crear costo |
| GET | `/{uid}/` | Detalle con animal display fields |
| PATCH | `/{uid}/` | Actualizar |
| DELETE | `/{uid}/` | Eliminar |

### Ventas de Fibra (`/api/v1/ventas-fibra/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Listar (incluye ingreso_total) |
| POST | `/` | Crear venta |
| GET | `/{uid}/` | Detalle con animal display fields |
| PATCH | `/{uid}/` | Actualizar |
| DELETE | `/{uid}/` | Eliminar |

### Producciones (`/api/v1/producciones/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/{uid}/` | Detalle esquila |
| PATCH | `/{uid}/` | Actualizar |
| DELETE | `/{uid}/` | Eliminar físico |

### Sincronización (`/api/v1/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `sync/` | Sync offline (animales + producciones) |

### Reportes (`/api/v1/reportes/`)

| Método | Endpoint | Descripción | Plan |
|--------|----------|-------------|------|
| GET | `animales/?format=csv\|pdf` | Animales (raza, categoría, peso nac., costo total) | Básico+ |
| GET | `esquilas/?format=csv\|pdf` | Esquilas (diámetro, confort, medulación) | Básico+ |
| GET | `empadres/?format=csv\|pdf` | Empadres (hembra, macho, fecha, resultado) | Básico+ |
| GET | `partos/?format=csv\|pdf` | Partos (hembra, fecha, crías, incidencias) | Básico+ |
| GET | `costos/?format=csv\|pdf` | Costos (animal, tipo, monto, fecha) | Básico+ |
| GET | `ventas-fibra/?format=csv\|pdf` | Ventas Fibra (kg, precio, comprador, ingreso total) | Básico+ |
| GET | `ranking-fibra/?format=csv\|pdf` | Ranking por diámetro, confort, medulación | Básico+ |
| GET | `consanguinidad/?format=csv\|pdf` | Consanguinidad (animal, coeficiente, padres) | Básico+ |

### Ranking / Fibra (JSON, `/api/v1/`)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `ranking-fibra/` | Ranking JSON por diámetro, confort, medulación |

### Documentación

| Endpoint | Descripción |
|----------|-------------|
| `/api/schema/` | Schema OpenAPI |
| `/api/docs/` | Swagger UI |

## Modelos de Datos

### Usuario
- `telefono` — Identificador único (login)
- `plan` — Gratuito / Básico / Criador
- `limite_animales` / `animales_count` / `generations_allowed` — Propiedades calculadas
- `solicitud_pendiente` — Campo virtual en PerfilSerializer (pendiente de pago)

### SolicitudPago
- `uid` (UUID), `usuario` (FK), `plan_solicitado`, `monto`
- `comprobante` (ImageField), `numero_operacion` (opcional), `estado` (pendiente/aprobado/rechazado)

### ConfiguracionPago (singleton)
- `celular`, `qr` (ImageField), `monto_basico`, `monto_criador`

### Notificacion
- `usuario` (FK), `mensaje`, `tipo` (solicitud_aprobada/rechazada/sistema), `leido`, `created_at`

### Animal
- `uid` (UUID), `arete` (único por usuario), `nombre`, `especie` (alpaca/llama/ovino), `sexo`, `raza`, `fecha_nacimiento`
- `padre` / `madre` — Self-referential FK
- `foto` (ImageField en serializer — lectura escritura, retorna URL absoluta con request context), `estado` (VIVO/VENDIDO/MUERTO), `fecha_estado`, `motivo_estado`
- `peso_nacimiento_kg`, `sync_status`

### Produccion (esquilas)
- `uid` (UUID), `animal` (FK), `fecha_esquila`, `peso_vellon_sucio_kg`, `peso_vellon_limpio_kg`
- `numero_esquila` (único por animal), `rendimiento_pct` (calculado en vivo), `observaciones`
- `sync_status`

### Empadre
- `uid` (UUID), `hembra` (FK Animal), `macho` (FK Animal), `usuario` (FK)
- `fecha_empadre`, `fecha_dx_gestacion`, `resultado` (pendiente/positivo/negativo/no_revisado), `observaciones`
- `fecha_probable_parto` (propiedad calculada según especie)

### Parto
- `uid` (UUID), `hembra` (FK Animal), `empadre` (FK nullable), `usuario` (FK)
- `fecha_parto`, `fecha_probable`, `numero_crias`, `incidencias`, `observaciones`

### Costo
- `uid` (UUID), `animal` (FK), `usuario` (FK)
- `tipo` (alimentacion/sanidad/esquila/transporte/otro), `monto`, `fecha`, `descripcion`

### VentaFibra
- `uid` (UUID), `animal` (FK), `produccion` (FK nullable), `usuario` (FK)
- `kg_vendidos`, `precio_kg`, `comprador`, `fecha_venta`
- `ingreso_total` (propiedad calculada: kg × precio)

### Categoría de Edad (calculada, no almacenada)

| Especie | Cría | Juvenil 1 | Juvenil 2 | Adulto |
|---------|------|-----------|-----------|--------|
| Alpaca/Llama | < 8m | Tui Menor (8-12m) | Tui Mayor (12-24m) | ≥ 24m |
| Ovino | < 4m | Borrego (4-18m) | — | ≥ 18m |

### Gestación por especie

| Especie | Gestación |
|---------|-----------|
| Alpaca | 345 días |
| Llama | 345 días |
| Ovino | 150 días |

### Razas válidas por especie

| Especie | Razas |
|---------|-------|
| Alpaca | Huacaya, Suri |
| Llama | Kara, Ch'aku |
| Ovino | Criollo, Corriedale, Junín, Hampshire Down, Black Belly, Assaf |

## Validaciones importantes

| Validación | Dónde | Comportamiento |
|------------|-------|----------------|
| Padre/madre misma especie | `AnimalSerializer.validate()` | Rechaza si especie diferente |
| Padre debe ser macho | `AnimalSerializer.validate_padre()` | Error si no es macho |
| Madre debe ser hembra | `AnimalSerializer.validate_madre()` | Error si no es hembra |
| Padre debe haber nacido antes | `AnimalSerializer.validate()` | Error si padre es menor que hijo |
| Empadre misma especie | `EmpadreSerializer.validate()` | Hembra y macho deben ser misma especie |
| Empadre sin duplicado activo | `EmpadreSerializer.validate()` | No permite 2 empadres pendientes/positivos para misma hembra |
| Parto hembra = empadre hembra | `PartoSerializer.validate()` | La hembra del parto debe coincidir con la del empadre |
| Raza por especie | `AnimalSerializer.validate()` | Rechaza raza no válida para la especie |
| Sync: raza por especie | `SyncChangeSerializer.validate()` | Validado también en sincronización |
| Peso limpio ≤ sucio | `ProduccionSerializer.validate()` | No permite peso limpio mayor al sucio |
| Fecha esquila ≥ nacimiento | `ProduccionSerializer.validate()` | No permite esquilar antes de nacer |
| Número de esquila único | Model `unique_together` | No permite duplicar número por animal |
| Fecha no futura | En todos los serializers con fecha | No permite fechas posteriores a hoy |

## Admin Django

### Usuarios (`/admin/usuarios/usuario/`)
- Campos visibles: teléfono, nombre, plan, activo, fechas (sin grupos/permisos)
- Inline con todos los animales del usuario (solo lectura)

### Solicitudes de Pago (`/admin/usuarios/solicitudpago/`)
- Lista con: usuario, plan, monto, estado, preview del comprobante
- Acción: **Aprobar** → cambia el plan del usuario + crea notificación
- Acción: **Rechazar** → marca como rechazado + crea notificación
- Solo lectura (no se puede crear/editar manualmente)

### Configuración de Pago (`/admin/usuarios/configuracionpago/`)
- Singleton: solo una fila
- Campos: celular, QR, monto_básico (S/ 7.90), monto_criador (S/ 19.90)

## Tests

```bash
python manage.py test
```

**137 tests** que cubren:
- 16 de usuarios (registro, login, refresh, perfil, cambio plan)
- 20+ de animales (CRUD, filtros, búsqueda, árbol, candidatos, resumen, foto, consanguinidad)
- 10+ de empadres (CRUD, validaciones misma especie, empadre activo duplicado)
- 8+ de partos (CRUD, validación hembra = empadre, fecha futura)
- 6+ de costos (CRUD)
- 6+ de ventas fibra (CRUD, ingreso total)
- 10+ de producción (CRUD anidado, standalone, sync, validaciones)
- 10+ de sincronización (animales, producciones, estado, validaciones)
- 28 de reportes (8 endpoints × CSV/PDF/denied + columnas nuevas + ordenamiento)

## Estructura del proyecto

```
back_GenApp/
├── geneapp/                # Configuración Django
│   ├── settings.py
│   └── urls.py
├── usuarios/               # App de usuarios
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── tests.py
├── animales/               # App principal (CRUD + sync)
│   ├── models.py           # 6 modelos: Animal, Produccion, Empadre, Parto, Costo, VentaFibra
│   ├── serializers.py      # ~670 líneas, 15+ serializers
│   ├── views.py            # ViewSets + SyncView + RankingFibraView
│   ├── utils.py            # calcular_categoria_edad, PERIODO_GESTACION
│   ├── urls.py
│   ├── tests.py            # 109 tests (modelos, CRUD, sync, algoritmos)
│   └── migrations/
├── reportes/               # App de reportes (separada)
│   ├── renderers.py        # CSVRenderer, PDFRenderer
│   ├── views.py            # 8 Reporte*View + _build_pdf + BaseReporteView
│   ├── urls.py             # /api/v1/reportes/*
│   ├── tests.py            # 28 tests para todos los reportes
│   └── migrations/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .dockerignore
├── mysql-init/
│   └── 01-charset.sql
├── requirements.txt
├── .env
└── README.md
```

## Comandos útiles

```bash
# Desarrollo local
.\env\Scripts\python.exe manage.py runserver
.\env\Scripts\python.exe manage.py test
.\env\Scripts\python.exe manage.py makemigrations
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py createsuperuser

# Producción Docker
docker compose up -d --build
docker compose logs -f
docker compose down
```

## Producción (Nginx)

Para HTTPS en producción, configurar Nginx como proxy reverso:

```nginx
server {
    listen 80;
    server_name tudominio.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name tudominio.com;

    ssl_certificate /etc/letsencrypt/live/tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tudominio.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /app/staticfiles/;
    }

    location /media/ {
        alias /app/media/;
    }
}
```
