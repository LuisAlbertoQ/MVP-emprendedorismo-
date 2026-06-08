# GeneApp Andina

Sistema de gestión para criadores de alpacas, llamas y ovinos en la región andina. MVP funcional con backend Django REST + frontend Flutter.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         GeneApp Andina                          │
├────────────────────────┬────────────────────────────────────────┤
│   front_genapp         │  back_GenApp                           │
│   (Flutter 3.29+)       │  (Django 4.2 + DRF 3.14)              │
│                        │                                        │
│   • Auth (JWT)         │  • Auth REST API                       │
│   • CRUD Animales      │  • CRUD Animales                       │
│   • Árbol genealógico  │  • Árbol genealógico                   │
│   • Dashboard          │  • Planes suscripción                  │
│   • Reportes           │  • Reportes CSV/PDF                    │
│   • Sincronización     │  • Sincronización offline              │
│   • Buscador           │  • Búsqueda por arete/nombre           │
└────────────────────────┴────────────────────────────────────────┘
         │                           │
         └──────── http ────────────┘
              (localhost:8000)
```

## Tecnologías

### Backend (`back_GenApp/`)
- Python 3.12+, Django 4.2 LTS, Django REST Framework 3.14
- MySQL 8.0+ (Laragon), SimpleJWT, drf-spectacular
- ReportLab (PDF), Pillow (imágenes)

### Frontend (`front_genapp/`)
- Flutter 3.29+, Dart 3.8+
- Riverpod (estado), GoRouter (navegación)
- Dio (HTTP), flutter_secure_storage (JWT)
- intl (fechas), path_provider (descargas)

## Requisitos mínimos

### Android
- API 21+ (Android 5.0)
- Permiso INTERNET

### iOS
- iOS 12+
- NSAppTransportSecurity configurado para HTTP

## Estructura del repositorio

```
MVP/
├── back_GenApp/          # Backend Django
│   ├── geneapp/          # Configuración del proyecto
│   ├── usuarios/         # App de usuarios y auth
│   ├── animales/         # App de animales
│   ├── env/              # Entorno virtual
│   └── requirements.txt
├── front_genapp/         # Frontend Flutter
│   ├── lib/
│   │   ├── data/         # Modelos, servicios, repositorios
│   │   ├── routes/       # GoRouter
│   │   └── ui/           # Pantallas y widgets
│   └── test/             # Tests unitarios y de widgets
└── README.md             # Este archivo
```

## Inicio rápido

### Backend
```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py runserver
```

### Frontend
```bash
cd front_genapp
flutter pub get
flutter run
```

## Planes de suscripción

| Plan | Precio | Animales | Generaciones | Reportes |
|------|--------|:--------:|:------------:|:--------:|
| Gratuito | Gratis | 20 | 2 | ❌ |
| Básico | S/ 7.90/mes | 150 | 3 | ❌ |
| Criador | S/ 19.90/mes | 500 | 3 | ✅ CSV/PDF |

## Tests

### Backend
```bash
cd back_GenApp
.\env\Scripts\python.exe manage.py test
```
50 tests — modelos, serializers, views, límites por plan, árbol genealógico.

### Frontend
```bash
cd front_genapp
flutter test
```
27 tests — modelos (fromJson/toJson), estados (copyWith), widgets (LoadingButton), integración mínima.
`flutter analyze` — 0 issues.
