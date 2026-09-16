# Sports Hub - Plataforma de Gestión y Reserva de Canchas Deportivas

Sports Hub es una aplicación web backend desarrollada con Ruby on Rails que centraliza la administración de complejos deportivos, la oferta de canchas y el flujo de reservas para los usuarios finales. El proyecto incluye una interfaz administrativa tradicional (Back-office) y una API RESTful versionada orientada a ser consumida por clientes frontend o aplicaciones móviles.

---

## Características Principales

* Back-office Administrativo: Panel de control con arquitectura MVC tradicional protegido por autenticación para la gestión de complejos deportivos, canchas, horarios y visualización de reservas.
* API RESTful Versionada (/api/v1): Endpoints en formato JSON que permiten consultar la oferta deportiva y concretar reservas.
* Autenticación por Tokens (JWT): Mecanismo de autenticación desacoplado para usuarios de la API mediante JSON Web Tokens.
* Reglas de Dominio y Consistencia: Validaciones a nivel de modelo para evitar solapamientos de turnos en una misma cancha y restricciones de reservas en fechas pasadas.
* Archivos Multimedia: Soporte para adjuntar imágenes a complejos y canchas mediante Active Storage.
* Notificaciones por Email: Confirmación automática de reservas por correo electrónico utilizando plantillas HTML y de texto plano a través de Action Mailer.
* Suite de Pruebas Automatizadas: Cobertura de tests unitarios de modelos y pruebas de integración sobre los controladores y flujos de la API.

---

## Requisitos del Sistema

* Ruby: >= 3.2.0
* Rails: 8.x
* Base de Datos: SQLite3 (entornos de desarrollo y test)
* Gestor de dependencias: Bundler

---

## Instalación y Puesta en Marcha

1. Clonar el repositorio y acceder a la carpeta:
git clone <URL_DEL_REPOSITORIO>
cd proyecto_rails

2. Instalar dependencias:
bundle install

3. Configurar la base de datos (creación, migraciones y datos de prueba):
bin/rails db:prepare
bin/rails db:seed

4. Iniciar el servidor local:
bin/rails server

La aplicación quedará disponible en http://localhost:3000.

---

## Cuentas y Accesos Preconfigurados

Los datos sembrados por defecto en db/seeds.rb proveen los siguientes usuarios de prueba:

### Administrador (Acceso al Back-office)
* URL de Ingreso: http://localhost:3000/login
* Email: admin@sportshub.com
* Password: password123
* Permisos: Gestión integral de complejos, canchas y administración de reservas.

### Cliente (Usuario de la API)
* Email: client@sportshub.com
* Password: password123
* Uso: Autenticación vía endpoint para operar reservas.

---

## Documentación de la API (/api/v1)

Todos los endpoints retornan respuestas en formato JSON. Las rutas que requieran autenticación deben incluir el header:
Authorization: Bearer <token_jwt>

### Autenticación

POST /api/v1/auth/login
Headers: Content-Type: application/json
Body:
{
  "email": "client@sportshub.com",
  "password": "password123"
}

Respuesta exitosa (200 OK):
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 2,
    "name": "Cliente de Prueba",
    "email": "client@sportshub.com",
    "role": "client"
  }
}

---

### Complejos y Canchas

GET /api/v1/sports_complexes
Respuesta (200 OK): Lista de complejos deportivos con información básica.

GET /api/v1/sports_complexes/:id
Respuesta (200 OK): Información detallada del complejo seleccionado.

GET /api/v1/sports_complexes/:sports_complex_id/courts
Respuesta (200 OK): Listado de canchas pertenecientes al complejo.

GET /api/v1/sports_complexes/:sports_complex_id/courts/:id
Respuesta (200 OK): Detalle específico de la cancha.

---

### Reservas (Requiere Autenticación)

GET /api/v1/reservations
Headers: Authorization: Bearer <token>
Respuesta (200 OK): Listado de reservas asociadas al usuario autenticado, ordenadas cronológicamente.

GET /api/v1/reservations/:id
Headers: Authorization: Bearer <token>
Respuesta (200 OK): Detalle de la reserva solicitada (solo accesible por su titular).

POST /api/v1/reservations
Headers:
  Authorization: Bearer <token>
  Content-Type: application/json
Body:
{
  "reservation": {
    "court_id": 1,
    "reservation_date": "2026-10-15",
    "start_time": "2026-10-15 18:00:00",
    "end_time": "2026-10-15 19:00:00"
  }
}

Respuesta exitosa (201 Created): Objeto de la reserva creada con importe calculado y estado inicial.

Respuesta de error por solapamiento (422 Unprocessable Entity):
{
  "errors": [
    "La cancha ya se encuentra reservada en el horario seleccionado"
  ]
}

---

## Arquitectura y Modelo de Datos

La persistencia del sistema se apoya en los siguientes modelos principales y sus asociaciones:

* User: Maneja credenciales cifradas con has_secure_password, control de roles (admin, client) y la relación con reservas.
* SportsComplex: Agrupa instalaciones deportivas, se vincula a una ciudad y soporta una imagen de portada (cover_photo) administrada mediante Active Storage.
* Court: Representa el espacio físico reservable; pertenece a un complejo y a un deporte, y cuenta con imagen adjunta (image).
* Sport: Catálogo de disciplinas (Fútbol, Tenis, Pádel, etc.) vinculadas a las canchas.
* Reservation: Registra el turno solicitado por un usuario para una cancha específica en fecha y franja horaria determinadas, con estados (pending, confirmed, cancelled).
* City / Province: Normalización geográfica para la ubicación de los complejos.

---

## Pruebas y Análisis de Calidad

Ejecutar la suite completa de tests automatizados:
bin/rails test

Inspección de código y estilo con RuboCop:
bundle exec rubocop

Auditoría estática de seguridad con Brakeman:
bundle exec brakeman --no-pager --summary