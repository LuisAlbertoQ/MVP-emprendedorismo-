# GeneApp Andina — Gestión de Ganado Andino

Aplicación móvil + API para que pequeños y medianos criadores de alpacas, llamas y ovinos puedan **digitalizar el registro genealógico de su ganado**, reemplazando las libretas de campo y hojas de cálculo.

> **Nuevo:** Estado del animal (Vivo/Vendido/Muerto) con motivo y fecha del cambio — la lista muestra todos los animales por defecto, filtro por estado disponible.
> > 
> > **Nuevo:** Rendimiento de esquila calculado en vivo (vellón limpio / sucio × 100) — ya no se almacena en BD.
> > 
> > **Nuevo:** Número de esquila obligatorio y único por animal, orden ascendente.
> > 
> > **Nuevo:** Peso al nacer (`peso_nacimiento_kg`) registrable desde el formulario.
> > 
> > > **Nuevo:** Validaciones completas — peso limpio ≤ sucio, fecha esquila ≥ nacimiento, peso nacimiento > 0, fromJson con tryParse, max_length en Sync.

## Problema

Los criadores de la región andina (Perú, Bolivia, Ecuador) enfrentan:

- **Registro manual** en libretas físicas que se pierden o deterioran
- **Sin control genealógico** — no saben qué animales son padres de cuáles, lo que lleva a cruces consanguíneos indeseados
- **Sin trazabilidad** — no pueden generar reportes para asociaciones, ferias o certificaciones de raza
- **Sin clasificación etaria** — no distinguen entre crías, juveniles y adultos para manejo del hato
- **Sin límites claros** — no saben cuántos animales tienen ni cuándo alcanzaron su capacidad operativa
- **Sin acceso mobile** — las soluciones existentes son desktop, caras o en inglés

## Solución

**GeneApp Andina** es un sistema mobile-first que permite:

1. **Registrar cada animal** con su arete, especie, sexo, raza, fecha de nacimiento, foto y **categoría de edad calculada automáticamente**
2. **Registrar esquilas** (fecha, peso del vellón, rendimiento) para crear un historial productivo que permite seleccionar a los mejores reproductores
3. **Asignar padres** a cada animal, construyendo un árbol genealógico de hasta 3 generaciones, con validación por edad real (meses, no fecha comparada)
4. **Visualizar el árbol genealógico** en pantalla, con indentación vertical para entender la línea familiar
5. **Buscar y filtrar** animales por especie, sexo, categoría de edad o por nombre/arete
6. **Dashboard** con resumen: total de animales, machos, hembras, desglose por especie
7. **Planes de suscripción** (Gratuito, Básico, Criador) que controlan el límite de animales
8. **Reportes** de animales y esquilas en CSV/PDF exportables y compartibles (planes pagos)
9. **Autenticación JWT** con refresh automático
10. **Sincronización offline** total — animales y producciones

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
6. **Registra esquilas** (fecha, peso del vellón, rendimiento) en el detalle de cada animal
7. Revisa el **historial productivo** para identificar a los mejores reproductores
8. **Filtra y busca** animales en la lista principal
9. Si necesita más capacidad, **cambia de plan** desde el perfil
10. Los planes pagos permiten **exportar y compartir reportes** CSV/PDF de animales y esquilas

## Funcionalidades

### Autenticación
- Registro con teléfono, nombre y contraseña
- Login con JWT (access + refresh automático)
- Persistencia segura de tokens en el dispositivo

### Gestión de animales
- CRUD completo: crear, ver detalle, editar, eliminar (cambio de estado a Vendido)
- Campos: arete, nombre, especie (alpaca/llama/ovino), sexo, raza, fecha de nacimiento, foto, observaciones, **peso al nacer (kg)**
- **Estado**: Vivo / Vendido / Muerto con motivo y fecha del cambio
- Asignación de padre y madre desde un buscador modal con filtro por especie y visualización de categoría de edad
- Validación: el padre debe ser macho, la madre hembra, los padres no pueden ser el mismo animal, padres deben haber nacido antes que el hijo
- **Categoría de edad calculada automáticamente** (Cría / Tui Menor / Tui Mayor / Borrego / Adulto) según especie y fecha de nacimiento
- Validación parental por fecha de nacimiento directa (padre debe haber nacido antes que el hijo)
- **Foto visible en el detalle del animal** (header con imagen de red)

### Producción (historial de esquilas)
- Cada animal puede tener **múltiples registros de esquila** (relación 1 a N)
- Campos: fecha de esquila (DatePicker), **peso vellón sucio (kg)** (obligatorio), **peso vellón limpio (kg)** (opcional), **número de esquila** (único por animal, orden ascendente), observaciones
- **Rendimiento (%) calculado automáticamente** en vivo: `vellón_limpio / vellón_sucio × 100` — no se almacena en BD
- CRUD completo desde el detalle del animal: listar, crear, editar, eliminar
- Lista con FAB flotante para agregar nueva esquila
- Sincronización offline: los cambios de producciones viajan junto con los animales en el endpoint `/sync/`
- Reportes CSV/PDF incluyen columna **"Total Esquilas"** por animal

### Árbol genealógico
- Vista vertical indentada con líneas conectoras
- Color por profundidad: verde (raíz), azul (padres), gris (abuelos)
- Cada nodo muestra **estado** (badge verde/naranja/rojo) junto al nombre
- Cada nivel se indentda 24px para legibilidad en pantallas chicas
- Máximo de generaciones según el plan (2 gratuito, 3 pagos)

### Categoría de edad
- Calculada en tiempo real desde `fecha_nacimiento` — nunca almacenada en BD
- Reglas diferenciadas por especie:
  - **Camélidos** (alpaca/llama): Cría (< 8m), Tui Menor (8-12m), Tui Mayor (12-24m), Adulto (≥ 24m)
  - **Ovinos**: Cría (< 4m), Borrego (4-18m), Adulto (≥ 18m)
- Mostrada en detalle, lista (tag teal) y selector de padres
- La validación parental usa meses de edad en lugar de comparación directa de fechas

### Búsqueda y filtros
- Filtros rápidos por especie (Alpaca/Llama/Ovino) y sexo (Macho/Hembra)
- Buscador textual con debounce de 400ms que busca en arete y nombre
- Selector de padres con filtro por especie y visualización de categoría de edad
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
- **Animales**: descarga CSV o PDF con lista completa de animales, incluye columna **Total Esquilas**
- **Producción**: descarga CSV o PDF con historial de esquilas (arete del animal, fecha, peso del vellón, rendimiento, observaciones)
- PDF con diseño profesional: orientación horizontal (landscape), colores alternados, encabezado con logo/marca, fecha de generación
- Todos los reportes se abren con el **Share sheet** del sistema para guardar en Descargas, enviar por WhatsApp, Drive, etc.
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
│   │   ├── models.py               # Animal + Produccion (esquilas)
│   │   ├── serializers.py          # CRUD, Sync, Reporte, Produccion
│   │   ├── views.py                # AnimalViewSet, ProduccionViewSet, SyncView, ReporteView
│   │   ├── utils.py                # calcular_categoria_edad
│   │   ├── urls.py                 # Rutas
│   │   ├── tests.py                # 77 tests (incl. 16 de produccion)
│   │   └── migrations/
│   │       └── 0003_produccion.py  # Tabla producciones
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
│   │   ├── data/
│   │   │   ├── models/             # AnimalModel, ProduccionModel, UserModel, etc.
│   │   │   ├── services/           # ApiService con JWT
│   │   │   └── repositories/       # AuthRepository, AnimalRepository (CRUD + producciones)
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

### Backend — 61 tests
```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py test
```
Cubren: modelos, serializers, CRUD, validación padres (especie, sexo, fecha nacimiento), límites por plan, árbol genealógico, sincronización (animales + producciones), categoría de edad, producción (CRUD anidado, standalone, sync).

### Frontend
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
| Validación padre/madre (especie, sexo, edad) | ✅ |
| Categoría de edad automática | ✅ |
| Límite de animales por plan | ✅ |
| Árbol genealógico (2-3 gen) | ✅ |
| Búsqueda por arete/nombre | ✅ |
| Filtros (especie, sexo, categoría) | ✅ |
| Scroll infinito paginado | ✅ |
| Dashboard con estadísticas | ✅ |
| Historial de esquilas (Producción) | ✅ |
| CRUD de esquilas (modal con DatePicker) | ✅ |
| Sincronización offline de producciones | ✅ |
| Total esquilas en reportes CSV/PDF | ✅ |
| Foto visible en detalle del animal | ✅ |
| Reporte de animales CSV/PDF (con Total Esquilas) | ✅ |
| Reporte de esquilas CSV/PDF (historial productivo) | ✅ |
| PDF con diseño profesional (landscape, colores) | ✅ |
| Compartir reportes por Share sheet | ✅ |
| Sincronización offline | ✅ |
| Estado animal (Vivo/Vendido/Muerto + motivo + fecha) | ✅ |
| Filtro por estado en lista | ✅ |
| Peso al nacer (kg) | ✅ |
| Peso vellón sucio + limpio en esquilas | ✅ |
| Número de esquila único por animal | ✅ |
| Rendimiento calculado en vivo | ✅ |
| Validaciones backend: peso limpio ≤ sucio, fecha ≥ nacimiento, peso nacimiento > 0 | ✅ |
| Validaciones frontend: fromJson con tryParse, max_length, formularios | ✅ |
| Sync con validación de límite de animales y sexo de padres | ✅ |
| Carga de fotos | ✅ |
| Confirmación de contraseña en registro | ✅ |
| Deslizar para eliminar en lista | ✅ |
| Pull-to-refresh en perfil | ✅ |
| Webhook Yape (stub) | ⚠️ Stub |
| Notificaciones push | ❌ Futuro |
| Galería de fotos | ❌ Futuro |
| Modo offline completo | ❌ Futuro |

## Licencia

Uso interno — MVP para validación con criadores de la región andina.
