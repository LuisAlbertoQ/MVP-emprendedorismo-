# GeneApp Andina — Frontend (Flutter)

Aplicación móvil para gestión de criadores de alpacas, llamas y ovinos. Cubre registro genealógico, gestón reproductiva (empadres/partos), gestión financiera (costos/ventas de fibra), árbol genealógico, consanguinidad, ranking de fibra y reportes.

## Tecnologías

- **Flutter 3.29+** con Dart 3.8+
- **Riverpod** — manejo de estado (StateNotifier, FutureProvider)
- **GoRouter** — navegación con redirect por auth, ShellRoute para bottom nav (25+ rutas)
- **Dio** — HTTP con interceptor JWT + refresh automático
- **flutter_secure_storage** — tokens JWT almacenados seguros
- **flutter_localizations** — localización a español (es_PE)
- **intl** — formato de fechas (dd/MM/yyyy)
- **path_provider** — almacenamiento temporal para reportes
- **share_plus** — compartir reportes (PDF/CSV) por WhatsApp, Drive, etc.
- **image_picker** — selección de fotos desde galería

## Requisitos

- Flutter SDK ^3.8.1
- Backend corriendo (local: `http://10.0.2.2:8000`, producción: IP del servidor)

Para cambiar la URL del backend: usar `--dart-define=API_HOST=<IP>` al compilar.

## Instalación (desarrollo)

```bash
cd front_genapp
flutter pub get
flutter run
```

Para construir APK de producción:
```bash
flutter build apk --dart-define=API_HOST=<IP_EC2>
```

## Estructura del proyecto

```
lib/
├── main.dart                          # Entry point + ProviderScope
├── app.dart                           # MaterialApp.router con tema + locale español
├── data/
│   ├── models/
│   │   ├── animal_model.dart          # AnimalModel, CandidatoModel, ArbolNode
│   │   ├── empadre_model.dart         # EmpadreModel, EmpadreListModel
│   │   ├── parto_model.dart           # PartoModel
│   │   ├── costo_model.dart           # CostoModel, CostoListModel
│   │   ├── venta_fibra_model.dart     # VentaFibraModel, VentaFibraListModel
│   │   ├── produccion_model.dart      # ProduccionModel
│   │   ├── user_model.dart            # UserModel + SolicitudPendiente
│   │   └── notificacion_model.dart    # NotificacionModel
│   ├── services/
│   │   └── api_service.dart           # Dio + interceptors JWT + extractError()
│   └── repositories/
│       ├── auth_repository.dart       # Auth (login, register, perfil, logout)
│       └── animal_repository.dart     # Animales + Producciones CRUD
├── routes/
│   └── app_router.dart                # GoRouter con 25+ rutas
└── ui/
    ├── core/
    │   ├── theme.dart                 # Tema Material 3 verde (AppTheme)
    │   ├── constants.dart             # AppStrings, AppRoutes
    │   └── widgets/
    │       ├── animal_selector.dart   # Selector de animales con búsqueda + filtro especie
    │       └── loading_button.dart    # Botón con estado de carga
    └── features/
        ├── auth/views/
        │   ├── login_screen.dart
        │   └── register_screen.dart
        ├── home/views/
        │   └── home_shell.dart        # Bottom navigation (4 tabs)
        ├── dashboard/views/
        │   └── dashboard_screen.dart   # Stats, especies, acciones rápidas
        ├── animales/views/
        │   ├── animal_list_screen.dart  # Lista + filtros + scroll infinito
        │   ├── animal_detail_screen.dart# Detalle con header, padres, esquilas
        │   ├── animal_form_screen.dart  # Crear/editar con sexo cards + raza por especie
        │   ├── arbol_screen.dart        # Árbol genealógico clickeable
        │   └── produccion_form_sheet.dart# Modal esquila
        ├── gestion/views/
        │   ├── gestion_screen.dart      # Hub de gestión
        │   ├── reproductivo_screen.dart # Acceso a empadres/partos
        │   └── financiero_screen.dart   # Acceso a costos/ventas
        ├── empadres/views/
        │   ├── empadre_list_screen.dart
        │   └── empadre_form_screen.dart # Con AnimalSelector hembra/macho
        ├── partos/views/
        │   ├── parto_list_screen.dart
        │   └── parto_form_screen.dart   # Con selector de empadre
        ├── costos/views/
        │   ├── costo_list_screen.dart
        │   └── costo_form_screen.dart
        ├── ventas_fibra/views/
        │   ├── venta_fibra_list_screen.dart
        │   └── venta_fibra_form_screen.dart # Total estimado automático
        ├── consanguinidad/views/
        │   └── consanguinidad_screen.dart
        ├── fibra_ranking/views/
        │   └── fibra_ranking_screen.dart
        ├── perfil/providers/
│   │   └── notificacion_provider.dart
│   ├── perfil/views/
│   │   ├── perfil_screen.dart
│   │   ├── pago_screen.dart
│   │   └── notificaciones_screen.dart
        └── reportes/views/
            └── reportes_screen.dart
```

## Pantallas (25+ rutas)

### Auth
- **Login/Register**: formularios con teléfono y contraseña

### Dashboard (Inicio)
- Banner del plan con barra de progreso
- Estadísticas: total, machos, hembras, desglose por especie
- Acciones rápidas

### Animales
- **Lista**: scroll infinito, filtros por especie/sexo/estado, buscador con debounce, categoría de edad en cards, deslizar para eliminar
- **Detalle**: header con gradiente + foto, info completa, padres tappables, historial de esquilas, botón árbol genealógico
- **Formulario**: sexo en tarjetas visuales, raza filtrada por especie, selector de padres con búsqueda, foto (con preview de foto existente al editar), estado, peso al nacer
- **Árbol genealógico**: vista vertical indentada, nodos clickeables para navegar al detalle

### Gestión > Reproductivo
- **Empadres**: lista + formulario con AnimalSelector (hembra/macho), dropdown de resultado
- **Partos**: lista + formulario con selector de empadre vinculado, número de crías, incidencias

### Gestión > Financiero
- **Costos**: lista + formulario con tipo de costo, monto, fecha
- **Ventas de Fibra**: lista + formulario con kg, precio/kg, total estimado automático, comprador

### Consanguinidad
- Seleccionar dos animales y calcular coeficiente de consanguinidad

### Ranking de Fibra
- Ranking por diámetro, factor de confort, medulación

### Perfil
- Header con gradiente, plan con barra de progreso, cambiar plan, cerrar sesión
- Badge "Solicitud pendiente" mientras el admin no apruebe/rechace
- Plans de pago (Básico/Criador) redirigen a pantalla de pago

### Pagos
- QR + celular + monto según plan (desde ConfiguracionPago)
- Subir captura del comprobante desde la galería
- Campo opcional: número de operación
- Confirmación: "Solicitud enviada, el administrador validará tu pago"
- Planes bloqueados si hay una solicitud pendiente
- La URL del QR se construye sin `/api/v1` en el path (usa `mediaUrl` = `baseUrl` sin `/api/v1`)

### Notificaciones
- Campana 🔔 con badge rojo en el Dashboard
- Al tocar: lista de notificaciones con icono por tipo
- Tap para marcar como leída
- Botón "Leer todas"
- Pull-to-refresh para actualizar

### Reportes
- 8 tipos de reportes en CSV/PDF: Animales, Esquilas, Empadres, Partos, Costos, Ventas Fibra, Ranking Fibra, Consanguinidad
- Compartir por WhatsApp/Drive desde la app

## Diseño y UX

- **Tema Material 3** verde personalizado (AppTheme)
- **Cards** con padding consistente para agrupar secciones
- **AnimalSelector**: widget reutilizable con modal de búsqueda + filtro por especie
- **Sexo en tarjetas**: toggle visual entre Macho/Hembra en vez de dropdown
- **Iconos** en todos los campos de formulario
- **Drag handle** en bottom sheets
- **DatePicker** localizado a español
- **isExpanded** en todos los DropdownButtonFormField para evitar overflow

## Manejo de errores

- `ApiService.extractError()`: limpia los mapas de error de DRF y muestra mensajes legibles
- Todos los catch blocks usan `extractError()` + `ScaffoldMessenger`
- Sin catch silenciosos

## Tests

```bash
flutter test
```

Cubren: modelos (fromJson/toJson), estados (copyWith), widgets.

## Análisis estático

```bash
flutter analyze
```
0 issues.

## Configuración de plataformas

### Android
- `AndroidManifest.xml`: permiso INTERNET, `usesCleartextTraffic=true` para HTTP en producción
- minSdk: flutter.minSdkVersion

### iOS
- `Info.plist`: `NSAllowsArbitraryLoads = true` para HTTP

### Build para producción

```bash
# Con IP del servidor backend
flutter build apk --dart-define=API_HOST=3.18.194.167
# El APK queda en: build/app/outputs/flutter-apk/app-release.apk
```
