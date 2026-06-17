# GeneApp Andina — Frontend (Flutter)

Aplicación móvil para gestión de criadores de alpacas, llamas y ovinos. Incluye historial productivo de esquilas, árbol genealógico, categoría de edad automática y sincronización offline.

## Tecnologías

- **Flutter 3.29+** con Dart 3.8+
- **Riverpod** — manejo de estado (StateNotifier, FutureProvider)
- **GoRouter** — navegación con redirect por auth, ShellRoute para bottom nav
- **Dio** — HTTP con interceptor JWT + refresh automático
- **flutter_secure_storage** — tokens JWT almacenados seguros
- **intl** — formato de fechas
- **path_provider** — descarga de reportes
- **image_picker** — selección de fotos desde galería

## Requisitos

- Flutter SDK ^3.8.1
- Backend corriendo en `http://10.0.2.2:8000` (Android emulator) o `http://localhost:8000` (iOS/web)

Para cambiar la URL del backend: editar `lib/data/services/api_service.dart` línea 8.

## Instalación

```bash
cd front_genapp
flutter pub get
flutter run
```

Para Android:
```bash
flutter run
```

Para iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

## Estructura del proyecto

```
lib/
├── main.dart                    # Entry point + ProviderScope
├── app.dart                     # MaterialApp.router con tema
├── data/
│   ├── models/
│   │   ├── animal_model.dart    # AnimalModel, AnimalListModel, CandidatoModel, ArbolNode
│   │   ├── produccion_model.dart # ProduccionModel, ProduccionSyncChange
│   │   └── user_model.dart      # UserModel
│   ├── services/
│   │   └── api_service.dart     # Dio + interceptors JWT + refresh
│   └── repositories/
│       ├── auth_repository.dart # Auth (login, register, perfil, logout)
│       └── animal_repository.dart # Animales + Producciones CRUD
├── routes/
│   └── app_router.dart          # GoRouter con redirect por auth + ShellRoute
├── ui/
│   ├── core/
│   │   ├── constants.dart       # AppStrings, AppRoutes
│   │   ├── theme.dart           # Tema Material 3 verde
│   │   └── widgets/
│   │       └── loading_button.dart  # Botón con estado de carga
│   └── features/
│       ├── auth/
│       │   ├── providers/
│       │   │   └── auth_provider.dart  # AuthState, AuthNotifier, apiServiceProvider
│       │   └── views/
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       ├── home/
│       │   └── views/
│       │       └── home_shell.dart     # Bottom navigation bar
│       ├── dashboard/
│       │   └── views/
│       │       └── dashboard_screen.dart  # Stats, plan banner, quick actions
│       ├── animales/
│       │   ├── providers/
│       │   │   └── animal_provider.dart  # AnimalList, detail, árbol, resumen, producciones
│       │   └── views/
│       │       ├── animal_list_screen.dart   # Lista + filtros + buscar + scroll infinito
│       │       ├── animal_detail_screen.dart # Detalle con header, padres, historial esquilas
│       │       ├── animal_form_screen.dart   # Crear/editar con selector de padres + foto
│       │       ├── produccion_form_sheet.dart # Modal para crear/editar esquila
│       │       └── arbol_screen.dart         # Árbol genealógico vertical
│       ├── perfil/
│       │   └── views/
│       │       └── perfil_screen.dart  # Header gradiente, plan, info, logout
│       └── reportes/
│           └── views/
│               └── reportes_screen.dart  # Descarga CSV/PDF
```

## Pantallas

### Auth
- **Login**: formulario con teléfono y contraseña
- **Register**: registro con teléfono, nombre, contraseña

### Dashboard
- Banner del plan con barra de progreso
- Estadísticas: total, machos, hembras
- Especies: alpaca, llama, ovino
- Acciones rápidas: nuevo animal, ver todos, reportes

### Animales
- **Lista**: scroll infinito, filtros por especie/sexo, buscador por arete/nombre, tag de categoría de edad en cada card, deslizar para eliminar
- **Detalle**: header con gradiente + foto, info con categoría de edad, padres tappables, observaciones, **historial de esquilas** con FAB para agregar
- **Formulario**: crear/editar con selector de padres (buscador modal con filtro por especie y categoría de edad), carga de fotos, confirmación de contraseña
- **Producción**: modal bottom sheet con DatePicker, peso vellón (kg), rendimiento (%), observaciones — editar/eliminar desde la lista
- **Árbol**: vista vertical indentada con líneas conectoras

### Perfil
- Header con gradiente, avatar, nombre, teléfono
- Card del plan con barra de progreso y botón cambiar plan
- Información: generaciones, fecha de registro
- Pull-to-refresh para recargar datos
- Cerrar sesión

### Reportes
- Descarga CSV/PDF (solo planes Básico/Criador)

## Tests

```bash
flutter test
```

30 tests:
- Modelos: AnimalModel (con categoriaEdad), ProduccionModel, UserModel, CandidatoModel, ArbolNode (fromJson/toJson)
- Estados: AuthState, AnimalListState (copyWith)
- Widgets: LoadingButton (idle, loading, disabled)
- Integración: LoginScreen render cuando no autenticado
**Backend 77 + Frontend 27 = 104 tests total.**

## Análisis estático

```bash
flutter analyze
```
0 issues.

## Configuración de plataformas

### Android
- `AndroidManifest.xml` (main): permiso INTERNET agregado
- NDK versión 27.0.12077973 (compatibilidad flutter_secure_storage)
- minSdk: flutter.minSdkVersion

### iOS
- `Info.plist`: `NSAllowsArbitraryLoads = true` para HTTP
- Soporta orientaciones portrait y landscape
