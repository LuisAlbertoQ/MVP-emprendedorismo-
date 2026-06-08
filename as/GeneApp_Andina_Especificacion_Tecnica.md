# Especificación Técnica del Sistema – GeneApp Andina
**Versión Simplificada**

---

## 1. Resumen del Sistema

GeneApp Andina es una plataforma SaaS para pequeños y medianos criadores de alpacas, llamas y ovinos en la región andina (inicialmente Puno). El sistema consta de:

- **Backend API REST** (Django REST Framework) que gestiona usuarios, animales, filiación básica, límites por plan de suscripción y sincronización con la app móvil.
- **Aplicación móvil** (Flutter) para Android (y luego iOS) que permite registrar animales, consultar listados, ver el árbol genealógico y usar la app sin conexión (offline-first).

> **No incluye en esta versión:** gestión de fibra, esquila, apareamientos planificados, cálculo de consanguinidad, múltiples criaderos, roles de usuario, ni módulo de pagos integrado (se hará con webhooks o manual al inicio).

---

## 2. Tecnologías, Frameworks y Librerías

### 2.1 Backend (API REST)

| Componente | Tecnología / Librería | Versión sugerida |
|---|---|---|
| Lenguaje | Python | 3.10+ |
| Framework web | Django | 4.2 LTS |
| API REST | Django REST Framework (DRF) | 3.14+ |
| Autenticación | DRF + Simple JWT | 5.3+ |
| Base de datos | MySQL | 8.0+ |
| Conector MySQL | mysqlclient | 2.2+ |
| Migraciones | Django ORM | – |
| Variables de entorno | python-decouple | 3.8+ |
| CORS | django-cors-headers | 4.3+ |
| Documentación API | drf-spectacular (OpenAPI) | 0.26+ |
| Manejo de imágenes | Pillow | 10.0+ |
| Sincronización offline | Endpoints específicos (no librería extra) | – |
| Servidor de aplicaciones | Gunicorn (producción) | 20.1+ |
| Servidor web (proxy) | Nginx | 1.22+ |

### 2.2 Frontend (App Móvil)

| Componente | Tecnología / Librería | Versión sugerida |
|---|---|---|
| Framework | Flutter | 3.16+ (stable) |
| Lenguaje | Dart | 3.0+ |
| Base de datos local (offline) | sqflite | 2.3+ |
| Estado de la app | Provider o Riverpod | 6.0+ |
| Peticiones HTTP | dio | 5.3+ |
| Autenticación | flutter_secure_storage (JWT) | 9.0+ |
| Sincronización manual | Lógica propia con timestamps y colas | – |
| Manejo de imágenes | image_picker | 1.0+ |
| Notificaciones push (opcional) | firebase_messaging | 14.0+ |

### 2.3 Infraestructura y Despliegue

| Componente | Tecnología |
|---|---|
| Servidor en la nube | DigitalOcean, AWS Lightsail o VPS similar |
| Sistema operativo | Ubuntu 22.04 LTS |
| Servidor de aplicaciones | Gunicorn + Nginx |
| Base de datos MySQL | Instalada en el mismo VPS (o RDS si escala) |
| Almacenamiento de imágenes | Carpeta `media` servida por Nginx |
| Certificado SSL | Let's Encrypt (Certbot) |
| Control de versiones | Git (GitHub / GitLab) |
| CI/CD (opcional) | GitHub Actions |

---

## 3. Requisitos Funcionales (RF)

### RF1: Gestión de Usuarios y Autenticación

| ID | Requisito |
|---|---|
| RF1.1 | El usuario se registra con su número de teléfono, nombre completo y contraseña. |
| RF1.2 | El usuario inicia sesión con teléfono y contraseña, recibiendo un token JWT. |
| RF1.3 | El token JWT se envía en cada petición protegida (`Authorization: Bearer <token>`). |
| RF1.4 | El sistema asigna automáticamente el plan Gratuito (20 animales máx.) al registro. |
| RF1.5 | El usuario puede cambiar de plan (Básico o Criador) a través de un endpoint; el pago se gestiona externamente al inicio o con webhook. |
| RF1.6 | El usuario puede consultar su plan actual y el número de animales usados. |

### RF2: Gestión de Animales (CRUD)

| ID | Requisito |
|---|---|
| RF2.1 | El usuario puede registrar un animal con los campos obligatorios: arete (único por usuario), especie (alpaca/llama/ovino), sexo (hembra/macho), fecha de nacimiento. |
| RF2.2 | Campos opcionales: nombre, raza, padre, madre, foto (una), observaciones, activo (por defecto `true`). |
| RF2.3 | El sistema valida que el padre y la madre existen y pertenecen al mismo usuario. |
| RF2.4 | El sistema valida que un animal no puede ser su propio padre o madre. |
| RF2.5 | El usuario puede editar cualquier campo de un animal. |
| RF2.6 | El usuario puede eliminar un animal (borrado lógico → marcado como inactivo). |
| RF2.7 | El sistema impide crear un nuevo animal si el usuario alcanzó el límite de su plan. |
| RF2.8 | El usuario puede listar sus animales con paginación (20 por página) y filtros por especie, sexo y estado activo. |
| RF2.9 | El usuario puede obtener el detalle completo de un animal, incluyendo nombres/aretes de padre y madre. |
| RF2.10 | El usuario puede subir una foto del animal (JPG/PNG, máximo 2 MB). |

### RF3: Árbol Genealógico

| ID | Requisito |
|---|---|
| RF3.1 | El sistema genera el árbol genealógico hasta 2 generaciones (padres y abuelos) para el plan Gratuito, y hasta 3 generaciones para planes de pago. |
| RF3.2 | El árbol se entrega como JSON con la estructura: `{ animal, padre, madre, abuelo_paterno, abuela_paterna, abuelo_materno, abuela_materna }`. |
| RF3.3 | Si un ancestro no existe, el campo correspondiente es `null`. |

### RF4: Sincronización Offline (App Móvil)

| ID | Requisito |
|---|---|
| RF4.1 | La app móvil funciona sin conexión a internet (offline-first). |
| RF4.2 | En modo offline, los animales se guardan en una base de datos local (SQLite). |
| RF4.3 | Cada animal tiene un campo `sync_status` con valores: `pendiente`, `sincronizado`, `error`. |
| RF4.4 | Al recuperar conexión, el usuario puede iniciar una sincronización manual o automática en segundo plano. |
| RF4.5 | El backend provee el endpoint `/sync` que acepta una lista de animales nuevos/modificados y retorna los cambios recientes del servidor (timestamp incremental). |
| RF4.6 | En caso de conflicto (mismo animal modificado en dos dispositivos), el backend resuelve con la última modificación (timestamp más reciente). |

### RF5: Límites por Plan de Suscripción

| ID | Plan | Animales | Árbol | Sincronización | Extras |
|---|---|---|---|---|---|
| RF5.1 | **Gratuito** | Hasta 20 | 2 generaciones | Solo local | – |
| RF5.2 | **Básico** (S/ 7.90/mes) | Hasta 150 | 3 generaciones | Nube | Soporte WhatsApp |
| RF5.3 | **Criador** (S/ 19.90/mes) | Hasta 500 | 3 generaciones | Nube | Exportación PDF/Excel |
| RF5.4 | El backend verifica el límite de animales antes de cada creación. | | | | |
| RF5.5 | El backend retorna el plan y límites en cada petición de perfil de usuario. | | | | |

### RF6: Reportes y Exportación (solo planes de pago)

| ID | Requisito |
|---|---|
| RF6.1 | El usuario puede generar un listado de todos sus animales en formato CSV o PDF desde la app. |
| RF6.2 | El listado incluye: arete, nombre, especie, sexo, fecha de nacimiento, padre, madre, observaciones. |
| RF6.3 | La generación se realiza en el backend (endpoint `/reporte/animales`) que devuelve el archivo. |

---

## 4. Requisitos No Funcionales (RNF)

| ID | Requisito | Métrica / Condición |
|---|---|---|
| RNF1 | Rendimiento | Tiempo de respuesta (p95) < 300 ms para listados, < 500 ms para árboles genealógicos. |
| RNF2 | Disponibilidad | 99.5% de disponibilidad en horario diurno (6 am – 10 pm). |
| RNF3 | Seguridad | Contraseñas hasheadas (PBKDF2 o bcrypt). Tokens JWT con expiración de 7 días. Siempre HTTPS. |
| RNF4 | Offline-first | La app debe permitir registrar al menos 50 animales sin conexión y sincronizarlos al recuperar internet. |
| RNF5 | Escalabilidad | El backend debe soportar al menos 1000 usuarios concurrentes en servidor inicial (2 vCPU, 4 GB RAM). |
| RNF6 | Usabilidad | Iconos grandes, texto claro, soporte en español (quechua en versión futura). |
| RNF7 | Mantenibilidad | Código bajo buenas prácticas de Django: apps separadas, variables de entorno, documentación con OpenAPI. |
| RNF8 | Compatibilidad | App móvil funcional en Android 8.0 o superior (dispositivos de gama baja). |

---

## 5. Estructura de la API

**Base URL:** `https://api.geneapp.com/api/v1/`

### Autenticación

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/auth/register/` | Registro de usuario (teléfono, nombre, contraseña) |
| `POST` | `/auth/login/` | Login; retorna access/refresh token |
| `POST` | `/auth/refresh/` | Refrescar token JWT |
| `GET` | `/auth/perfil/` | Obtener datos del usuario (plan, animales usados) |

### Animales

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/animales/` | Listar animales (paginado, con filtros) |
| `POST` | `/animales/` | Crear animal |
| `GET` | `/animales/{id}/` | Detalle de animal |
| `PUT` / `PATCH` | `/animales/{id}/` | Actualizar animal |
| `DELETE` | `/animales/{id}/` | Eliminar animal (borrado lógico o físico) |
| `GET` | `/animales/{id}/arbol/` | Árbol genealógico (profundidad según plan) |

### Sincronización

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/sync/` | Envía cambios locales y devuelve cambios del servidor (timestamp incremental) |

### Reportes (solo planes de pago)

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/reporte/animales/?format=csv` | Descargar listado de animales en CSV |
| `GET` | `/reporte/animales/?format=pdf` | Descargar listado en PDF |

### Planes y pagos

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/suscripcion/cambiar-plan/` | Cambiar de plan (requiere confirmación de pago vía webhook) |
| `POST` | `/suscripcion/webhook-yape/` | Endpoint para notificaciones de Yape (integración externa) |

---

## 6. Estructura de la App Móvil (Pantallas Clave)

| # | Pantalla | Descripción |
|---|---|---|
| 1 | **Splash** | Carga inicial; verifica token y redirige a Login o Home. |
| 2 | **Login / Registro** | Ingreso con teléfono y contraseña; registro con teléfono, nombre y contraseña. |
| 3 | **Home** | Lista de animales del usuario con botón para agregar, ícono de sincronización y menú de perfil. |
| 4 | **Registro / Edición de animal** | Formulario con: arete, nombre, especie, sexo, fecha de nacimiento, padre, madre, foto, observaciones. |
| 5 | **Detalle de animal** | Toda la información del animal, foto, padre/madre y botón "Ver árbol genealógico". |
| 6 | **Árbol genealógico** | Vista gráfica (cards o texto) con el animal, sus padres y abuelos según profundidad permitida. |
| 7 | **Perfil / Plan** | Plan actual, animales usados vs. límite, opciones para cambiar de plan (redirige a pago externo o Yape). |
| 8 | **Sincronización manual** | Botón que envía cambios locales al servidor y descarga actualizaciones. |
| 9 | **Configuración** | Cerrar sesión, borrar datos locales, etc. |

---

## 7. Entorno de Desarrollo y Despliegue

### Desarrollo local

**Backend:**
```bash
git clone <repo>
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # configurar variables
python manage.py migrate
python manage.py runserver
```

**Frontend:**
```bash
git clone <repo>
flutter pub get
flutter run   # apuntando a backend local o de pruebas
```

### Producción

- **Backend:** Servidor Ubuntu con Nginx + Gunicorn + MySQL. Variables de entorno seguras. Certificado SSL con Let's Encrypt.
- **Frontend:** Generar APK con `flutter build apk --split-per-abi` y subir a Google Play Console.

### Variables de entorno requeridas (backend)

```env
SECRET_KEY=...
DEBUG=False
DB_NAME=geneapp
DB_USER=...
DB_PASSWORD=...
DB_HOST=localhost
DB_PORT=3306
ALLOWED_HOSTS=api.geneapp.com
CORS_ALLOWED_ORIGINS=https://app.geneapp.com
YAPE_WEBHOOK_SECRET=...   # opcional
```

---

## 8. Documentación y Pruebas

| Tipo | Herramienta / Método |
|---|---|
| Documentación de API | drf-spectacular (OpenAPI) — accesible en `/api/schema/swagger-ui/` |
| Pruebas unitarias | Django tests para modelos, vistas y límites de animales |
| Pruebas de integración | Postman/Newman o pytest-django |
| Pruebas de la app | Flutter widget tests y device tests con emulador |

---

## 9. Entregables del Sistema

- Código fuente del backend (Django) en repositorio privado (GitHub)
- Código fuente de la app móvil (Flutter)
- Documentación técnica (este documento + comentarios en código)
- Manual de usuario en PDF (versión simple)
- Archivo APK de prueba para Android
- Instrucciones de despliegue para servidor

---

## 10. Nota Final

Esta especificación se ajusta estrictamente al modelo SaaS para pequeños criadores, sin funcionalidades complejas (fibra, apareamientos, consanguinidad, roles). Puede ser implementada por un solo desarrollador en aproximadamente **8–10 semanas** (backend + frontend básico). Las funcionalidades avanzadas se dejan para versiones futuras (Pro o Empresarial).
