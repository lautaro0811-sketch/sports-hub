# Sports Hub — Backend (API Rails)

Plataforma de gestión y reserva de canchas deportivas. Backend desarrollado con **Ruby on Rails 8**, exponiendo una API REST versionada (`/api/v1`) y un back-office administrativo.

---

## Stack Tecnológico

- **Ruby:** 3.4.x (gestionado con `mise`)
- **Rails:** 8.1.x
- **Base de Datos:** SQLite3 (desarrollo y test)
- **Autenticación:** JWT (`gem jwt`) + `has_secure_password` (bcrypt)
- **Multimedia:** Active Storage
- **Email:** Action Mailer
- **Tests:** Minitest (103 tests · 0 fallas)
- **Calidad de Código:** RuboCop · Brakeman

---

## Instalación y Puesta en Marcha

### Requisitos previos
- Ruby >= 3.2 instalado (recomendado con `mise`)
- Bundler

```bash
# 1. Clonar e ingresar al repositorio
git clone https://github.com/lautaro0811-sketch/sports-hub.git
cd sports-hub

# 2. Instalar dependencias
bundle install

# 3. Crear base de datos, correr migraciones y cargar datos de prueba
bin/rails db:prepare
bin/rails db:seed

# 4. Levantar el servidor (puerto 3000)
bin/rails server
```

La API quedará disponible en: **`http://localhost:3000/api/v1`**
El back-office admin en: **`http://localhost:3000/login`**

---

## Cuentas de Prueba (generadas por `db/seeds.rb`)

| Rol | Email | Password |
|:---|:---|:---|
| Administrador | `admin@sportshub.com` | `password123` |
| Cliente API | `client@sportshub.com` | `password123` |

---

## Arquitectura y Estructura

```
app/
├── controllers/
│   ├── admin/                    # Back-office (MVC tradicional)
│   │   ├── dashboard_controller.rb
│   │   ├── courts_controller.rb
│   │   ├── pricing_schemes_controller.rb
│   │   ├── reservations_controller.rb
│   │   └── sports_complexes_controller.rb
│   └── api/v1/                   # API RESTful JSON
│       ├── base_controller.rb    # Autenticación JWT centralizada
│       ├── authentication_controller.rb  # Login, Register, Me
│       ├── sports_controller.rb
│       ├── sports_complexes_controller.rb
│       ├── courts_controller.rb  # Filtros + disponibilidad + precios
│       ├── reservations_controller.rb
│       └── deposits_controller.rb        # Seña + webhook de pago
├── models/
│   ├── user.rb                   # Roles: admin / client
│   ├── sports_complex.rb         # Complejo deportivo (con Active Storage)
│   ├── court.rb                  # Cancha, precios dinámicos, disponibilidad
│   ├── sport.rb                  # Catálogo de disciplinas
│   ├── time_slot.rb              # Franja horaria por día de la semana
│   ├── pricing_scheme.rb         # Esquema de tarifas
│   ├── pricing_rule.rb           # Regla de multiplicador (día + rango horario)
│   └── reservation.rb            # Turno reservado (estados + seña)
└── views/
    ├── admin/                    # Vistas ERB del back-office
    └── api/v1/courts/            # Vistas Jbuilder para la API JSON
```

---

## Modelo de Datos (Entidades Principales)

```
User ──< Reservation >── Court ──< TimeSlot
                           │
                     SportsComplex
                           │
                     PricingScheme ──< PricingRule
                           │
                          Sport
```

---

## Contrato de la API

Documentación completa de endpoints, parámetros, ejemplos JSON y códigos de respuesta:

👉 **[API_CONTRACT.md](./API_CONTRACT.md)**

---

## Comandos de Desarrollo

```bash
# Tests automatizados (103 tests)
bin/rails test

# Linter de código (RuboCop)
bundle exec rubocop

# Auditoría de seguridad (Brakeman)
bundle exec brakeman --no-pager --summary

# Consola Rails
bin/rails console

# Resetear base de datos
bin/rails db:reset
```

---

## Variables de Entorno

Para producción, configurar en `config/credentials.yml.enc`:

```
SECRET_KEY_BASE=<clave secreta de Rails>
JWT_SECRET=<clave para firmar tokens JWT>
```

---

## Ramas Git

| Rama | Descripción |
|:---|:---|
| `main` | Base estable — TP Nº 1 entregado |
| `feature/tp2-api-integration` | Integración con el frontend — TP Nº 2 |
| `feature/pagos-seña` | Funcionalidad de pagos del back-office |

---

## Proyectos Relacionados

- **Frontend React:** [sports-hub-frontend](https://github.com/lautaro0811-sketch/sports-hub-frontend)
