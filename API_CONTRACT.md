# Sports Hub — Contrato de API REST v1

> **Base URL:** `http://localhost:3000/api/v1`
> Todas las respuestas se devuelven en formato **JSON** (`Content-Type: application/json`).

---

## Autenticación

Los endpoints marcados con 🔒 requieren el header:

```
Authorization: Bearer <token_jwt>
```

El token se obtiene al hacer login o registro y tiene una validez de **24 horas**.

---

## 1. Autenticación (`/auth`)

### `POST /auth/login` — Iniciar Sesión

**Acceso:** Público

**Body:**
```json
{
  "email": "client@sportshub.com",
  "password": "password123"
}
```

**Respuesta 200 OK:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "exp": 1761573600,
  "user": {
    "id": 2,
    "name": "Cliente de Prueba",
    "email": "client@sportshub.com",
    "role": "client"
  }
}
```

**Respuesta 401 Unauthorized:**
```json
{ "error": "Credenciales inválidas" }
```

---

### `POST /auth/register` — Registrar Nueva Cuenta

**Acceso:** Público

**Body:**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Respuesta 201 Created:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "exp": 1761573600,
  "user": {
    "id": 10,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "role": "client"
  }
}
```

**Respuesta 422 Unprocessable Entity:**
```json
{ "errors": ["Email ya está en uso"] }
```

---

### `GET /auth/me` — Verificar Sesión Activa

**Acceso:** 🔒 Requiere token

**Respuesta 200 OK:**
```json
{
  "user": {
    "id": 2,
    "name": "Cliente de Prueba",
    "email": "client@sportshub.com",
    "role": "client"
  }
}
```

**Respuesta 401 Unauthorized:**
```json
{ "error": "No autorizado. Token inválido o ausente." }
```

---

## 2. Deportes (`/sports`)

### `GET /sports` — Listar Disciplinas Deportivas

**Acceso:** Público

**Respuesta 200 OK:**
```json
[
  { "id": 1, "name": "Fútbol", "courts_count": 4 },
  { "id": 2, "name": "Pádel", "courts_count": 3 },
  { "id": 3, "name": "Tenis", "courts_count": 2 }
]
```

---

## 3. Complejos Deportivos (`/sports_complexes`)

### `GET /sports_complexes` — Listar Complejos

**Acceso:** Público

**Respuesta 200 OK:**
```json
[
  {
    "id": 1,
    "name": "Complejo Palermo",
    "address": "Av. Libertador 1000",
    "city": "CABA",
    "cover_photo_url": "/rails/active_storage/blobs/...",
    "total_courts": 5
  }
]
```

---

### `GET /sports_complexes/:id` — Detalle de Complejo

**Acceso:** Público

**Respuesta 200 OK:** Mismo esquema que el elemento de lista.

**Respuesta 404 Not Found:**
```json
{ "error": "Complejo deportivo no encontrado" }
```

---

## 4. Canchas (`/courts`)

### `GET /courts` — Listar Canchas con Filtros

**Acceso:** Público

**Query params opcionales:**

| Parámetro | Tipo | Descripción |
|:---|:---|:---|
| `date` | `YYYY-MM-DD` | Fecha para calcular disponibilidad. Default: hoy. |
| `time` | `HH:MM` | Filtra canchas que tienen turno disponible a esa hora. |
| `sport` | `string` | Filtra por nombre de deporte (ej: `"padel"`). |
| `sport_id` | `integer` | Filtra por ID de deporte. |

**Ejemplo:** `GET /courts?date=2026-11-01&sport=padel`

**Respuesta 200 OK:**
```json
{
  "date": "2026-11-01",
  "day_of_week": 0,
  "courts": [
    {
      "id": 3,
      "name": "Cancha Pádel Cristal",
      "surface_type": "Cristal",
      "base_price": 2000.0,
      "is_active": true,
      "pricing_scheme_name": "Tarifa Pico Semana",
      "image_url": "/rails/active_storage/blobs/...",
      "sport": { "id": 2, "name": "Pádel" },
      "sports_complex": {
        "id": 1,
        "name": "Complejo Palermo",
        "address": "Av. Libertador 1000",
        "city": "CABA"
      },
      "time_slots": [
        {
          "id": 12,
          "day_of_week": 0,
          "day_name": "domingo",
          "start_time": "18:00",
          "end_time": "19:00",
          "time_range": "18:00 - 19:00 hs",
          "duration_in_hours": 1.0,
          "pricing": {
            "base_price": 2000.0,
            "multiplier": 1.5,
            "final_price": 3000.0
          },
          "available": true
        }
      ]
    }
  ]
}
```

**Respuesta 400 Bad Request** (fecha o hora con formato inválido):
```json
{ "error": "Formato de fecha inválido. Usar YYYY-MM-DD" }
```

---

### `GET /sports_complexes/:sports_complex_id/courts` — Canchas de un Complejo

**Acceso:** Público. Mismos filtros y esquema que `GET /courts`.

---

### `GET /courts/:id` — Detalle de Cancha

**Acceso:** Público

**Query params opcionales:** `date` (igual que en la lista)

**Respuesta 200 OK:**
```json
{
  "date": "2026-11-01",
  "day_of_week": 0,
  "court": { "...mismo esquema de cancha..." }
}
```

---

## 5. Reservas (`/reservations`)

### `GET /reservations` — Mis Reservas

**Acceso:** 🔒

**Respuesta 200 OK:**
```json
[
  {
    "id": 15,
    "reservation_date": "2026-11-05",
    "start_time": "2026-11-05T18:00:00.000Z",
    "end_time": "2026-11-05T19:00:00.000Z",
    "status": "confirmed",
    "payment_status": "partially_paid",
    "total_price": "1500.0",
    "deposit_amount": "450.0",
    "deposit_paid_at": "2026-10-26T21:45:00.000Z",
    "court": {
      "id": 3,
      "name": "Cancha Pádel Cristal",
      "surface_type": "Cristal",
      "sports_complex": {
        "id": 1,
        "name": "Complejo Palermo",
        "address": "Av. Libertador 1000"
      }
    }
  }
]
```

---

### `GET /reservations/:id` — Detalle de Reserva

**Acceso:** 🔒 (solo el titular puede ver su reserva)

**Respuesta 200 OK:** Mismo esquema que el elemento de lista.

**Respuesta 404 Not Found:**
```json
{ "error": "Reserva no encontrada o no autorizada" }
```

---

### `POST /reservations` — Crear Reserva

**Acceso:** 🔒

**Body:**
```json
{
  "reservation": {
    "court_id": 3,
    "reservation_date": "2026-11-05",
    "start_time": "2026-11-05 18:00:00",
    "end_time": "2026-11-05 19:00:00"
  }
}
```

**Respuesta 201 Created:** Objeto de la reserva creada en estado `pending`.

**Respuesta 422 Unprocessable Entity** (solapamiento de horario):
```json
{ "errors": ["La cancha ya se encuentra reservada en el horario seleccionado"] }
```

**Respuesta 422 Unprocessable Entity** (fecha en el pasado):
```json
{ "errors": ["Reservation date no puede ser en el pasado"] }
```

---

### `DELETE /reservations/:id` — Cancelar Reserva

**Acceso:** 🔒 (solo el titular)

**Respuesta 200 OK:**
```json
{
  "message": "Reserva cancelada exitosamente",
  "reservation": { "...objeto de reserva con status: 'cancelled'..." }
}
```

**Respuesta 422 Unprocessable Entity** (menos de 24 hs para el turno):
```json
{ "errors": ["No es posible cancelar la reserva: debe realizarse con al menos 24 horas de anticipación."] }
```

---

## 6. Depósitos / Seña (`/deposits`)

### `POST /deposits` — Generar Preferencia de Seña

**Acceso:** 🔒

Genera la preferencia de pago por el monto de la seña (30% del total).

**Body:**
```json
{ "reservation_id": 15 }
```

**Respuesta 201 Created:**
```json
{
  "reservation_id": 15,
  "deposit_amount": 450.0,
  "total_price": 1500.0,
  "init_point": "https://mock.payment.gateway/checkout/...",
  "preference_id": "mock_pref_15_1761400000"
}
```

**Respuesta 422 Unprocessable Entity** (reserva ya tiene seña):
```json
{ "error": "La reserva debe estar pendiente para generar el pago de seña" }
```

---

### `POST /deposits/webhook` — Confirmar Pago de Seña

**Acceso:** Público (webhook para pasarela de pagos)

Simula la confirmación de la pasarela (Mercado Pago o Mock). Actualiza la reserva a `confirmed` + `partially_paid`.

**Body:**
```json
{ "reservation_id": 15 }
```

**Respuesta 200 OK:**
```json
{ "status": "ok", "reservation_id": 15 }
```

**Respuesta 422 Unprocessable Entity** (ya confirmado):
```json
{ "error": "El depósito ya fue registrado para esta reserva" }
```

---

## Modelo de Estados

### Estado de Reserva (`status`)

```
pending ──→ confirmed
   │              │
   └──→ cancelled ←──┘
```

| Valor | Descripción |
|:---|:---|
| `pending` | Reserva creada, esperando pago de seña |
| `confirmed` | Seña abonada, turno asegurado |
| `cancelled` | Cancelada por el usuario (máx. 24 hs antes del turno) |

### Estado de Pago (`payment_status`)

| Valor | Descripción |
|:---|:---|
| `unpaid` | Sin pagos registrados |
| `partially_paid` | Seña del 30% abonada |
| `paid` | Total del turno saldado |

---

## Manejo de Errores General

| Código HTTP | Significado |
|:---|:---|
| `200 OK` | Solicitud exitosa |
| `201 Created` | Recurso creado correctamente |
| `400 Bad Request` | Parámetro de formato inválido (fecha, hora) |
| `401 Unauthorized` | Token ausente, inválido o expirado |
| `404 Not Found` | Recurso no encontrado o sin acceso |
| `422 Unprocessable Entity` | Validación de negocio fallida |
