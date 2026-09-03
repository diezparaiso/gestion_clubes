# ARQUITECTURA MAESTRA — PLATAFORMA DE GESTIÓN Y MONETIZACIÓN DE CLUBES DEPORTIVOS

Versión: 1.0
Fecha: 2026-09-01
Estado: Arquitectura inicial / antes de programar
Objetivo: construir una plataforma SaaS multi-club, escalable y autogestionable, desarrollada principalmente con Flutter y VS Code, asistida por IA.

---

## 0. PRINCIPIOS NO NEGOCIABLES

1. Frontend: Flutter + Dart.
2. IDE principal: Visual Studio Code.
3. La primera versión será Flutter Web con comportamiento PWA/responsive.
4. La misma base de código debe permitir evolucionar a Android/iOS sin rehacer el producto.
5. Backend recomendado: Supabase:
   - PostgreSQL
   - Auth
   - Storage
   - Row Level Security (RLS)
   - Edge Functions cuando sean necesarias.
6. Código mantenible y modular. Nada de un `main.dart` gigante.
7. La IA generará código siguiendo esta arquitectura; nunca debe inventar carpetas, nombres o patrones sin documentarlo.
8. No se debe implementar una funcionalidad que contradiga esta arquitectura sin registrar primero la decisión.
9. La interfaz estará inicialmente en español, pero el código, nombres de archivos, clases, funciones, variables y tablas se escribirán en inglés.
10. Diseño responsive desde el primer día: móvil, tablet, portátil y escritorio.
11. Seguridad y privacidad por diseño, especialmente por la presencia de menores.
12. La plataforma debe permitir múltiples clubes utilizando la misma infraestructura.
13. Cada club debe estar aislado lógicamente de los demás.
14. Los identificadores internos nunca deben reutilizarse.
15. El número de socio es un dato administrativo independiente del ID interno.
16. Las operaciones económicas deben tener trazabilidad.
17. Las rifas, sorteos y porras son módulos prioritarios de monetización, pero deben diseñarse teniendo en cuenta la legislación aplicable antes de activar pagos reales.
18. No almacenar datos de tarjetas. Los pagos se delegarán a un proveedor especializado.
19. La exportación de datos a CSV/Excel debe formar parte del diseño.
20. Antes de programar, cualquier decisión importante debe estar documentada.

---

# 1. VISIÓN DEL PRODUCTO

La plataforma no se posicionará inicialmente como un software deportivo gigantesco.

Propuesta:

> Plataforma de gestión, comunicación y generación de ingresos para clubes deportivos pequeños y medianos.

El club debe poder autogestionarse sin conocimientos técnicos.

## Objetivos

- Gestionar club.
- Gestionar usuarios y permisos.
- Gestionar socios.
- Gestionar directiva.
- Gestionar equipos.
- Gestionar jugadores y entrenadores.
- Gestionar tesorería.
- Crear rifas.
- Crear sorteos.
- Crear porras cuando el modelo legal y de pagos sea viable.
- Gestionar campañas.
- Comunicar información.
- Mostrar noticias.
- Integrar enlaces sociales.
- Enviar notificaciones.
- Exportar información.
- Facilitar patrocinadores.
- Preparar una base tecnológica para futuras entradas, merchandising, cuotas y otros ingresos.

---

# 2. ESTRATEGIA MVP

NO construir todo de una vez.

## MVP 1 — Fundación

- Landing pública.
- Registro/login.
- Crear club.
- Perfil del club.
- Usuarios.
- Roles y permisos.
- Dashboard.
- Socios.
- Número de socio.
- Equipos básicos.
- Tesorería básica.
- Exportación CSV.
- Configuración.
- Privacidad.

## MVP 2 — Monetización

- Rifas.
- Página pública de rifa.
- Participaciones.
- QR.
- Registro de ventas.
- Sorteo.
- Ganador.
- Historial.
- Integración de pago tras validación legal/técnica.

## MVP 3 — Comunicación

- Noticias.
- Eventos.
- Notificaciones push.
- Redes sociales.
- Avisos del club.

## MVP 4 — Monetización avanzada

- Porras, si el modelo legal lo permite.
- Patrocinadores.
- Campañas patrocinadas.
- Entradas.
- Merchandising.
- Estadísticas.

---

# 3. ARQUITECTURA GENERAL

                         FLUTTER
                            |
        +-------------------+-------------------+
        |                                       |
   FLUTTER WEB                              MOBILE
     PWA                                Android / iOS
        |                                       |
        +-------------------+-------------------+
                            |
                       SUPABASE
                            |
       +--------------------+---------------------+
       |                    |                     |
   PostgreSQL              Auth                Storage
       |                    |                     |
       +--------------------+---------------------+
                            |
                       Edge Functions
                            |
                +-----------+------------+
                |                        |
             Payments               Notifications
          proveedor externo          FCM / Web Push

---

# 4. MULTI-TENANCY

La plataforma será multi-tenant.

Un tenant = un club.

Ejemplo:

Club A
Club B
Club C

Todos utilizan la misma aplicación y base de datos, pero las consultas deben estar aisladas mediante `club_id` + Row Level Security.

Nunca confiar únicamente en filtros del frontend.

La seguridad real debe estar en PostgreSQL/Supabase RLS.

## Regla

Toda entidad perteneciente a un club debe tener, directa o indirectamente, `club_id`.

---

# 5. ROLES

Roles iniciales:

- `platform_admin`
- `club_president`
- `club_treasurer`
- `club_secretary`
- `team_manager`
- `coach`
- `staff`
- `member`
- `parent_guardian`
- `player`
- `follower`

## Importante

Rol ≠ persona.

Una persona puede tener más de un rol dentro del club.

Ejemplo:

Juan:
- president
- treasurer

Por eso no crear una única columna `role` en `profiles`.

Usar relación:

`club_memberships`

---

# 6. USUARIOS Y AUTENTICACIÓN

Proveedor principal: Supabase Auth.

Métodos previstos:

- Email + contraseña.
- Magic Link.
- Google.
- Apple.

No almacenar contraseñas nosotros.

## Perfil

`profiles`

Campos conceptuales:

- id
- first_name
- last_name
- email
- phone
- date_of_birth
- avatar_url
- created_at
- updated_at

No introducir más datos personales de los necesarios.

---

# 7. PRIVACIDAD Y MENORES

La aplicación puede contener menores.

Por defecto:

- No publicar fotos de menores.
- No publicar información innecesaria.
- Los perfiles públicos de jugadores deben ser mínimos.
- Las fotografías deben estar desactivadas por defecto.
- Cualquier publicación de imagen de un menor requiere un flujo de consentimiento adecuado.
- La configuración debe permitir al club gestionar permisos.
- No mostrar fecha de nacimiento completa públicamente.
- Evitar publicar teléfonos, emails o direcciones.
- Separar claramente datos internos y datos públicos.

## Principio

`private data != public profile`

Nunca reutilizar directamente un perfil interno como página pública.

La normativa aplicable deberá ser revisada antes del lanzamiento comercial. Esta arquitectura no sustituye asesoramiento jurídico.

---

# 8. CLUB

Tabla conceptual: `clubs`

Datos:

- id
- legal_name
- public_name
- tax_id
- address
- postal_code
- city
- province
- country
- email
- phone
- website
- logo_url
- facebook_url
- instagram_url
- x_url
- youtube_url
- privacy_policy_url
- created_at
- updated_at
- status

`tax_id` debe tratarse como dato administrativo privado.

---

# 9. DIRECTIVA

No crear una tabla aislada e independiente de usuarios.

Utilizar `club_memberships` y asignar roles.

Información adicional específica de cargo:

`club_officials`

Campos:

- id
- club_id
- profile_id
- position
- start_date
- end_date
- is_active

Cargos:

- President
- Vice President
- Treasurer
- Secretary
- Board Member
- Other

---

# 10. SOCIOS

Tabla: `memberships`

Debe distinguir:

- persona
- pertenencia al club
- número de socio
- estado.

Campos:

- id
- club_id
- profile_id
- member_number
- membership_type
- status
- join_date
- renewal_date
- leave_date
- notes
- created_at
- updated_at

Estados:

- active
- pending
- expired
- cancelled
- deceased
- suspended

---

# 11. NÚMERO DE SOCIO

IMPORTANTE:

`profile.id` y `membership.id` nunca cambian.

`member_number` es un identificador administrativo visible.

No renumerar automáticamente todos los socios por el hecho de que alguien cause baja.

Ejemplo:

100
101
102
103

Si 102 se da de baja:

100
101
103

No convertir automáticamente 103 en 102.

La aplicación puede ofrecer posteriormente una herramienta de "renumeración" explícita y controlada, con confirmación, historial y copia de seguridad.

Esto evita romper documentos, carnés, recibos e historiales antiguos.

---

# 12. CUOTAS DE SOCIOS

Futura tabla:

`membership_fees`

Conceptos:

- id
- club_id
- membership_id
- amount
- due_date
- status
- payment_method
- paid_at
- reference
- created_at

Métodos:

- bizum
- bank_transfer
- cash
- card
- other

La integración real de Bizum dependerá del proveedor y del producto de pago contratado. No asumir que un Bizum personal puede automatizarse como una pasarela empresarial.

---

# 13. TESORERÍA

Objetivo: que el tesorero pueda introducir ingresos y gastos manualmente y consultar el saldo.

Tablas:

`financial_accounts`

- id
- club_id
- name
- account_type
- opening_balance
- current_balance
- is_active

`financial_transactions`

- id
- club_id
- account_id
- type
- category_id
- amount
- transaction_date
- description
- reference
- created_by
- created_at
- updated_at

Tipos:

- income
- expense

Categorías:

- membership
- sponsorship
- raffle
- event
- equipment
- federation
- facilities
- salaries
- supplies
- other

## Regla contable básica

Saldo = saldo inicial + ingresos - gastos.

No modificar transacciones históricas sin dejar auditoría.

---

# 14. AUDITORÍA

Tabla:

`audit_logs`

Registrar:

- quién
- qué
- cuándo
- club
- entidad
- ID de entidad
- acción
- datos relevantes.

Acciones:

- create
- update
- delete
- login
- export
- payment
- raffle_draw
- permission_change

---

# 15. EQUIPOS

Tabla: `teams`

Campos:

- id
- club_id
- name
- category
- season_id
- coach_id
- assistant_coach_id
- description
- is_active

---

# 16. TEMPORADAS

Tabla:

`seasons`

Campos:

- id
- club_id
- name
- start_date
- end_date
- is_current

Ejemplo:

`2026/2027`

No mezclar datos de diferentes temporadas sin una relación explícita.

---

# 17. JUGADORES

Tabla:

`players`

No guardar toda la información directamente en `profiles`.

Relación:

profile → player → team assignment

Tabla:

`team_players`

Campos:

- id
- club_id
- team_id
- player_id
- jersey_number
- joined_at
- left_at
- is_active

---

# 18. ENTRENADORES

Un entrenador es un usuario/persona con una relación con el equipo.

Tabla:

`team_staff`

Campos:

- id
- club_id
- team_id
- profile_id
- role
- start_date
- end_date
- is_active

---

# 19. RIFAS — MÓDULO PRIORITARIO

Tablas iniciales:

`raffles`

- id
- club_id
- title
- description
- image_url
- ticket_price
- total_numbers
- start_at
- end_at
- draw_at
- status
- terms_url
- created_by
- created_at
- updated_at

Estados:

- draft
- scheduled
- active
- sold_out
- closed
- drawn
- cancelled

`raffle_tickets`

- id
- raffle_id
- number
- buyer_profile_id nullable
- buyer_name
- buyer_email
- buyer_phone
- payment_status
- payment_reference
- purchased_at

Nunca reutilizar números vendidos.

---

# 20. RIFA PÚBLICA

El comprador debe poder:

1. Abrir enlace.
2. Ver premio.
3. Ver precio.
4. Elegir número.
5. Introducir datos mínimos.
6. Pagar mediante proveedor compatible.
7. Recibir confirmación.

Debe existir una URL pública.

Ejemplo:

`/r/club-slug/raffle-slug`

La página pública NO debe permitir acceder a datos privados.

---

# 21. QR

Cada rifa tendrá:

- QR público.
- Botón compartir.
- Enlace corto.
- Imagen descargable para carteles.

El QR únicamente codifica una URL pública.

---

# 22. SORTEO

El sistema debe registrar:

- fecha
- método
- resultado
- ganador
- número
- usuario que ejecutó el sorteo
- timestamp
- evidencia/resultado si procede.

Tabla:

`raffle_draws`

No permitir modificar silenciosamente un sorteo finalizado.

---

# 23. PORRAS

Módulo futuro y condicionado a análisis jurídico.

No diseñar inicialmente como una casa de apuestas.

Antes de activar pagos:

- determinar naturaleza jurídica;
- revisar legislación estatal/autonómica aplicable;
- revisar obligaciones del organizador;
- revisar proveedor de pagos;
- revisar fiscalidad;
- revisar protección de menores.

La arquitectura debe permitir desactivarlo por club.

---

# 24. EVENTOS

Tabla:

`events`

Campos:

- id
- club_id
- title
- description
- location
- start_at
- end_at
- image_url
- visibility
- created_by

Tipos:

- match
- tournament
- meeting
- event
- fundraiser
- other

---

# 25. NOTICIAS

Tablas:

`posts`

- id
- club_id
- title
- body
- image_url
- author_id
- status
- published_at
- created_at
- updated_at

Estados:

- draft
- published
- archived

---

# 26. NOTIFICACIONES

Diseño:

`notifications`

- id
- club_id
- title
- body
- type
- target
- created_at

`user_devices`

- id
- profile_id
- platform
- token
- permission_status
- last_seen_at

La tecnología exacta de push debe validarse para Flutter Web/PWA y posteriormente Android/iOS.

---

# 27. REDES SOCIALES

El club podrá almacenar enlaces:

- Instagram
- Facebook
- YouTube
- X
- TikTok
- Website

Inicialmente serán enlaces.

No intentar publicar automáticamente en todas las redes desde el MVP.

La publicación automática puede convertirse en módulo futuro si existe API oficial y merece la pena.

---

# 28. PATROCINADORES

Futuro:

`sponsors`

- id
- club_id
- business_name
- contact_name
- email
- phone
- website
- logo_url
- notes
- status

`sponsor_contracts`

- id
- club_id
- sponsor_id
- start_date
- end_date
- amount
- benefits
- status

---

# 29. DASHBOARD

## Presidente

Ver:

- saldo
- ingresos
- gastos
- socios
- equipos
- rifas activas
- campañas
- eventos
- notificaciones
- patrocinadores
- alertas.

## Tesorero

Ver:

- saldo
- ingresos
- gastos
- categorías
- movimientos
- exportaciones.

## Secretario

Ver:

- socios
- directiva
- documentos
- comunicaciones.

## Entrenador

Ver:

- equipos asignados
- jugadores
- calendario
- eventos.

## Socio

Ver:

- perfil
- número de socio
- cuotas
- noticias
- eventos
- rifas
- avisos.

## Seguidor

Ver:

- noticias públicas
- eventos públicos
- rifas públicas
- información del club.

---

# 30. NAVEGACIÓN FLUTTER

Rutas conceptuales:

`/`
`/login`
`/register`
`/onboarding`
`/clubs`
`/club/:clubId`
`/dashboard`
`/members`
`/members/:id`
`/teams`
`/teams/:id`
`/finance`
`/finance/transactions`
`/raffles`
`/raffles/create`
`/raffles/:id`
`/raffles/:id/tickets`
`/raffles/:id/draw`
`/news`
`/events`
`/notifications`
`/sponsors`
`/settings`

Públicas:

`/club/:slug`
`/club/:slug/news`
`/club/:slug/events`
`/r/:clubSlug/:raffleSlug`

---

# 31. ESTRUCTURA DE CARPETAS

```text
club_platform/
│
├── android/
├── ios/
├── web/
│
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── app_theme.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── helpers/
│   │   ├── services/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── clubs/
│   │   ├── members/
│   │   ├── teams/
│   │   ├── finance/
│   │   ├── raffles/
│   │   ├── draws/
│   │   ├── events/
│   │   ├── news/
│   │   ├── notifications/
│   │   ├── sponsors/
│   │   └── settings/
│   │
│   └── shared/
│       ├── models/
│       ├── repositories/
│       └── widgets/
│
├── test/
├── integration_test/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
│
├── docs/
│   ├── architecture/
│   ├── database/
│   ├── ui/
│   ├── decisions/
│   ├── api/
│   └── ai/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── .env.example
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

---

# 32. REGLA DE ARCHIVOS FLUTTER

Una pantalla importante debe tener su propio archivo.

Ejemplo:

`create_raffle_page.dart`

No:

`raffles_everything.dart`

Evitar archivos de miles de líneas.

Separar:

- Page
- Widget
- Model
- Repository
- Service

---

# 33. PATRÓN DE ARQUITECTURA

Usar una arquitectura inspirada en:

Feature-first + separación Presentation / Domain / Data.

Ejemplo:

```text
features/raffles/

├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
│
├── domain/
│   ├── entities/
│   └── use_cases/
│
└── presentation/
    ├── pages/
    ├── widgets/
    └── controllers/
```

No introducir complejidad innecesaria.

La arquitectura debe ser suficientemente limpia para crecer, pero comprensible para un único desarrollador asistido por IA.

---

# 34. GESTIÓN DE ESTADO

Criterio inicial:

Riverpod.

Motivos:

- buena separación;
- testabilidad;
- escalabilidad;
- funciona bien con Flutter;
- facilita inyección de dependencias.

No mezclar Riverpod, Bloc, Provider y GetX.

Elegir un patrón y mantenerlo.

---

# 35. NAVEGACIÓN

Usar `go_router`.

La navegación debe contemplar:

- autenticación;
- usuario sin club;
- usuario con uno o varios clubes;
- roles;
- rutas públicas;
- deep links;
- rutas no autorizadas.

---

# 36. MODELOS

Preferir modelos inmutables y serializables.

Ejemplo conceptual:

`Club`
`Profile`
`Membership`
`Team`
`Raffle`
`RaffleTicket`
`FinancialTransaction`

No utilizar `Map<String, dynamic>` por toda la aplicación.

---

# 37. RESPONSIVE DESIGN

Diseñar primero para:

1. móvil.
2. tablet.
3. escritorio.

Breakpoints conceptuales:

- mobile: < 600 px
- tablet: 600–1023 px
- desktop: >= 1024 px

No fijar estos valores como dogma; centralizarlos en constantes y revisarlos durante pruebas.

## Móvil

- bottom navigation cuando sea adecuada;
- cards;
- botones grandes;
- formularios sencillos.

## Escritorio

- sidebar;
- dashboard con columnas;
- tablas;
- filtros;
- paneles.

---

# 38. DISEÑO VISUAL

Objetivo:

- fondo claro;
- blanco predominante;
- aspecto moderno;
- limpio;
- deportivo sin parecer infantil;
- accesible;
- animaciones suaves;
- buen contraste.

No abusar de animaciones.

Animaciones recomendadas:

- aparición de tarjetas;
- cambios de estado;
- loading;
- navegación;
- confirmaciones.

Nunca sacrificar rendimiento por efectos visuales.

---

# 39. COMPONENTES REUTILIZABLES

Crear un sistema de diseño:

`AppButton`
`AppTextField`
`AppDropdown`
`AppCard`
`AppDialog`
`AppDataTable`
`AppEmptyState`
`AppLoading`
`AppErrorState`
`AppAvatar`
`AppBadge`
`AppSectionHeader`

Así la IA podrá reutilizar componentes.

---

# 40. EXPORTACIÓN

El club debe poder exportar:

- socios;
- movimientos;
- ingresos;
- gastos;
- participaciones;
- equipos;
- determinados informes.

Formato mínimo:

CSV.

Formato Excel:

compatible con Excel.

La exportación debe respetar permisos y privacidad.

---

# 41. SUPABASE

Servicios:

## Auth
Usuarios.

## Database
PostgreSQL.

## Storage
- logos;
- imágenes de noticias;
- imágenes de rifas;
- documentos permitidos.

## RLS
Aislamiento por club.

## Edge Functions
Operaciones que no deben ejecutarse directamente desde el cliente.

Ejemplos futuros:

- confirmación de pagos;
- webhooks;
- operaciones sensibles;
- sorteos;
- notificaciones.

---

# 42. SEGURIDAD

Nunca confiar en:

- ocultar botones;
- rutas Flutter;
- variables del cliente.

Un usuario no autorizado puede intentar llamar directamente a Supabase.

Por tanto:

Frontend:
UX + validación.

Backend/RLS:
seguridad real.

---

# 43. PAGOS

No implementar pagos reales en el primer prototipo.

Primero:

- simular compra;
- probar estados;
- probar reservas de números;
- probar confirmaciones;
- probar cancelaciones.

Después seleccionar proveedor.

Requisitos:

- webhooks;
- pagos confirmados desde servidor;
- idempotencia;
- reintentos;
- conciliación;
- comisión;
- devolución;
- historial.

Nunca considerar que "el usuario volvió a la página de éxito" significa que el pago está confirmado.

---

# 44. RIFAS Y LEGALIDAD

Antes de vender participaciones reales:

- revisar legislación de juego/rifas;
- revisar ámbito estatal/autonómico;
- requisitos del organizador;
- bases del sorteo;
- fiscalidad;
- protección de datos;
- condiciones del proveedor de pagos;
- tratamiento de menores;
- publicidad.

La aplicación deberá permitir activar/desactivar funcionalidades por jurisdicción si fuera necesario.

---

# 45. IA COMO PARTE DEL DESARROLLO

La IA será una herramienta de programación, no el arquitecto autónomo.

Flujo:

1. Usuario pide funcionalidad.
2. IA revisa documentación.
3. IA identifica archivos afectados.
4. IA propone cambios.
5. Usuario ejecuta.
6. Se compila.
7. Se prueba.
8. Se corrige.
9. Se documenta.
10. Se hace commit.

La IA NO debe crear una arquitectura diferente espontáneamente.

---

# 46. REGLAS PARA PROMPTS DE IA

Cada prompt de programación deberá indicar:

- objetivo;
- arquitectura;
- archivos existentes;
- archivos que puede modificar;
- archivos que NO debe modificar;
- dependencias;
- comportamiento esperado;
- errores;
- tests;
- criterios de aceptación.

Ejemplo:

```text
OBJETIVO:
Crear CreateRafflePage.

CONTEXTO:
Proyecto Flutter + Riverpod + go_router + Supabase.

ARCHIVOS A CREAR:
lib/features/raffles/presentation/pages/create_raffle_page.dart

ARCHIVOS A MODIFICAR:
router.dart
raffle_repository.dart si fuese necesario.

NO MODIFICAR:
otros módulos.

REQUISITOS:
...
```

---

# 47. REGLAS DE NOMENCLATURA

Código en inglés.

Clases:

PascalCase

`RaffleService`

Variables:

camelCase

`ticketPrice`

Archivos:

snake_case

`create_raffle_page.dart`

Constantes:

`kDefaultPageSize`

Base de datos:

snake_case

`raffle_tickets`

No usar:

`cosa1`
`data2`
`temp`
`asdf`
`x`

excepto variables locales extremadamente obvias.

---

# 48. GIT / GITHUB

Ramas:

`main`
`develop`
`feature/...`
`fix/...`

Ejemplo:

`feature/raffle-management`

Commits claros:

`feat: add raffle creation`
`fix: validate member number`
`refactor: simplify finance repository`
`docs: update architecture`

Nunca guardar:

- claves privadas;
- passwords;
- API secrets;
- tokens.

---

# 49. VARIABLES DE ENTORNO

`.env.example`

Nunca subir `.env` real.

Conceptualmente:

`SUPABASE_URL`
`SUPABASE_ANON_KEY`

Las claves públicas/client-side no sustituyen las políticas RLS.

Secrets sensibles únicamente en backend/Edge Functions.

---

# 50. TESTING

Mínimo:

## Unit tests

- cálculo de saldo;
- validación número socio;
- estados rifa;
- permisos;
- reglas de negocio.

## Widget tests

- login;
- dashboard;
- crear rifa;
- formulario socio.

## Integration tests

- login → club → crear rifa;
- crear socio → exportar;
- crear ingreso → saldo.

No considerar una funcionalidad terminada hasta que pase sus pruebas básicas.

---

# 51. MANEJO DE ERRORES

Nunca mostrar errores técnicos al usuario.

Mal:

`PostgrestException code 23505`

Bien:

> No se ha podido guardar el número de socio. Comprueba que no esté asignado a otra persona.

Registrar detalle técnico en logs.

---

# 52. OFFLINE

No será prioridad del MVP.

Pero la arquitectura debe permitirlo en el futuro.

No diseñar todavía una sincronización offline compleja.

---

# 53. ESCALABILIDAD

El diseño debe soportar:

- 1 club;
- 10 clubes;
- 100 clubes;
- 1.000 clubes;
- potencialmente más.

No crear una base de datos independiente por club en el MVP.

Usar multi-tenancy con RLS.

---

# 54. SUPERADMINISTRACIÓN DE LA PLATAFORMA

Futuro panel interno:

- clubes;
- usuarios;
- incidencias;
- métricas;
- módulos activados;
- estado de pagos;
- configuración global.

No debe confundirse con el presidente de un club.

`platform_admin` pertenece a la plataforma, no al club.

---

# 55. CONFIGURACIÓN POR CLUB

Tabla futura:

`club_settings`

Permitir:

- módulos activos;
- nombre;
- colores;
- logo;
- redes;
- privacidad;
- configuración de notificaciones;
- configuración de socios.

Ejemplo:

```text
raffles_enabled = true
pools_enabled = false
sponsors_enabled = true
```

---

# 56. FUNCIONALIDADES ACTIVABLES

Arquitectura modular:

- members
- finance
- teams
- raffles
- draws
- pools
- events
- news
- notifications
- sponsors
- tickets
- store

El club solamente ve los módulos activos y permitidos.

---

# 57. MODELO DE DATOS — RELACIONES PRINCIPALES

```text
profiles
   |
   +---- club_memberships ---- clubs
   |
   +---- memberships -------- clubs
   |
   +---- players
   |
   +---- team_staff

clubs
 |
 +--- seasons
 |      |
 |      +--- teams
 |             |
 |             +--- team_players
 |
 +--- financial_accounts
 |       |
 |       +--- financial_transactions
 |
 +--- raffles
 |       |
 |       +--- raffle_tickets
 |       |
 |       +--- raffle_draws
 |
 +--- events
 |
 +--- posts
 |
 +--- sponsors
 |
 +--- club_settings
 |
 +--- audit_logs
```

---

# 58. DECISIONES QUE NO DEBEMOS TOMAR TODAVÍA

No decidir todavía:

- proveedor definitivo de pagos;
- precio comercial;
- comisión definitiva;
- modelo jurídico de porras;
- automatización completa de redes;
- aplicación nativa independiente;
- offline completo;
- IA para análisis deportivo.

Primero validar producto.

---

# 59. ORDEN REAL DE CONSTRUCCIÓN

FASE 0
- documentación;
- repositorio;
- Flutter;
- VS Code;
- Supabase;
- Git.

FASE 1
- tema;
- navegación;
- autenticación;
- perfiles.

FASE 2
- clubes;
- membresías;
- roles;
- RLS.

FASE 3
- socios;
- números de socio;
- exportación.

FASE 4
- equipos;
- temporadas;
- jugadores;
- entrenadores.

FASE 5
- tesorería;
- ingresos;
- gastos;
- saldo;
- categorías.

FASE 6
- dashboard.

FASE 7
- rifas;
- QR;
- página pública;
- participaciones;
- sorteo simulado.

FASE 8
- pagos reales tras validación.

FASE 9
- noticias;
- eventos;
- notificaciones.

FASE 10
- patrocinadores.

FASE 11
- porras, tras validación legal.

---

# 60. CRITERIO DE ÉXITO DEL MVP

No medir éxito por número de pantallas.

Medir:

1. ¿Un presidente puede crear un club sin ayuda?
2. ¿Puede añadir usuarios?
3. ¿Puede asignar roles?
4. ¿Puede introducir 100 socios?
5. ¿Puede exportarlos a CSV?
6. ¿Puede registrar ingresos/gastos?
7. ¿Puede ver el saldo?
8. ¿Puede crear una rifa?
9. ¿Puede compartirla mediante QR?
10. ¿Puede ver participaciones?
11. ¿Puede realizar un sorteo de prueba?
12. ¿Un usuario externo puede participar sin acceder a información privada?
13. ¿El sistema funciona bien en móvil y escritorio?

Si estas respuestas son sí, tenemos un MVP útil.

---

# 61. PRIMERA PANTALLA

Después de login:

```text
-------------------------------------------------
 CLUB PLATFORM
-------------------------------------------------

[Logo]  CD EJEMPLO

Hola, Presidente

-------------------------------------------------
| SALDO       | SOCIOS       | RIFAS ACTIVAS   |
| 8.450 €     | 247          | 2               |
-------------------------------------------------

INGRESOS       GASTOS        ESTE MES
2.450 €        1.180 €       +1.270 €

-------------------------------------------------

ACCIONES RÁPIDAS

[ + Socio ] [ + Ingreso ] [ + Gasto ] [ + Rifa ]

-------------------------------------------------

ACTIVIDAD RECIENTE

• Nuevo socio #248
• Rifa Navidad: 34 nuevas participaciones
• Gasto: material deportivo 350 €
-------------------------------------------------
```

En móvil, estas tarjetas se apilan.

---

# 62. REGLA FUNDAMENTAL DE DESARROLLO CON IA

Antes de pedir código:

1. Consultar este documento.
2. Definir módulo.
3. Definir pantalla.
4. Definir datos.
5. Definir permisos.
6. Definir comportamiento.
7. Crear/actualizar tests.
8. Generar código.
9. Ejecutar `flutter analyze`.
10. Ejecutar tests.
11. Ejecutar aplicación.
12. Documentar cambios.

Nunca:

"IA, créame toda la aplicación."

---

# 63. DOCUMENTOS QUE DEBEN EXISTIR

Dentro de `/docs`:

`01_product_requirements.md`
`02_architecture.md`
`03_database.md`
`04_security_privacy.md`
`05_ui_design.md`
`06_roles_permissions.md`
`07_api_integrations.md`
`08_development_workflow.md`
`09_ai_coding_rules.md`
`10_testing.md`
`11_decisions.md`
`12_roadmap.md`

---

# 64. DECISION LOG

Archivo:

`docs/decisions/architecture_decisions.md`

Formato:

```text
ADR-001
Título: Flutter Web como primera plataforma
Estado: Aceptada

Contexto:
Queremos una única base de código.

Decisión:
Flutter Web/PWA será la primera plataforma.

Consecuencia:
Se prioriza responsive y compatibilidad web.
```

Todas las decisiones importantes deberán registrarse.

---

# 65. REGLA SOBRE CAMBIOS DE ARQUITECTURA

Si la IA considera que debe:

- cambiar Riverpod;
- cambiar Supabase;
- cambiar estructura;
- añadir una tecnología;
- mover carpetas;
- cambiar nombres;
- introducir otro backend;

debe detenerse y explicarlo antes de hacerlo.

---

# 66. CHECKLIST DE CADA FEATURE

```text
[ ] Requisito definido
[ ] Pantallas definidas
[ ] Roles definidos
[ ] Datos definidos
[ ] RLS revisado
[ ] Modelo creado
[ ] Repository creado
[ ] UI creada
[ ] Responsive comprobado
[ ] Loading
[ ] Empty state
[ ] Error state
[ ] Validaciones
[ ] Tests
[ ] Flutter analyze
[ ] Documentación
```

---

# 67. PRIMER OBJETIVO TÉCNICO

No empezar por rifas.

Primero construir:

`Flutter → Supabase → Auth → Club → Roles → Socios → Tesorería`

Cuando eso funcione, las rifas se construyen sobre una base sólida.

Las rifas siguen siendo el módulo de monetización prioritario, pero dependen de que exista correctamente:

- club;
- usuarios;
- permisos;
- configuración;
- auditoría;
- base de datos.

---

# 68. RESULTADO FINAL ESPERADO

El producto final deberá ser una plataforma SaaS:

```text
             PLATAFORMA
                  |
        +---------+---------+
        |                   |
      CLUB A              CLUB B
        |                   |
    Usuarios             Usuarios
    Socios               Socios
    Equipos              Equipos
    Finanzas             Finanzas
    Rifas                Rifas
    Eventos              Eventos
```

Cada club administra sus datos.

La plataforma administra la infraestructura.

El objetivo es que añadir el club número 100 no requiera crear otra aplicación.

---

# 69. RECOMENDACIÓN ESTRATÉGICA FINAL

No intentar competir inicialmente contra las plataformas deportivas más completas.

Nuestro posicionamiento inicial:

> "La forma sencilla de gestionar tu club y generar ingresos desde un único sitio."

Diferenciadores:

1. Autogestión.
2. Sencillez.
3. Club pequeño como usuario objetivo.
4. Rifas digitales.
5. Sorteos.
6. Comunicación.
7. Tesorería sencilla.
8. Socios y numeración.
9. Patrocinadores.
10. Arquitectura modular.

---

# 70. PRÓXIMO DOCUMENTO A CREAR

Antes del primer código, crear:

`docs/03_database.md`

con:

- esquema completo de PostgreSQL;
- tablas;
- columnas;
- tipos;
- PK;
- FK;
- índices;
- constraints;
- enums;
- RLS;
- políticas;
- triggers;
- funciones;
- seed de desarrollo.

Después:

`docs/06_roles_permissions.md`

Y después:

`docs/05_ui_design.md`

Solo después de esos tres documentos empezar el código Flutter.

FIN DE LA ARQUITECTURA MAESTRA
