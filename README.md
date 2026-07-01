# GeneApp Andina — Gestión de Ganado Andino

Aplicación móvil + API para que pequeños y medianos criadores de alpacas, llamas y ovinos puedan **digitalizar la gestión completa de su hato**: registro genealógico, control reproductivo (empadres/partos), gestión financiera (costos/ventas) y trazabilidad productiva.

## Problema

Los criadores de la región andina enfrentan:
- **Registro manual** en libretas físicas que se pierden o deterioran
- **Sin control genealógico** — no saben qué animales son padres de cuáles, cruces consanguíneos indeseados
- **Sin trazabilidad** — no pueden generar reportes para asociaciones, ferias o certificaciones de raza
- **Sin control reproductivo** — no registran montas (empadres) ni partos de forma sistemática
- **Sin control financiero** — no llevan costos por animal ni ingresos por venta de fibra
- **Sin límites claros** — no saben cuántos animales tienen ni cuándo alcanzaron su capacidad

## Solución

**GeneApp Andina** cubre todo el ciclo del criador:

1. **Registrar animales** con arete, especie, raza, sexo, fecha de nacimiento, foto, padres y estado (Vivo/Vendido/Muerto)
2. **Gestión reproductiva**: registrar empadres (montas) con hembra y macho, diagnosticar resultado, y registrar partos vinculados al empadre
3. **Gestión financiera**: registrar costos por animal (alimentación, sanidad, esquila) y ventas de fibra (kg, precio, total estimado)
4. **Árbol genealógico** de hasta 3 generaciones con consanguinidad calculada
5. **Ranking de fibra** por diámetro, factor de confort y medulación
6. **8 tipos de reportes** en CSV/PDF exportables (Animales, Esquilas, Empadres, Partos, Costos, Ventas Fibra, Ranking Fibra, Consanguinidad)
7. **Sincronización offline** total
8. **Autenticación JWT** con refresh automático

## Cómo funciona

```
           ┌──────────────┐
           │  Flutter App │  ← Android / iOS
           │  (frontend)  │
           └──────┬───────┘
                  │ HTTP (JSON) / JWT Bearer
                  ▼
          ┌───────────────┐
          │ Django REST   │  ← API (Gunicorn)
          │   Backend     │
          └───────┬───────┘
                  │ ORM
                  ▼
          ┌───────────────┐
          │    MySQL      │  ← Base de datos
          └───────────────┘
```

### Flujo típico para un criador

1. **Registra** los animales de su hato (alpacas, llamas y/u ovinos)
2. **Registra empadres** (montas): selecciona hembra y macho, registra fecha y resultado
3. **Registra partos**: vinculados al empadre, número de crías, incidencias
4. **Registra costos**: alimentación, sanidad, esquila, transporte por animal
5. **Registra ventas de fibra**: kg vendidos, precio, comprador
6. **Consulta el árbol genealógico** y coeficiente de consanguinidad
7. **Revisa el ranking de fibra** para identificar mejores reproductores
8. **Exporta reportes** en CSV/PDF (8 tipos disponibles)

## Funcionalidades

### Autenticación
- Registro con teléfono, nombre y contraseña
- Login con JWT (access + refresh automático)
- Persistencia segura de tokens

### Gestión de animales
- CRUD completo con foto, estado (Vivo/Vendido/Muerto), peso al nacer
- Especies: alpaca, llama, ovino — con razas validadas por especie
- Categoría de edad calculada automáticamente por especie
- Asignación de padre y madre con buscador y filtro por especie
- Árbol genealógico de 2-3 generaciones con click para navegar

### Gestión reproductiva
- **Empadres**: registrar monta (hembra + macho), fecha, resultado (pendiente/positivo/negativo), validación misma especie
- **Partos**: registrar parto vinculado a empadre, fecha, número de crías, incidencias
- Fecha probable de parto calculada según especie (345 días camélidos, 150 días ovinos)

### Gestión financiera
- **Costos**: tipo (alimentación, sanidad, esquila, transporte, otro), monto, fecha, descripción
- **Ventas de fibra**: kg vendidos, precio por kg, comprador, total estimado automático

### Producción (esquilas)
- Múltiples esquilas por animal con peso sucio, peso limpio, número de esquila
- Rendimiento calculado automáticamente

### Herramientas de gestión
- **Dashboard** con resumen: total por especie, machos, hembras
- **Consanguinidad**: calcular coeficiente entre dos animales
- **Ranking de fibra**: ranking por diámetro, factor de confort, medulación
- **8 reportes**: Animales, Esquilas, Empadres, Partos, Costos, Ventas Fibra, Ranking Fibra, Consanguinidad — todos en CSV/PDF

### Planes de suscripción

| Plan | Precio | Animales | Generaciones | Sincronización | Reportes |
|------|--------|:--------:|:------------:|:--------------:|:--------:|
| Gratuito | Gratis | 20 | 2 | Local | ❌ |
| Básico | S/ 7.90/mes | 150 | 3 | Nube | ✅ |
| Criador | S/ 19.90/mes | 500 | 3 | Nube | ✅ |

### Pagos (manual Yape/Plin)
- Configuración desde admin: QR estático + celular + montos por plan
- Usuario paga vía Yape/Plin y sube captura de comprobante
- Admin aprueba/rechaza desde Django admin → cambia el plan automáticamente
- Montos configurables: S/ 7.90 Básico, S/ 19.90 Criador

### Notificaciones
- Sistema de notificaciones interno (no push)
- Al aprobar/rechazar un pago, se crea notificación automática
- Campana con badge rojo en el Dashboard con conteo de no leídas
- Pantalla de lista con iconos por tipo (aprobado/rechazado)
- Al tocar una notificación se marca automáticamente como leída

## Tecnologías

### Backend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Python | 3.13 | Lenguaje |
| Django | 4.2 LTS | Framework web |
| Django REST Framework | 3.14 | API REST |
| SimpleJWT | 5.3 | Autenticación JWT |
| MySQL | 8.0+ | Base de datos |
| Gunicorn | 21.2 | Servidor WSGI producción |
| Whitenoise | 6.6 | Servir estáticos en producción |
| drf-spectacular | 0.26 | Documentación OpenAPI/Swagger |
| ReportLab | 4.0 | Generación de PDF |
| Pillow | 11.1 | Manejo de imágenes |
| django-cors-headers | 4.3 | CORS |
| python-decouple | 3.8 | Variables de entorno |

### Frontend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.29+ | Framework mobile |
| Dart | 3.8+ | Lenguaje |
| Riverpod | 2.6 | Estado (StateNotifier, FutureProvider) |
| GoRouter | 14.8 | Navegación con redirect |
| Dio | 5.7 | HTTP + interceptors JWT |
| flutter_secure_storage | 9.2 | Almacenamiento seguro de JWT |
| flutter_localizations | — | Localización a español |
| intl | 0.20 | Formato de fechas |
| path_provider | 2.1 | Rutas de archivos |
| share_plus | 10.1 | Compartir reportes |
| image_picker | 1.2 | Selección de fotos |

### Infraestructura
| Tecnología | Uso |
|------------|-----|
| Docker | Contenedor del backend |
| Docker Compose | Orquestación (API + MySQL) |
| Nginx | Proxy reverso (producción) |
| AWS EC2 | Servidor cloud |

## Estructura del repositorio

```
MVP/
├── back_GenApp/                    # Backend Django
│   ├── geneapp/                    # Configuración Django
│   │   ├── settings.py
│   │   └── urls.py
│   ├── usuarios/                   # App de usuarios + pagos + notificaciones
│   │   ├── models.py               # Usuario, SolicitudPago, ConfiguracionPago, Notificacion
│   │   ├── serializers.py          # Login, Register, Perfil, Pago, Notificaciones
│   │   ├── views.py                # Auth + pagos + webhook (stub)
│   │   ├── urls.py
│   │   ├── admin.py                # UsuarioAdmin simplificado, SolicitudPagoAdmin con acciones
│   │   └── tests.py
│   ├── animales/                   # App principal (CRUD + sync)
│   │   ├── models.py               # Animal, Produccion, Empadre, Parto, Costo, VentaFibra
│   │   ├── serializers.py          # CRUD, Sync, + nuevos módulos
│   │   ├── views.py                # ViewSets para todos los modelos
│   │   ├── utils.py                # calcular_categoria_edad, PERIODO_GESTACION
│   │   ├── urls.py
│   │   ├── tests.py                # Tests de modelos, CRUD, sync, algoritmos
│   │   └── migrations/
│   ├── reportes/                   # App de reportes (separada)
│   │   ├── renderers.py            # CSVRenderer, PDFRenderer
│   │   ├── views.py                # 8 Reporte*View + _build_pdf + BaseReporteView
│   │   ├── urls.py                 # /api/v1/reportes/*
│   │   └── tests.py                # 28 tests para todos los reportes
│   ├── Dockerfile                  # Imagen Docker para producción
│   ├── docker-compose.yml          # Orquestación MySQL + API
│   ├── entrypoint.sh               # Script de inicio del contenedor
│   ├── .env                        # Variables de entorno
│   ├── requirements.txt
│   └── README.md
│
├── front_genapp/                   # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── data/
│   │   │   ├── models/             # Modelos de datos (13 modelos)
│   │   │   ├── services/           # ApiService con JWT
│   │   │   └── repositories/       # AuthRepository, AnimalRepository
│   │   ├── routes/
│   │   │   └── app_router.dart     # GoRouter (25+ rutas)
│   │   └── ui/
│   │       ├── core/
│   │       │   ├── theme.dart      # Tema Material 3
│   │       │   ├── constants.dart
│   │       │   └── widgets/        # AnimalSelector, LoadingButton
│   │       └── features/           # auth, home, dashboard, animales,
│   │                                # gestion, empadres, partos, costos,
│   │                                # ventas_fibra, consanguinidad,
│   │                                # fibra_ranking, perfil, reportes
│   ├── android/
│   │   └── app/src/main/AndroidManifest.xml
│   ├── pubspec.yaml
│   ├── test/
│   └── README.md
│
└── README.md                       # Este archivo
```

## Inicio rápido (desarrollo local)

### Requisitos
- Python 3.13+, MySQL 8.0+
- Flutter SDK 3.29+, Android Studio o Xcode

### 1. Backend

```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py runserver
```

API en `http://localhost:8000`. Swagger en `http://localhost:8000/api/docs/`.

### 2. Frontend

```bash
cd front_genapp
flutter pub get
flutter run
```

La app apunta a `http://10.0.2.2:8000` (Android emulator).

## Despliegue en producción (EC2 con Docker)

```bash
# En el servidor EC2 (Ubuntu)
git clone <repo>
cd back_GenApp

# Crear .env con valores de producción
cat > .env << EOF
SECRET_KEY=<genera una segura>
DEBUG=False
DB_NAME=geneapp
DB_USER=root
DB_PASSWORD=<contraseña>
DB_HOST=db
DB_PORT=3306
ALLOWED_HOSTS=localhost,127.0.0.1,<IP_EC2>
MYSQL_ROOT_PASSWORD=<contraseña>
EOF

# Iniciar
docker compose up -d --build
```

API en `http://<IP_EC2>:8000/api/v1/`. Para HTTPS agregar Nginx + Let's Encrypt.

### Build del APK

```bash
cd front_genapp
flutter build apk --dart-define=API_HOST=<IP_EC2>
```

## Tests

### Backend — 137 tests
```bash
cd back_GenApp
python manage.py test
```
Cubren: modelos, serializers, CRUD (animales, empadres, partos, costos, ventas), validaciones (especie, sexo, fechas), árbol genealógico, sincronización, **8 reportes** (animales, esquilas, empadres, partos, costos, ventas fibra, ranking fibra, consanguinidad), consanguinidad, ranking fibra, pagos, notificaciones.

### Frontend
```bash
cd front_genapp
flutter test
flutter analyze  # 0 issues
```

## Estado del proyecto

| Funcionalidad | Estado |
|---------------|--------|
| Registro y login JWT | ✅ |
| Perfil de usuario | ✅ |
| Planes (Gratuito/Básico/Criador) | ✅ |
| CRUD de animales | ✅ |
| Validación padre/madre (especie, sexo, edad) | ✅ |
| Categoría de edad automática | ✅ |
| Razas validadas por especie (Huacaya/Suri/Kara/Chaqu/6 ovinos) | ✅ |
| Sexo en tarjetas visuales | ✅ |
| Límite de animales por plan | ✅ |
| Árbol genealógico (2-3 gen, clickeable) | ✅ |
| Búsqueda por arete/nombre con debounce | ✅ |
| Filtros (especie, sexo, estado, categoría) | ✅ |
| Scroll infinito paginado | ✅ |
| Dashboard con estadísticas | ✅ |
| CRUD de empadres (montas) | ✅ |
| Validación misma especie en empadre | ✅ |
| Validación empadre duplicado activo | ✅ |
| CRUD de partos | ✅ |
| Parto vinculado a empadre | ✅ |
| Validación parto hembra = empadre hembra | ✅ |
| Fecha probable de parto (345d camélidos / 150d ovinos) | ✅ |
| CRUD de costos | ✅ |
| CRUD de ventas de fibra | ✅ |
| Total estimado en venta (kg × precio) | ✅ |
| Consanguinidad (coeficiente entre dos animales) | ✅ |
| Ranking de fibra (diámetro, confort, medulación) | ✅ |
| Historial de esquilas (Producción) | ✅ |
| Rendimiento calculado en vivo | ✅ |
| Sincronización offline de animales + producciones | ✅ |
| 8 reportes CSV/PDF (animales, esquilas, empadres, partos, costos, ventas fibra, ranking fibra, consanguinidad) | ✅ |
| Foto visible en detalle del animal | ✅ |
| Estado animal (Vivo/Vendido/Muerto + motivo + fecha) | ✅ |
| Peso al nacer | ✅ |
| Calendarizado en español (locale es_PE) | ✅ |
| Diseño consistente (Cards, iconos, AnimalSelector) | ✅ |
| Errores DRF formateados limpios | ✅ |
| Dropdowns con isExpanded (sin overflow) | ✅ |
| Candidatos incluyen no-VIVO al editar (include_uids) | ✅ |
| Docker + docker-compose para producción | ✅ |
| Pagos Yape/Plin (QR + comprobante) | ✅ |
| Admin aprueba/rechaza solicitud | ✅ |
| Notificaciones internas (campana + badge) | ✅ |
| Admin: UsuarioAdmin simplificado | ✅ |
| Admin: ver animales del usuario inline | ✅ |
| Admin: filtro por usuario en animales | ✅ |
| Webhook Yape (stub) | ⚠️ Stub |
| Notificaciones push (FCM) | ❌ Futuro |
| Modo offline completo | ❌ Futuro |

## Licencia

Uso interno — MVP para validación con criadores de la región andina.
