# GeneApp Andina — Gestión de Ganado Andino

Aplicación móvil + API para que pequeños y medianos criadores de alpacas, llamas y ovinos puedan **digitalizar el registro genealógico de su ganado**, reemplazando las libretas de campo y hojas de cálculo.

## Problema

Los criadores de la región andina (Perú, Bolivia, Ecuador) enfrentan:

- **Registro manual** en libretas físicas que se pierden o deterioran
- **Sin control genealógico** — no saben qué animales son padres de cuáles, lo que lleva a cruces consanguíneos indeseados
- **Sin trazabilidad** — no pueden generar reportes para asociaciones, ferias o certificaciones de raza
- **Sin límites claros** — no saben cuántos animales tienen ni cuándo alcanzaron su capacidad operativa
- **Sin acceso mobile** — las soluciones existentes son desktop, caras o en inglés

## Solución

**GeneApp Andina** es un sistema mobile-first que permite:

1. **Registrar cada animal** con su arete, especie, sexo, raza, fecha de nacimiento y foto
2. **Asignar padres** a cada animal, construyendo un árbol genealógico de hasta 3 generaciones
3. **Visualizar el árbol genealógico** en pantalla, con indentación vertical para entender la línea familiar
4. **Buscar y filtrar** animales por especie, sexo o por nombre/arete
5. **Dashboard** con resumen: total de animales, machos, hembras, desglose por especie
6. **Planes de suscripción** (Gratuito, Básico, Criador) que controlan el límite de animales
7. **Reportes** en CSV y PDF exportables (planes pagos)
8. **Autenticación JWT** con refresh automático
9. **Sincronización offline** (endpoint preparado)

## Cómo funciona

```
           ┌──────────────┐
           │  Flutter App │  ← Android / iOS
           │  (frontend)  │
           └──────┬───────┘
                  │ HTTP (JSON)
                  │ JWT Bearer Token
                  ▼
          ┌───────────────┐
          │ Django REST   │  ← API
          │   Backend     │
          └───────┬───────┘
                  │ ORM
                  ▼
          ┌───────────────┐
          │    MySQL      │  ← Base de datos
          └───────────────┘
```

### Flujo típico

1. El usuario se **registra** con su teléfono y nombre
2. Inicia sesión y recibe un **JWT** (access + refresh)
3. Ve el **Dashboard** con el resumen de su ganado y su plan actual
4. **Registra animales** uno por uno, y opcionalmente asigna padre y madre
5. Consulta el **árbol genealógico** de cada animal para ver su línea familiar
6. **Filtra y busca** animales en la lista principal
7. Si necesita más capacidad, **cambia de plan** desde el perfil
8. Los planes pagos permiten **exportar reportes** CSV/PDF

## Funcionalidades

### Autenticación
- Registro con teléfono, nombre y contraseña
- Login con JWT (access + refresh automático)
- Persistencia segura de tokens en el dispositivo

### Gestión de animales
- CRUD completo: crear, ver detalle, editar, eliminar (borrado lógico)
- Campos: arete, nombre, especie (alpaca/llama/ovino), sexo, raza, fecha de nacimiento, foto, observaciones
- Asignación de padre y madre desde un buscador modal
- Validación: el padre debe ser macho, la madre hembra, los padres no pueden ser el mismo animal

### Árbol genealógico
- Vista vertical indentada con líneas conectoras
- Color por profundidad: verde (raíz), azul (padres), gris (abuelos)
- Cada nivel se indentda 24px para legibilidad en pantallas chicas
- Máximo de generaciones según el plan (2 gratuito, 3 pagos)

### Búsqueda y filtros
- Filtros rápidos por especie (Alpaca/Llama/Ovino) y sexo (Macho/Hembra)
- Buscador textual con debounce de 400ms que busca en arete y nombre
- Scroll infinito con paginación (20 items por página)

### Dashboard
- Banner del plan con barra de progreso (animales usados / límite)
- Estadísticas: total, machos, hembras
- Desglose por especie: alpaca, llama, ovino
- Acciones rápidas: nuevo animal, ver todos, reportes

### Planes de suscripción

| Plan | Precio | Animales | Generaciones | Sincronización | Reportes |
|------|--------|:--------:|:------------:|:--------------:|:--------:|
| Gratuito | Gratis | 20 | 2 | Local | ❌ |
| Básico | S/ 7.90/mes | 150 | 3 | Nube | ❌ |
| Criador | S/ 19.90/mes | 500 | 3 | Nube | ✅ CSV/PDF |

### Reportes
- Descarga de lista de animales en CSV (tabla) o PDF
- Solo disponible para planes Básico y Criador

## Tecnologías

### Backend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Python | 3.12+ | Lenguaje |
| Django | 4.2 LTS | Framework web |
| Django REST Framework | 3.14 | API REST |
| SimpleJWT | 5.3 | Autenticación JWT |
| MySQL | 8.0+ | Base de datos |
| drf-spectacular | 0.26 | Documentación OpenAPI/Swagger |
| ReportLab | 4.0 | Generación de PDF |
| Pillow | 10.0 | Manejo de imágenes |
| django-cors-headers | 4.3 | CORS para mobile |
| python-decouple | 3.8 | Variables de entorno |

### Frontend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.29+ | Framework mobile |
| Dart | 3.8+ | Lenguaje |
| Riverpod | 2.6 | Estado (StateNotifier, FutureProvider) |
| GoRouter | 14.8 | Navegación con redirect |
| Dio | 5.7 | HTTP + interceptors |
| flutter_secure_storage | 9.2 | Almacenamiento seguro de JWT |
| intl | 0.20 | Formato de fechas |
| path_provider | 2.1 | Rutas de archivos |

## Estructura del repositorio

```
MVP/
├── back_GenApp/                    # Backend Django
│   ├── geneapp/                    # Configuración Django
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── ...
│   ├── usuarios/                   # App de usuarios
│   │   ├── models.py               # AbstractUser extendido
│   │   ├── serializers.py          # Register, Login, Perfil
│   │   ├── views.py                # Auth endpoints
│   │   ├── urls.py
│   │   └── tests.py                # Tests de usuarios
│   ├── animales/                   # App de animales
│   │   ├── models.py               # Animal con padres
│   │   ├── serializers.py          # CRUD, Sync, Reporte
│   │   ├── views.py                # AnimalViewSet, SyncView, ReporteView
│   │   ├── urls.py                 # Rutas
│   │   └── tests.py                # Tests de animales
│   ├── env/                        # Entorno virtual Python
│   ├── media/                      # Archivos subidos
│   ├── requirements.txt
│   └── README.md                   # Documentación del backend
│
├── front_genapp/                   # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart               # Entry point
│   │   ├── app.dart                # MaterialApp.router
│   │   ├── data/
│   │   │   ├── models/             # AnimalModel, UserModel, etc.
│   │   │   ├── services/           # ApiService con JWT
│   │   │   └── repositories/       # AuthRepository, AnimalRepository
│   │   ├── routes/
│   │   │   └── app_router.dart     # GoRouter
│   │   └── ui/
│   │       ├── core/               # Tema, constantes, widgets
│   │       └── features/           # auth, home, dashboard, animales, perfil, reportes
│   ├── test/                       # 27 tests
│   └── README.md                   # Documentación del frontend
│
└── README.md                       # Este archivo
```

## Inicio rápido

### Requisitos
- Python 3.12+, MySQL 8.0+ (Laragon)
- Flutter SDK 3.29+, Android Studio o Xcode

### 1. Backend

```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py runserver
```

API en `http://localhost:8000`. Documentación Swagger en `http://localhost:8000/api/docs/`.

### 2. Frontend

```bash
cd front_genapp
flutter pub get
flutter run
```

La app apunta a `http://10.0.2.2:8000` (Android emulator). Para iOS físico, cambiar a `http://<IP-local>:8000` en `lib/data/services/api_service.dart`.

## Tests

### Backend — 50 tests
```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py test
```
Cubren: modelos, serializers, CRUD, validación padres, límites por plan, árbol genealógico, sincronización.

### Frontend — 27 tests
```bash
cd front_genapp
flutter test
flutter analyze  # 0 issues
```
Cubren: modelos (fromJson/toJson), estados (copyWith), widgets (LoadingButton), integración.

## Estado del proyecto

Funcionalidades implementadas:

| Funcionalidad | Estado |
|---------------|--------|
| Registro y login JWT | ✅ |
| Perfil de usuario | ✅ |
| Planes (Gratuito/Básico/Criador) | ✅ |
| CRUD de animales | ✅ |
| Validación padre/madre | ✅ |
| Límite de animales por plan | ✅ |
| Árbol genealógico (2-3 gen) | ✅ |
| Búsqueda por arete/nombre | ✅ |
| Filtros (especie, sexo) | ✅ |
| Scroll infinito paginado | ✅ |
| Dashboard con estadísticas | ✅ |
| Reportes CSV/PDF | ✅ |
| Sincronización offline | ✅ |
| Soft delete | ✅ |
| Webhook Yape (stub) | ⚠️ Stub |
| Notificaciones push | ❌ Futuro |
| Galería de fotos | ❌ Futuro |
| Modo offline completo | ❌ Futuro |

## Licencia

Uso interno — MVP para validación con criadores de la región andina.
