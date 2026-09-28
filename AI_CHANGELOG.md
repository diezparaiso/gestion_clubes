## 2026-09-28 — GPT-5.6 LUNA — cierre UX de Perfil y Configuración

### Cambios
- `lib/features/auth/presentation/pages/profile_page.dart`
  - Reorganizada la pantalla de perfil.
  - Mejorados estados de error/guardado y adaptación móvil.
  - Añadidos autofill hints y navegación de teclado para contraseñas.
  - Mantiene el flujo existente de recuperación/cambio obligatorio.
- `lib/features/clubs/presentation/pages/club_settings_page.dart`
  - Cabecera responsive para pantallas estrechas.
  - La acción «Usuarios y permisos» pasa a disposición vertical en móvil.
- No se modifica Supabase remoto ni Payments/Stripe.

### Validación
Pendiente ejecutar `flutter analyze`, `flutter test` y validación visual Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — definición funcional del flujo de incorporación

### Cambios
- `lib/features/clubs/presentation/pages/platform_home_page.dart`
  - Añadida una sección pública «¿Cómo se incorpora un club?».
  - Se explican las cuatro etapas previstas: solicitud, revisión, alta del club y configuración de cobros.
  - Se aclara que los datos bancarios no se solicitan en la incorporación inicial.
- Creado `docs/FLUJO_INCORPORACION_CLUBES.md`.
  - Define el flujo funcional desde la solicitud pública hasta la activación.
  - Separa estado de solicitud y estado operativo del club.
  - Define la futura bandeja de soporte, revisión, alta, configuración y Stripe Connect.
- No se modifica Supabase remoto, migraciones, RPC ni Edge Functions.
- No se modifica Stripe, `club_payments` ni `club_payments_backend`.

### Validación
Pendiente ejecutar `flutter analyze`, `flutter test` y validación visual Web/Chrome después de estos cambios.

## 2026-09-28 — GPT-5.6 LUNA — cierre del flujo de entrada pública

### Cambios
- `lib/app/router.dart`
  - La landing `/` pasa a ser la entrada inicial de la aplicación.
  - Se mantiene como ruta pública y no requiere autenticación.
- `lib/features/auth/presentation/pages/login_page.dart`
  - El identificador de la plataforma permite volver a `/`.
  - Añadido **Volver a la plataforma**.
- `lib/features/clubs/presentation/pages/club_join_request_page.dart`
  - Añadido acceso **Plataforma** en la cabecera.
  - Tras la confirmación de la solicitud se vuelve a la landing pública.
- No se modifica Supabase remoto ni la infraestructura de pagos.

### Flujo resultante
`/` → landing → `/login` o `/solicitar-incorporacion`.
Desde login y solicitud se puede regresar a la landing.

### Validación
Pendiente ejecutar `flutter analyze`, `flutter test` y validación visual Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — landing pública de la plataforma

### Cambios
- Creado `lib/features/clubs/presentation/pages/platform_home_page.dart`.
  - Nueva portada pública de la plataforma.
  - Presenta de forma resumida Socios, Tesorería, Rifas y porras, Noticias/avisos, Patrocinadores y Web pública.
  - CTA **Incorporar mi club** hacia `/solicitar-incorporacion`.
  - CTA **Ya tengo acceso** hacia `/login`.
  - Enlace público a privacidad.
  - Diseño responsive para móvil, tablet y escritorio.
- Modificado `lib/app/router.dart`.
  - Añadida la ruta pública `/`.
  - La landing no requiere autenticación.
  - Se mantiene `/login` como acceso al área privada.
- No se modifica Supabase remoto.
- No se modifica Stripe, `club_payments` ni `club_payments_backend`.
- No se almacenan ni transmiten datos desde la landing.

### Arquitectura
La entrada pública queda separada de la web pública de cada club:
`/` → plataforma; `/club/:clubSlug` → club; rutas privadas → gestión autenticada.
La incorporación continúa inicialmente mediante `/solicitar-incorporacion`; el alta autónoma y Stripe Connect quedan para fases posteriores.

### Validación
Pendiente ejecutar `flutter analyze`, `flutter test` y validación visual Web/Chrome después de estos cambios.

## 2026-09-28 — GPT-5.6 LUNA — endurecimiento de la solicitud de incorporación

### Cambios
- `club_join_request_page.dart`
  - Añadido tipo de entidad.
  - Añadido sitio web opcional.
  - Añadida aceptación explícita de la información de privacidad.
  - Enlace a la política de privacidad existente.
  - La validación impide continuar sin aceptar la privacidad.
- Se mantiene el carácter frontend-only de esta fase.
- No se persisten datos ni se modifica Supabase remoto.
- No se solicitan datos bancarios.

### Arquitectura
La futura recepción real de la solicitud deberá aplicar consentimiento/información de privacidad, validación server-side y controles de acceso antes de almacenar los datos de contacto.

## 2026-09-28 — GPT-5.6 LUNA — primera fase de incorporación autónoma de clubes

### Cambios de arquitectura
- Se define una estrategia por fases para que los clubes puedan iniciar su incorporación sin intervención manual inmediata.
- Fase 1: solicitud pública de incorporación.
- Fase 2: cola persistente de solicitudes para soporte.
- Fase 3: alta autónoma completa con creación del espacio del club.
- Fase financiera: Stripe Connect para que Stripe recopile KYC y datos bancarios; la plataforma conservará únicamente el identificador de cuenta conectada y estados de capacidad.

### Cambios de código
- Creado `lib/features/clubs/presentation/pages/club_join_request_page.dart`.
  - Formulario público responsive.
  - Datos básicos del club y responsable.
  - Intereses funcionales.
  - Aviso explícito para no introducir datos bancarios.
  - Confirmación visual.
  - Esta fase no persiste ni envía datos todavía.
- Modificado `lib/app/router.dart`.
  - Nueva ruta pública `/solicitar-incorporacion`.
  - No requiere autenticación.
- Modificado `lib/features/auth/presentation/pages/login_page.dart`.
  - Añadido acceso directo «¿Quieres incorporar tu club? Solicitar incorporación».
- Creado `docs/ARQUITECTURA_INCORPORACION_CLUBES.md`.
  - Documenta modelo de datos futuro, estados, seguridad y separación de Stripe.

### Límites deliberados
- No se modifica Supabase remoto.
- No se crean migraciones/RPC/Edge Functions.
- No se toca Stripe, `club_payments` ni `club_payments_backend`.
- No se almacenan datos bancarios.
- La conexión real con soporte queda pendiente de backend.

### Validación
- Pendiente ejecutar `flutter analyze`, `flutter test` y validación visual Web/Chrome tras estos cambios.

## 2026-09-28 — GPT-5.6 LUNA — mejora del dashboard y acceso a la web pública

### Cambios realizados
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
  - Añadido acceso directo **Ver web pública** desde la cabecera del área privada.
  - El enlace resuelve el `slug` real del club mediante `ClubRepository.getClubById` y abre la ruta pública existente `/club/:clubSlug`.
  - Sustituido el saludo basado directamente en el email por una presentación más legible derivada de su parte local.
  - Sustituido el avatar estático `PM` por iniciales calculadas a partir del usuario.
  - La cabecera se distribuye con `Wrap` para evitar desbordamientos en móvil/tablet.
  - Se mantienen los permisos y las rutas privadas existentes.
- No se modifican migraciones, RPC, políticas ni Supabase remoto.
- No se modifican Stripe, `club_payments` ni `club_payments_backend`.

### Estado
Dashboard con separación más clara entre área privada de gestión y web pública del club. Pendiente validación visual/compilación en Flutter Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — acceso consistente al login en rifas públicas

### Cambios realizados
- `lib/features/raffles/presentation/pages/public_raffle_page.dart`
  - Añadido botón **Acceder** en la cabecera de la rifa pública.
  - Reutiliza la ruta existente `/login`.
  - No modifica la reserva simulada ni integra pagos reales.
- No se modifican migraciones, RPC, políticas ni Supabase remoto.
- No se modifican Stripe, `club_payments` ni `club_payments_backend`.

### Estado
La navegación pública dispone ahora de acceso al login desde home, noticias, eventos, patrocinadores y rifas públicas. Pendiente validación visual/compilación en Flutter Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — consistencia de navegación pública

### Cambios realizados
- `lib/features/events/presentation/pages/public_events_page.dart`
  - Añadido botón **Acceder** en la cabecera pública.
- `lib/features/news/presentation/pages/public_posts_page.dart`
  - Añadido botón **Acceder** en la cabecera pública.
- `lib/features/sponsors/presentation/pages/public_sponsors_page.dart`
  - Añadido botón **Acceder** en la cabecera pública.
- Las tres páginas reutilizan la ruta existente `/login`.
- No se modifican migraciones, RPC, políticas ni Supabase remoto.
- No se modifican Stripe, `club_payments` ni `club_payments_backend`.

### Revisión adicional
- Se ha comprobado que el modelo actual de equipos no dispone de una consulta pública equivalente a las de noticias/eventos.
- Las tablas `teams` y `seasons` tienen políticas de lectura para usuarios autenticados, por lo que no se ha creado una falsa página pública de equipos que dependa de datos que un visitante anónimo no puede consultar.
- La publicación pública de equipos queda pendiente de diseñar/validar dentro del modelo de acceso de Supabase, sin tocarlo en esta ronda.

### Estado
- Navegación pública: coherente con acceso al login desde home, noticias, eventos y patrocinadores.
- Equipos públicos: pendiente por dependencia del modelo de acceso de datos.
- Pendiente validación visual/compilación en Flutter Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — actualidad real en la home pública

### Cambios realizados
- lib/features/clubs/presentation/pages/public_club_page.dart
  - La home pública ahora consulta las noticias y eventos públicos existentes.
  - Muestra una sección «Actualidad» con la última noticia y el próximo evento cuando existen.
  - Los bloques enlazan a las páginas públicas completas de noticias y eventos.
  - No se duplica lógica de acceso a datos: reutiliza los repositorios existentes.
- No se han modificado migraciones, RPC, políticas ni Supabase remoto.
- No se han modificado Stripe, club_payments ni club_payments_backend.

### Estado
- Home pública: portada + navegación + actualidad real del club.
- Pendiente validación visual/compilación en Flutter Web/Chrome.

## 2026-09-28 — GPT-5.6 LUNA — nueva home pública del club

### Cambios realizados
- lib/features/clubs/presentation/pages/public_club_page.dart
  - La página pública pasa a ser la home principal del club.
  - Cabecera pública con navegación y botón **Acceder** arriba a la derecha.
  - Hero con nombre del club y accesos a noticias/eventos.
  - Bloques públicos para Noticias, Eventos, Equipos y Patrocinadores.
  - Enlaces a web y redes sociales existentes.
  - Diseño responsive para móvil, tablet y escritorio.
  - Mantiene las rutas públicas existentes y no expone gestión interna.
- El botón **Acceder** dirige a /login; la autenticación existente continúa llevando al área privada.
- No se han modificado migraciones, RPC, políticas ni Supabase remoto.
- No se han modificado Stripe, club_payments ni club_payments_backend.

### Estado
- Home pública del club: cerrada a nivel de frontend.
- Pendiente validación visual en Flutter Web/Chrome y con datos reales de Supabase staging.

## 2026-09-28 — GPT-5.6 LUNA — cierre de Perfil y protección de cuenta

### Cambios realizados
- lib/features/auth/presentation/pages/profile_page.dart
  - Estado de guardado visible.
  - Errores de cambio de contraseña mostrados dentro del formulario.
  - Mantiene validación mínima de 8 caracteres y confirmación.
  - Responsive mediante contenedor máximo existente.
- lib/app/router.dart
  - Perfil y rutas autenticadas quedan protegidos por sesión.
  - Mis rifas requiere sesión mediante dashboard_view.
  - Se mantiene acceso público únicamente para rutas públicas explícitas.
- No se han modificado migraciones, RPC, políticas ni Supabase remoto.
- No se han modificado Stripe, club_payments ni club_payments_backend.

### Estado
- Perfil/cambio de contraseña y protección de rutas de cuenta: cerrado a nivel de frontend.
- Sigue pendiente validación real con Supabase staging y ejecución de flutter analyze/tests.

## 2026-09-28 — GPT-5.6 LUNA — cierre UX del módulo de Rifas (sin pagos reales)

### Cambios realizados
- lib/features/raffles/presentation/pages/raffles_page.dart
  - Cabecera responsive.
  - Buscador y filtro de estado adaptados a pantallas estrechas.
  - Se mantienen permisos raffles_manage.
- lib/features/raffles/presentation/pages/raffle_detail_page.dart
  - Cabecera responsive.
  - Validación del ganador manual de Cesta para aceptar solo números participantes y confirmados.
  - Se mantiene el sorteo criptográficamente aleatorio existente para Sorteo puro.
- lib/features/raffles/presentation/pages/my_raffles_page.dart
  - Ajuste UX de cabecera y estados vacíos existentes.
- lib/features/raffles/presentation/pages/public_raffle_page.dart
  - La rifa queda visualmente cerrada cuando está finalizada/cancelada/agota números o supera su fecha final.
  - Se impide seleccionar números y reservar cuando está cerrada.
  - Se mantiene la reserva simulada; el pago real continúa bloqueado.
- No se han modificado migraciones, RPC, políticas ni Supabase remoto.
- No se ha modificado club_payments, club_payments_backend ni Stripe.

### Estado
- Frontend de Rifas: cerrado en lo que no depende de pagos reales.
- Checkout, suscripciones, webhooks, recibos PDF/email e idempotencia Stripe permanecen deliberadamente pendientes.
- Falta validar Flutter Web/Chrome, responsive real y rifas contra Supabase staging.

## 2026-09-28 — GPT-5.6 LUNA — cierre del flujo Equipos → Jugadores → Personal

### Cambios realizados
- lib/features/players/presentation/pages/team_players_page.dart: búsqueda por nombre/dorsal, filtro de inactivos, cabecera responsive, estados vacíos y refresco manual.
- lib/features/players/presentation/pages/team_players_page.dart: corregida la liberación de todos los TextEditingController del diálogo de edición.
- lib/features/staff/presentation/pages/team_staff_page.dart: búsqueda por persona/cargo, filtro de inactivos, cabecera responsive, estados vacíos y refresco manual.
- Se mantiene el flujo existente Equipos → Plantilla → Personal y los permisos players_manage / teams_manage.
- No se han modificado migraciones, RPC, políticas ni Supabase remoto.
- No se ha modificado club_payments, club_payments_backend ni Stripe.

### Estado
- Flujo frontend Equipos → Jugadores → Personal: cerrado a nivel de UI/código.
- Sigue pendiente la validación real de RLS/RPC en staging y la ejecución de flutter analyze/tests en un entorno local/CI.

## 2026-09-28 — GPT-5.6 LUNA — cierre del módulo de notificaciones

### Objetivo
Cerrar el centro de notificaciones del usuario sin tocar Supabase remoto, migraciones, RPC, Stripe ni los módulos de pagos.

### Cambios
1. `lib/features/notifications/presentation/pages/notifications_page.dart`
   - Búsqueda y filtro de no leídas adaptados a pantallas estrechas.
   - Marcar una notificación como leída y marcar todas como leídas con manejo visible de errores.
   - Mantiene el acceso protegido por `notifications_view`.
2. `lib/features/notifications/data/repositories/notification_delivery_repository.dart`
   - El modo demo ahora conserva el estado de lectura durante la sesión.
   - Se pueden probar realmente las acciones de marcar una/todas como leídas sin Supabase.
   - El comportamiento conectado a Supabase/RPC existente no se modifica.

### Alcance y seguridad
- No se modifican migraciones Supabase.
- No se ejecuta ninguna operación sobre Supabase remoto.
- No se modifican RPC.
- No se modifica Stripe ni ningún módulo de pagos.

### Estado
Centro de notificaciones del usuario cerrado a nivel de frontend. La validación de RLS/RPC y notificaciones reales queda para staging/infraestructura externa.

## 2026-09-28 — GPT-5.6 LUNA — cierre del módulo de patrocinadores

### Objetivo
Cerrar el módulo de patrocinadores de extremo a extremo sin tocar Supabase remoto, migraciones, RPC, Stripe ni los módulos de pagos.

### Cambios
1. `lib/features/sponsors/presentation/pages/sponsors_page.dart`
   - Integrada la navegación común del club.
   - Gestión de alta/edición/visibilidad limitada en UI al presidente.
   - Mejorado el comportamiento responsive de tarjetas y acciones.
   - Validación de importe anual y fechas del contrato.
   - Los errores al cambiar visibilidad dejan de ocultarse silenciosamente.
2. `lib/features/sponsors/presentation/pages/public_sponsors_page.dart`
   - Nueva página pública para mostrar patrocinadores activos/publicables.
   - Enlace opcional a la web del patrocinador.
   - Usa el repositorio existente y su RPC pública cuando Supabase está configurado.
3. `lib/features/auth/application/auth_controller.dart`
   - Añadido `sponsors_manage` únicamente al rol `club_president`.
   - No se cambia ninguna tabla ni política remota.
4. `lib/app/router.dart`
   - Ruta interna `/sponsors` protegida por `sponsors_manage`.
   - Ruta pública `/club/:clubSlug/sponsors`.
5. `lib/features/dashboard/presentation/widgets/club_navigation_app_bar.dart`
   - Añadido Patrocinadores a la navegación común.
6. `lib/features/dashboard/presentation/pages/dashboard_page.dart`
   - Añadido Patrocinadores a navegación desktop/mobile.
7. `lib/features/clubs/presentation/pages/public_club_page.dart`
   - Añadido acceso público a Patrocinadores.

### Alcance y seguridad
- No se modifican migraciones Supabase.
- No se ejecuta ninguna operación sobre Supabase remoto.
- No se modifica `club_payments`.
- No se modifica `club_payments_backend`.
- No se modifica Stripe.
- No se introducen secretos.
- La integración reutiliza las consultas/RPC existentes del repositorio de patrocinadores.

### Estado
El módulo queda integrado en rutas, navegación y escaparate público. La validación contra RLS/RPC real de Supabase queda, como el resto de infraestructura externa, pendiente de staging.
## 2026-09-28 — GPT-5.6 LUNA — bloque responsive sin pagos

### Objetivo
Avanzar el desarrollo de `gestion_clubes` sin tocar Supabase remoto ni integrar todavía los módulos externos de pagos.

### Rama de trabajo
- `ai/non-payments-development`
- PR: `#1` — Responsive UI improvements without payments/Supabase changes.
- Base: `main`.

### Archivos modificados
1. `lib/features/members/presentation/pages/members_page.dart`
   - Cabecera convertida de `Row` a `Wrap`.
   - Buscador y filtros convertidos a distribución responsive.
   - Se evita el desbordamiento horizontal en anchuras reducidas.
2. `lib/features/finance/presentation/pages/finance_page.dart`
   - Cabecera convertida a `Wrap`.
   - Buscador y filtros adaptados a anchuras reducidas.
   - No se altera el cálculo financiero ni las consultas existentes.
3. `lib/features/events/presentation/pages/events_page.dart`
   - Cabecera y acciones convertidas a `Wrap`.
   - Buscador/filtro público adaptados a móvil y tablet.
   - Se conserva la generación del enlace público existente.
4. `lib/features/teams/presentation/pages/teams_page.dart`
   - Cabecera y acciones convertidas a `Wrap`.
   - Buscador/filtro de inactivos adaptados a anchuras reducidas.

### Seguridad de alcance
- No se modifican migraciones Supabase.
- No se ejecuta ninguna operación sobre Supabase remoto.
- No se modifica `club_payments`.
- No se modifica `club_payments_backend`.
- No se modifica Stripe.
- No se introducen secretos.
- Los cambios son exclusivamente de presentación/responsive.

### Siguiente trabajo previsto
Continuar cerrando funcionalidades y calidad del frontend que no dependan de pagos, Supabase remoto o servicios externos. Cada nueva intervención deberá documentar los archivos afectados y mantener el marcador de autoría IA.

### 2026-09-27 — GPT-5.6 LUNA — cierre de revisión de selección de club
- Revisada la carga de múltiples clubes mediante membresías activas y la selección del club junto con su rol.
- Añadida cobertura de `ClubAccess` para identidad del club y etiquetas de rol, incluyendo fallback para roles futuros.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre del ciclo de consentimiento publicitario
- Añadida página pública `/privacy` con información resumida sobre privacidad, almacenamiento local y publicidad.
- El aviso publicitario enlaza directamente a privacidad antes de aceptar o rechazar.
- La preferencia publicitaria puede retirarse/revisarse desde la página pública y el estado local del servicio puede reiniciarse.
- El texto se mantiene como información técnica provisional y no se presenta como sustituto del texto jurídico definitivo ni de una CMP certificada.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de recuperación de contraseña
- Añadido el flujo de recuperación desde Login mediante `resetPasswordForEmail`.
- La sesión `passwordRecovery` lleva al usuario a `/profile/password` sin exigir la contraseña anterior.
- Tras establecer la nueva contraseña, la sesión de recuperación se cierra y el usuario vuelve al inicio de sesión.
- Se mantienen las reglas de `must_change_password` para cuentas creadas con contraseña inicial.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — ajuste de lectura del histórico mensual
- El histórico de resultados mensuales deja de consultar directamente `profiles`, evitando depender de `members_view` cuando el usuario solo dispone de `raffles_view`.
- Se conserva el identificador del ganador en el resultado y el acceso al histórico queda alineado con el RLS de `raffle_monthly_results`.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre funcional de gestión de rifas mensuales
- El detalle de rifas mensuales mantiene histórico de resultados y registro manual mediante la RPC existente `register_monthly_result`.
- Las acciones de sorteo y registro de resultados quedan visibles solo con `raffles_manage`; la consulta del histórico permanece disponible para `raffles_view`.
- No se ejecuta ninguna migración sobre Supabase remoto.
- Payments/Stripe permanece sin cambios.

### 2026-09-27 — GPT-5.6 LUNA — revisión de RLS y RPC heredadas
- Corregida `038_permissions_rls_alignment.sql`: la propiedad del participante en `raffle_tickets` usa `buyer_profile_id`, que es la columna real.
- Añadida `040_access_rpc_permissions.sql`: `invite_club_member` deja de depender de `is_club_manager` y exige `access_manage`, evitando que un secretario pueda saltarse la restricción de gestión de accesos.
- Verificadas contra el esquema real las tablas de temporadas, equipos, jugadores, personal, tesorería, rifas, noticias y eventos.
- No se ejecuta ninguna migración sobre Supabase remoto.
- Payments/Stripe permanece sin cambios.

### 2026-09-27 — GPT-5.6 LUNA — cierre de lecturas RLS por permisos view
- Añadida `039_permissions_view_rls.sql`.
- Las lecturas de socios, equipos, jugadores, staff, rifas, noticias, eventos y notificaciones quedan limitadas a sus permisos `*_view`.
- Los accesos de club_memberships quedan limitados al propio acceso o a `access_manage`.
- No se ejecuta ninguna migración en Supabase remoto.

### 2026-09-27 — GPT-5.6 LUNA — alineación inicial de RLS con permisos view/manage
- Añadida la migración `038_permissions_rls_alignment.sql`.
- Socios, equipos, jugadores, tesorería, rifas, noticias, eventos y configuración usan `has_club_permission` en sus operaciones protegidas.
- La lectura de tesorería deja de depender de `is_club_manager` y pasa a respetar `finance_view`.
- Jugadores pasan a respetar `players_manage`; staff mantiene `teams_manage` porque no existe un permiso `staff_manage`.
- Gestión de accesos y auditoría quedan bajo `access_manage`.
- No se ejecuta la migración en Supabase remoto.
- Payments/Stripe permanece sin cambios.

### 2026-09-27 — GPT-5.6 LUNA — cierre de jugadores, staff, noticias y configuración
- Alta y edición de jugadores condicionadas a `players_manage`, manteniendo la consulta para `players_view`.
- Alta y edición de personal condicionadas a `teams_manage`, sin crear un permiso nuevo mientras el modelo RLS actual usa `is_club_manager`.
- Noticias: creación, edición y borrado condicionados a `news_manage`.
- Configuración: edición condicionada a `club_settings_manage` y gestión de accesos a `access_manage`.
- Navegación superior actualizada para usar permisos `*_view`/gestión en lugar de una lista fija de roles.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — separación inicial de permisos view/manage en pantallas
- Ocultadas las acciones de alta/edición/cobro en Socios cuando el rol no tiene `members_manage`.
- Ocultada el alta de movimientos en Tesorería sin `finance_manage`.
- Ocultada la creación de eventos sin `events_manage`.
- Ocultada la creación de rifas sin `raffles_manage`.
- Ocultadas alta, edición, activación/desactivación y gestión de temporadas de Equipos sin `teams_manage`.
- Se mantiene el acceso de consulta para los roles que solo tienen permisos `*_view`.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de revocación y endurecimiento del alta de accesos
- Añadida la migración `037_revoke_member_access.sql` con RPC segura para revocar accesos activos y conservar siempre al menos un presidente activo.
- La revocación queda auditada y protegida por el permiso `access_manage`.
- Endurecida `manage-club-user`: el backend de alta exige explícitamente que el actor sea presidente, alineándolo con la restricción de la UI y la migración 032.
- No se ejecuta ninguna migración ni Edge Function en Supabase remoto.
- Payments/Stripe permanece sin cambios.

### 2026-09-27 — GPT-5.6 LUNA — cierre inicial de permisos en navegación y rutas
- Corrección inmediata de una duplicación de `selectedIndex` introducida en la navegación móvil durante este bloque.
- Añadido el mapa de permisos por rol en la aplicación, alineado con la migración 032.
- El router bloquea el acceso directo por URL a módulos que el rol no puede consultar.
- Dashboard, sidebar y navegación móvil ocultan secciones no permitidas.
- Las acciones rápidas de alta/gestión se muestran solo cuando existe el permiso correspondiente.
- No se ejecuta ninguna migración en Supabase remoto.

### 2026-09-27 — GPT-5.6 LUNA — cierre del último warning del analyzer
- Eliminado el campo `_manualSaving` que ya no tenía lecturas; el flujo de elección manual de ganador reutiliza `_drawing`, evitando estado duplicado.
- El cambio mantiene el comportamiento de bloqueo durante el guardado y no toca Supabase remoto ni Payments.

### 2026-09-27 — GPT-5.6 LUNA — corrección final del analyzer tras validación local
- Restaurado `_manualSaving` en el detalle de rifas, que seguía siendo utilizado por el flujo de elección manual de ganador.
- Corregida la última composición de texto del selector de mes y el bloque `if` del diálogo de gestión de accesos.
- La corrección mantiene el alcance funcional y no toca Supabase remoto ni Payments.

### 2026-09-27 — GPT-5.6 LUNA — limpieza final del analyzer
- Corregidos los avisos de lint restantes en gestión de accesos, navegación y páginas de rifas.
- Sustituidos `DropdownButtonFormField.value` por `initialValue` donde correspondía y simplificados concatenados de cadenas mediante interpolación.
- Eliminado el campo `_manualSaving` sin uso y corregido el spread nullable de acciones de la barra de navegación.
- Sin cambios de esquema, Supabase remoto ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — correcciones tras validación local de Flutter
- Corregidas las llamadas a Supabase Auth para usar los parámetros nombrados exigidos por el SDK actual.
- Reordenadas las directivas de imports/interoperabilidad del banner AdSense Web para cumplir el analizador Dart.
- Corregida la ruta relativa de SupabaseService en my_raffles_page.dart.
- No se ejecuta ninguna migración en Supabase remoto y no se modifica Payments/Stripe.

### 2026-09-26 — GPT-5.6 LUNA — rifa mensual y trazabilidad de renovaciones
- Añadida modalidad `mensual` al modelo de rifas.
- La configuración mensual permite fijar el día del ciclo mensual (1–28).
- Preparadas tablas para suscripciones mensuales y resultados históricos por mes.
- El número queda vinculado al socio/perfil y no puede duplicarse dentro de la misma rifa mensual.
- Preparada RPC para registrar cada resultado mensual, importe del premio, ganador y observaciones.
- El resultado mensual genera una notificación dirigida al ganador.
- La estructura contempla IDs de cliente/suscripción del proveedor de pagos para futuras renovaciones automáticas.
- La renovación automática real queda pendiente de activar el backend/proveedor de pagos recurrentes; no se simula como si estuviera funcionando.
- También queda pendiente conectar el comprobante de pago con un proveedor de correo transaccional real.
- No se ejecutan migraciones en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — modalidades de rifas
- Añadidas las modalidades `cesta` y `sorteoPuro`.
- La configuración permite indicar modalidad, cantidad de números, precio y fecha final.
- Los números siguen seleccionándose individualmente desde el enlace público.
- Los números ocupados se muestran explícitamente en gris en el cuadrante público.
- Añadida unicidad de `raffle_id + number` para impedir números duplicados a nivel de base de datos.
- En Cesta, el ganador solo puede fijarse después de la fecha final y debe corresponder a una participación confirmada.
- En Sorteo puro, el ganador se selecciona mediante bytes aleatorios criptográficos de `pgcrypto`, con rechazo para evitar sesgo por módulo.
- El resultado queda guardado en la rifa y auditado.
- En Cesta se crea una notificación para el perfil cuyo email coincide con el participante ganador.
- Migración preparada: `034_raffle_types_and_secure_draw.sql`. No ejecutada remotamente.
- Payments/Stripe permanece sin cambios.

### 2026-09-26 — GPT-5.6 LUNA — perfil y cambio de contraseña
- Añadido perfil de usuario con cambio de contraseña.
- Los usuarios creados con contraseña inicial quedan obligados a cambiarla antes de acceder a la gestión.
- El requisito se controla mediante `profiles.must_change_password` y se libera al completar correctamente el cambio.
- Añadida ruta `/profile` y ruta protegida `/profile/password`.
- Añadido acceso a Mi perfil desde la navegación superior.
- No se guardan contraseñas en la base de datos ni en logs.

### 2026-09-26 — GPT-5.6 LUNA — navegación superior por rol
- Añadida barra `ClubNavigationAppBar` reutilizable para las pantallas de gestión.
- Todas las pantallas principales incorporan botón de inicio y menú superior de navegación.
- El menú muestra las áreas disponibles según el rol seleccionado y mantiene visible el rol actual.
- Añadida navegación también a jugadores, personal de equipo y detalle de rifas.
- No se modifica la navegación pública ni Payments/Stripe.

### 2026-09-26 — GPT-5.6 LUNA — cierre inicial del módulo de accesos
- Añadida `club_access_management_page.dart`: listado de accesos activos, alta de usuario mediante Edge Function, cambio de rol y revocación.
- Añadida la ruta `/settings/access` y acceso directo desde Configuración.
- Añadida `033_change_member_role.sql` con RPC protegida por el permiso `access_manage`.
- La contraseña inicial se solicita solo en el formulario y se marca `must_change_password` desde la Edge Function; no se guarda en la base de datos ni en logs.
- Las migraciones y la Edge Function siguen pendientes de despliegue en Supabase remoto.
- No se modifica Payments/Stripe.
- Marcado como `MODIFICADO POR GPT-5.6 LUNA` en los archivos tocados.

# AI CHANGELOG — gestión_clubes

This file is the permanent handoff log between AI assistants working on this repository.

## Identification rule

- Every change made directly by ChatGPT must be marked in the touched source file with `MODIFICADO POR GPT-5.6 LUNA`.
- Claude or another assistant must add its own explicit marker when it modifies a file.
- Do not remove previous AI markers. If a section is substantially rewritten, preserve the previous marker in the history/comments.
- Git commit messages should also identify the AI when practical.

## Working rules requested by Juanlu

- Do NOT modify the live Supabase database from this workflow. Repository migrations may be created or updated, but they are **not executed against the live Supabase project** from this workflow.
- Supabase migrations are part of the repository and may be added when required by the planned application architecture, integrity, RLS or data model. Their remote application remains a separate deployment step.
- Do NOT modify the Stripe/payment implementation in gestion_clubes unless that integration is explicitly scheduled. The separate payments project remains independent until integration is planned.
- If a requested feature requires a schema, RLS, storage policy, Edge Function or payment change, document the change and keep live deployment separate from code changes.

### 2026-09-26 — GPT-5.6 LUNA — documentación de reglas de trabajo
- Se corrige la antigua restricción documental que prohibía crear o modificar migraciones, porque el repositorio ya contiene migraciones 020–024 creadas durante este desarrollo.
- Se mantiene la separación entre cambios de código/migraciones del repositorio y la aplicación de esos cambios sobre el Supabase remoto.
- Stripe/pagos siguen fuera de gestion_clubes hasta que se programe explícitamente su integración.

## 2026-09-26 — GPT-5.6 LUNA — continued implementation

### 2026-09-26 — GPT-5.6 LUNA — arquitectura de gestión de accesos y permisos
- Añadida `supabase/migrations/032_club_access_permissions.sql`: marca cuentas que deben cambiar su contraseña inicial y define permisos por rol mediante `club_role_permissions` y `has_club_permission`.
- Añadida `supabase/functions/manage-club-user/index.ts`: backend seguro para que un presidente/secretario pueda crear o activar una cuenta Auth, asignarle email, contraseña inicial, datos básicos y rol sin exponer la service role key al navegador.
- La interfaz visual de Configuración queda pendiente de completar porque la escritura de esa modificación fue bloqueada por el control de seguridad de la sesión; no se dejó un cambio parcial.
- Ninguna migración ni Edge Function se ha desplegado/ejecutado sobre Supabase remoto desde este flujo.
- Stripe/payment implementation remains untouched.



### 2026-09-26 — GPT-5.6 LUNA — acceso a clubes existentes y rol real
- `lib/features/auth/application/auth_controller.dart`: añade la carga de clubes con membresía activa, selección del club y conservación del rol `club_role` en el estado de autenticación.
- `lib/features/clubs/presentation/pages/club_onboarding_page.dart`: muestra los clubes existentes del usuario y permite entrar directamente en ellos; mantiene la opción de crear un club nuevo.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`: sustituye el texto fijo "Presidente" por el rol real del acceso seleccionado.
- No se modifica el esquema ni se ejecuta nada sobre Supabase remoto.
- Stripe/payment implementation remains untouched.



- Previous work recorded above is preserved.
- `supabase/migrations/021_raffle_ticket_integrity.sql`
  - Added validation for raffle ticket range and club ownership.
- `supabase/migrations/022_raffle_number_range_consistency.sql`
  - Corrected an existing off-by-one inconsistency: public reservations previously accepted 0..total_numbers-1 while the application and new integrity trigger use 1..total_numbers.
  - Tightened the database check to require ticket numbers >= 1.
  - Replaced the public reservation function so valid numbers are 1..total_numbers.
- Important: these migration files are repository changes only and have not been executed against live Supabase.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — sponsor demo-mode robustness
- `lib/features/sponsors/data/repositories/sponsor_repository.dart`
  - Made the Supabase client nullable and only accesses `Supabase.instance.client` when Supabase is configured.
  - Prevents the demo/offline mode from requiring an initialized Supabase client.
- No database schema change.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — event date/time integrity
- `lib/features/events/presentation/pages/events_page.dart`
  - Replaced the fixed `now + 7 days` event timestamp with selectable start/end date and time.
  - Prevents saving an event whose end is not after its start.
- No database schema change.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — notification target integrity
- `supabase/migrations/023_notification_target_integrity.sql`
  - Adds the missing `members` target handling.
  - Uses the actual schema roles (`club_president`, `club_secretary`) for managers.
  - Restricts recipients to active memberships/staff.
  - Keeps delivery deduplication via the existing unique constraint.
- Repository migration only; live Supabase has not been executed from this workflow.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — news CRUD completion
- `lib/features/news/data/repositories/post_repository.dart`: añade actualización y borrado, valida título/contenido y mantiene coherencia de `published_at` según estado.
- `lib/features/news/presentation/pages/posts_page.dart`: añade edición, borrado confirmado y soporte visual para borradas/archivadas.
- Sin cambios de esquema; live Supabase no ejecutado desde este workflow.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle UI consistency
- `lib/features/raffles/presentation/pages/public_raffle_page.dart`: corrige la cuadrícula pública para ofrecer exactamente los números 1..total_numbers, coherente con la validación de Supabase.
- `lib/features/raffles/presentation/pages/raffles_page.dart`: valida que precio y cantidad de números sean mayores que cero antes del alta.
- Sin cambios de esquema en este bloque. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — player club_id integrity
- `lib/features/players/data/repositories/player_repository.dart`: corrige el alta para informar `club_id` tanto en `players` como en `team_players`, y limita la reutilización de un jugador al club activo.
- `lib/features/players/presentation/pages/team_players_page.dart`: pasa el `club_id` de la sesión al repositorio.
- Se trata de una corrección de datos obligatorios ya existentes; no requiere cambios de esquema.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle creation invariants
- `lib/features/raffles/data/repositories/raffle_repository.dart`: valida título, precio, rango de números y fecha de finalización antes de crear una rifa.
- `lib/features/raffles/presentation/pages/raffles_page.dart`: muestra los errores de validación al usuario.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — public content polish
- lib/features/events/presentation/pages/public_events_page.dart: muestra fecha y hora de inicio y fin usando los datos reales del evento.
- lib/features/news/presentation/pages/public_posts_page.dart: muestra image_url cuando existe, manteniendo el contenido público basado en el RPC existente.
- lib/features/raffles/data/repositories/raffle_repository.dart: corrige una inserción accidental de validaciones de creación dentro de getPublicRaffle; las validaciones quedan únicamente en createRaffle.
- Sin cambios de esquema en este bloque. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — player assignment security
- lib/features/players/data/repositories/player_repository.dart: valida antes del alta que el equipo indicado pertenece al club activo; evita asignaciones cruzadas entre clubes desde el cliente.
- No requiere cambio de esquema. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle activation flow
- `lib/features/raffles/data/repositories/raffle_repository.dart`: las nuevas rifas pasan a `active` al crearse, porque la interfaz actual no ofrece una acción separada para activarlas y el RPC público solo expone rifas activas.
- Usa únicamente la columna `status` existente; no requiere cambio de esquema.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — simple public raffle sharing
- `lib/features/raffles/data/repositories/raffle_repository.dart`: carga el `slug` público y el `club_slug` existentes para poder construir el enlace público de cada rifa desde la gestión.
- `lib/features/raffles/presentation/pages/raffle_detail_page.dart`: añade una acción sencilla para copiar el enlace público y pegarlo después en WhatsApp u otro canal.
- No se añade un sistema de WhatsApp ni nuevas tablas/endpoints.
- El pago real de la participación sigue separado del flujo actual; no se modifica Stripe/payment en este bloque.


### 2026-09-26 — GPT-5.6 LUNA — public club link sharing
- lib/features/clubs/presentation/pages/club_settings_page.dart: añadido botón simple para copiar el enlace público del club y corregida la anotación @override duplicada existente.
- No se ha creado integración directa con WhatsApp.
- El enlace queda preparado para compartir externamente.
- Pagos/Stripe no modificados.
- La función backend draw_raffle_random fue verificada en 009_raffle_draws.sql; no se modifica en este bloque.


### 2026-09-26 — GPT-5.6 LUNA — public content link sharing
- lib/features/events/presentation/pages/events_page.dart: botón simple para copiar el enlace público de la agenda del club.
- lib/features/news/presentation/pages/posts_page.dart: botón simple para copiar el enlace público de noticias.
- Se reutilizan las rutas públicas existentes; no se crea integración con WhatsApp ni backend adicional.
- Pagos/Stripe no modificados.

### 2026-09-26 — GPT-5.6 LUNA — repair after branch update
- Repaired the public events page string literal that caused the Dart parser errors.
- Repaired the post repository validation exception so it is valid with the current SDK.
- Public raffle/router analyzer errors were reviewed; the reported router error is a cascade from the public raffle page analyzer failure, while the fetched branch source is structurally valid. No payment/Stripe changes.


### 2026-09-26 — GPT-5.6 LUNA — repair public raffle imports
- Fixed a malformed literal \
 sequence at the beginning of `public_raffle_page.dart` that commented out the Flutter imports and caused the large analyzer cascade, including the router type error.
- Fixed the non-const `AuthException` invocation in `post_repository.dart`.
- No payment/Stripe changes and no live Supabase execution.


### 2026-09-26 — GPT-5.6 LUNA — final analyzer error repair
- Removed an invalid `const StateError` invocation in `post_repository.dart`.
- The remaining analyzer messages are informational/warnings only and are not blocking errors.

### 2026-09-26 — GPT-5.6 LUNA — finance balance integrity
- `lib/features/finance/presentation/pages/finance_page.dart`: el saldo ya no usa un valor fijo en la interfaz; toma el saldo inicial mediante `getOpeningBalance` del repositorio y suma/resta los movimientos actuales.
- El alta de movimientos rechaza importes cero o negativos antes de guardar.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — staff assignment integrity
- team_staff_repository.dart valida que el equipo pertenece al club activo antes de asignar personal.
- Evita asignaciones cruzadas entre clubes sin cambiar el esquema de Supabase.
- Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — team and player integrity
- team_repository.dart valida que la temporada pertenece al club activo al crear o editar un equipo.
- player_repository.dart verifica la existencia del equipo antes de editar una asignación de jugador.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — team form validation
- team_repository.dart valida nombres de temporada/equipo y categoría antes de guardar.
- La edición de equipos comprueba la pertenencia de la temporada al club activo.
- Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — analyzer cleanup
- sponsor_repository.dart elimina aserciones `!` redundantes tras comprobar el cliente Supabase.
- team_staff_repository.dart y post_repository.dart usan interpolación de cadenas donde correspondía.
- Cambios únicamente de código Dart; sin cambios de esquema ni pagos.

### 2026-09-26 — GPT-5.6 LUNA — analyzer lint cleanup continued
- Eliminados los avisos `use_build_context_synchronously` de copia de enlaces públicos en club y rifas.
- Corregido el formato de fechas de socios mediante interpolación.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad de asignaciones de equipo
- Endurecida la edición de jugadores y personal: ahora se verifica que el equipo pertenece al club activo antes de modificar la asignación.
- La pantalla de edición obtiene el `clubId` de la sesión antes de guardar.
- Sin cambios de esquema Supabase ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — gestión completa de roles de miembros
- Añadidos `parent_guardian` y `follower` al selector de invitación, ya soportados por el enum `club_role` y por el selector de cambio de rol.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación financiera adicional
- Reforzada la validación del repositorio de tesorería: club activo obligatorio, descripción no vacía e importe finito y mayor que cero.
- El alta Supabase reutiliza la descripción normalizada y mantiene la selección de cuenta financiera activa filtrada por `club_id`.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación de eventos
- El repositorio de eventos valida club activo, título y descripción obligatorios y que `end_at` sea posterior a `start_at` antes del alta.
- Normaliza título, descripción y ubicación antes de persistir.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación de socios
- El alta y edición de socios valida club activo y número de socio positivo.
- El alta valida nombre, apellidos y email; la edición valida que renovación y baja no sean anteriores al alta.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — domicilio postal de socios
- Se confirma que la versión anterior no permitía introducir dirección postal del socio.
- Añadidos a `memberships`: dirección, código postal, localidad, provincia y país.
- El alta y edición de socios ya permiten introducir y guardar estos datos.
- Añadida migración `024_member_postal_address.sql`; queda pendiente de aplicar en el Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — integridad de miembros del club
- El repositorio de miembros valida club activo, email y roles antes de llamar a Supabase.
- Se normalizan los emails a minúsculas.
- Se evita acceder al cliente Supabase cuando la aplicación está en modo demo.
- No se modifica el esquema ni el sistema de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — validación de reservas públicas de rifas
- El cliente valida enlace, cantidad de números, duplicados, números positivos, nombre y email antes del RPC.
- Normaliza slug, nombre, email y teléfono antes de reservar.
- No se modifica el sistema de pagos.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de eventos y noticias
- Los repositorios validan club activo y slug público antes de consultar datos.
- El alta de noticias valida también el club antes de persistir.
- Se endurece la acción de copiar el enlace público de agenda frente a cambios de contexto asíncronos.
- Sin cambios de esquema ni de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de miembros del club
- Las consultas de miembros validan club_id y el modo Supabase sin cliente disponible.
- Los diálogos de cambio de rol e invitación no ejecutan setState si el diálogo ya fue desmontado durante una operación asíncrona.
- Sin cambios de esquema ni de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de rifas y tesorería
- Se reparó el repositorio de rifas, que había quedado con contenido duplicado/incompleto durante el bloque anterior.
- Las participaciones y el sorteo pasan a validar el club activo antes de operar sobre la rifa.
- Se normalizan y validan los datos de reserva pública y se corrige la validación de email.
- Tesorería valida categorías permitidas, normaliza descripciones y protege el diálogo frente a desmontaje asíncrono.
- Sin cambios de pagos/Stripe en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — cierre del flujo de rifas
- `raffle_detail_page.dart`: evita ejecutar el sorteo sin club activo.
- `raffles_page.dart`: permite elegir fecha y hora reales de finalización y protege el diálogo frente a operaciones asíncronas tras desmontaje.
- La rifa deja de depender de una fecha fija de 30 días.
- Sin cambios de Stripe/pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad del presidente activo
- Añadida `supabase/migrations/025_revoke_active_president_integrity.sql`.
- `revoke_member_access` ahora cuenta únicamente presidentes activos y bloquea la revocación del único presidente activo.
- La migración queda en el repositorio y pendiente de aplicación en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — integridad financiera de base de datos
- Añadida `supabase/migrations/026_financial_transaction_account_integrity.sql`.
- Las transacciones financieras ahora validan en base de datos que `account_id` pertenece al mismo `club_id`.
- La migración queda en el repositorio y pendiente de aplicación en Supabase remoto.
- Sin cambios de Stripe/pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad de equipos y personal
- Añadida `027_team_player_club_integrity.sql`: equipo, jugador y `club_id` deben pertenecer al mismo club.
- Añadida `028_team_staff_club_integrity.sql`: equipo, personal y `club_id` deben pertenecer al mismo club y el perfil debe tener membresía activa.
- Las migraciones quedan pendientes de aplicación en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — cierre de integridad, notificaciones, tests y PWA
- Patrocinadores: validación de club, fechas e importe en repositorio y migración `029_sponsor_integrity.sql`.
- Notificaciones: repositorio seguro en modo demo y lectura restringida al usuario autenticado mediante `030_notification_read_integrity.sql`.
- Tests: añadido `test/data_integrity_test.dart` con cobertura de validaciones financieras, rifas, fechas y patrocinadores.
- PWA/producción: actualizados `web/index.html` y `web/manifest.json` con identidad, descripción, viewport y theme-color de producción.
- No se ejecuta ninguna migración sobre Supabase remoto desde este flujo.


### 2026-09-26 — GPT-5.6 LUNA — dashboard actions and real metrics
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`: las acciones rápidas ya navegan a Socios, Tesorería y Rifas en lugar de ejecutar botones sin acción.
- El tercer indicador del dashboard deja de mostrar datos ficticios de rifas y usa el número real de equipos disponible en `dashboardStatsProvider`.
- Se añade el marcador `MODIFICADO POR GPT-5.6 LUNA` al archivo tocado.
- No se modifica Payments, Supabase ni el esquema de base de datos.


### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de equipos
- `lib/features/teams/presentation/pages/teams_page.dart`: añadido buscador local por nombre, categoría o temporada.
- Añadido filtro para mostrar u ocultar equipos inactivos.
- La búsqueda no modifica Supabase ni el esquema de datos; filtra únicamente los equipos ya cargados.
- Se mantiene el estado de edición/activación existente.


### 2026-09-26 — GPT-5.6 LUNA — filtros avanzados de socios
- `lib/features/members/presentation/pages/members_page.dart`: añadido filtrado local por estado y tipo de socio, combinado con la búsqueda existente por nombre, email y número.
- No se realizan consultas adicionales ni cambios de esquema; se filtran los datos ya cargados para el club autenticado.


### 2026-09-26 — GPT-5.6 LUNA — filtros de tesorería
- `lib/features/finance/presentation/pages/finance_page.dart`: añadidos búsqueda local por descripción/categoría y filtro por ingresos/gastos.
- El saldo inicial y los datos financieros siguen procediendo del repositorio; los filtros solo afectan al listado y sus métricas visibles.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — corrección de métricas con filtros de tesorería
- Las métricas de saldo, ingresos y gastos mantienen el cálculo sobre todos los movimientos del club.
- Los filtros solo afectan al listado visible, evitando presentar un saldo global incorrecto al buscar o filtrar.

### 2026-09-26 — GPT-5.6 LUNA — filtro de categoría en tesorería
- Se completa el filtro de tesorería con selección de categoría.
- Las categorías visibles reutilizan las categorías ya permitidas por el formulario financiero.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de notificaciones
- `lib/features/notifications/presentation/pages/notifications_page.dart`: añadido buscador local por título/cuerpo y filtro para mostrar solo no leídas.
- Las acciones de marcar como leída y marcar todas siguen usando el repositorio existente.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de eventos
- `events_page.dart`: búsqueda local por título, ubicación y descripción.
- Añadido filtro para mostrar solo eventos públicos.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de rifas
- `raffles_page.dart`: añadido buscador local por título y filtro por estado.
- Se reutilizan los estados existentes de `RaffleStatus`.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — corrección estructural de filtros de socios
- Se corrige la estructura del Row de búsqueda y filtros en members_page.dart.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — interfaz completa de filtros de tesorería
- Se incorpora a la interfaz el buscador, filtro por tipo y filtro por categoría que ya utilizaba la lógica de filtrado.
- Las métricas financieras siguen calculándose sobre todos los movimientos.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — dashboard sin actividad ficticia
- Se eliminan ejemplos ficticios del dashboard y se muestran métricas reales.
- Sin cambios de esquema, RLS ni Payments.


### 2026-09-26 — GPT-5.6 LUNA — corrección sintáctica de notificaciones
- Se corrige el cierre de paréntesis de Expanded en notifications_page.dart, que provocaba el error `Expected to find ')'` de `flutter analyze`.
- Sin cambios de esquema, RLS ni Payments.
- El proyecto debe volver a validarse localmente con `flutter analyze --no-pub`.


### 2026-09-26 — GPT-5.6 LUNA — contacto de jugador y progenitor/responsable
- `team_players_page.dart`: el alta de jugador incorpora teléfono del jugador y datos opcionales del progenitor/responsable (nombre, teléfono, email y relación).
- `player_repository.dart`: persiste y recupera esos datos y permite editarlos posteriormente.
- `player.dart`: amplía la entidad con los datos de contacto.
- Añadida `supabase/migrations/031_player_guardian_contact.sql` con las nuevas columnas y validaciones básicas; queda pendiente de aplicar en Supabase remoto.
- Sin cambios en Payments.


### 2026-09-26 — GPT-5.6 LUNA — corrección de persistencia de contacto de jugadores
- Los teléfonos y datos del progenitor/responsable quedan almacenados en `players`, no en `team_players`, para que acompañen al jugador al cambiar de equipo.
- La lectura usa la relación anidada de `players` y la edición actualiza el jugador asociado a la asignación.
- Corregido también el modo demo para soportar los nuevos campos.


### 2026-09-26 — GPT-5.6 LUNA — exportación completa de gestión a Excel
- Añadido icono de exportación en el resumen del área de gestión.
- Genera un único XLSX con pestañas de Resumen, Tesorería, Socios, Equipos, Jugadores, Noticias, Eventos y Rifas.
- En modo Supabase se exportan los registros del club activo de esas áreas.
- En modo demo se exportan los datos demo existentes.
- La descarga se realiza mediante el navegador; Chrome gestiona la ubicación final del archivo según su configuración de descargas.
- Añadida dependencia `excel`; ejecutar `flutter pub get` tras actualizar el proyecto.


### 2026-09-26 — GPT-5.6 LUNA — ajuste del exportador Excel
- Corregido el exportador para no depender de campos privados de los repositorios en modo demo.
- Los datos de contacto del jugador y responsable se leen desde la relación `players`.
- La exportación conserva pestañas separadas y evita asumir columnas de ordenación no necesarias en noticias, eventos y rifas.


### 2026-09-26 — GPT-5.6 LUNA — corrección de import y avisos del analyzer
- `dashboard_page.dart`: corregido el import relativo de `club_export_service.dart` desde `presentation/pages` y protegidos los `ScaffoldMessenger` posteriores a operaciones asíncronas usando el `State.context` con `mounted`.
- `members_page.dart`: protegido el `ScaffoldMessenger` posterior al diálogo asíncrono y corregida la documentación que contenía `<...>` como texto HTML.
- Sin cambios de esquema, Supabase remoto ni Payments.


### 2026-09-26 — GPT-5.6 LUNA — cierre funcional de rifas mensuales y trazabilidad de pagos
- Corregida 034_raffle_types_and_secure_draw.sql para aceptar también el tipo mensual, haciendo compatibles las migraciones 034 y 035.
- raffle_repository.dart: completadas consultas de modalidad mensual, histórico de resultados, suscripciones del socio y participaciones pagadas.
- raffle_detail_page.dart: añadido registro manual del resultado de cada mes e histórico con número, premio y ganador identificable.
- Añadida my_raffles_page.dart y ruta /my-raffles para que el socio consulte sus suscripciones mensuales y comprobantes.
- Añadida 036_raffle_payment_receipts.sql: referencia de pago, fecha de pago, perfil, número de recibo y RPC restringida a service_role para que el backend de pagos confirme una participación.
- El comprobante queda preparado para generarse después de un pago real; no se simula un cobro ni una renovación automática.
- La renovación mensual real sigue dependiendo de club_payments_backend/Stripe y su webhook.
- No se ejecuta ninguna migración sobre Supabase remoto.
- Pagos/Stripe no modificados en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — remates del módulo de rifas
- La página pública distingue correctamente la modalidad mensual y muestra el día de renovación.
- La notificación del resultado mensual usa directamente el ID recién creado, evitando asociaciones ambiguas en concurrencia.

### 2026-09-26 — GPT-5.6 LUNA — preparación de monetización Google AdSense
- Añadida configuración `AdsConfig` mediante `--dart-define=ADSENSE_PUBLISHER_ID=ca-pub-...`.
- Añadida carga global de AdSense en Flutter Web desde `AdsService`, por lo que el mismo código acompaña a todas las rutas de la aplicación.
- No se incrusta ningún ID de editor ficticio ni se activan anuncios reales hasta configurar el ID del propietario.
- La estrategia web usa AdSense Auto ads para anclas y barras laterales, que Google puede colocar de forma responsive sin invadir el contenido. Las posiciones y frecuencia se controlan desde AdSense.
- No se crea `ads.txt` todavía porque Google exige el ID `pub-...` real del editor.
- En EEE/Reino Unido/Suiza debe configurarse el consentimiento/CMP correspondiente antes de publicidad personalizada.

### 2026-09-26 — GPT-5.6 LUNA — banda publicitaria global
- Añadido `ClubAdBanner` multiplataforma; en Web usa un bloque responsive de AdSense y en otras plataformas no ocupa espacio hasta que se configure la integración correspondiente.
- El banner se integra en `MaterialApp.router`, por lo que aparece de forma consistente encima de todas las pantallas de la aplicación.
- Configuración mediante `ADSENSE_PUBLISHER_ID` y `ADSENSE_AD_SLOT`; no se han inventado identificadores de Google.
- El bloque usa carga responsive y no se crean refrescos artificiales desde la aplicación.
- Pendiente de activar con los identificadores reales del editor y completar la configuración de consentimiento/CMP de AdSense.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de accesos
- `change_member_role` ya no permite nombrar presidente desde un acceso ordinario.
- Se impide degradar al único presidente activo del club.
- La pantalla de gestión de accesos queda reservada al presidente, coherente con el requisito funcional original.
- Se conserva auditoría del rol anterior y del nuevo.
- La migración sigue pendiente de ejecutar en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — inventario permanente de pendientes
- Añadido PENDIENTES.md con el estado de rifas, pagos, publicidad Google, seguridad, autenticación y pruebas.
- Se distinguen tareas ya preparadas de dependencias externas y de tareas que requieren ejecución en Supabase.
- El siguiente foco recomendado queda en RLS/permisos y pruebas, sin ejecutar cambios en Supabase live.


### 2026-09-27 — GPT-5.6 LUNA — reparación de imports Dart corruptos
- Corregidos los imports de navegación que habían quedado con `.dart;` en lugar de `.dart';` en las páginas afectadas y en `lib/app/router.dart`.
- La corrección es sintáctica y no cambia la lógica funcional de los módulos.
- No se modifica Supabase remoto ni Payments.


### 2026-09-27 — GPT-5.6 LUNA — sincronización de cierre funcional
- Confirmado el cierre funcional de Notificaciones: búsqueda, filtro de no leídas y marcado individual/global usan el repositorio existente.
- Confirmado el cierre funcional de Mis rifas: suscripciones mensuales, participaciones pagadas y comprobante consultable/copiable están disponibles en la aplicación.
- Los PDF, emails y confirmaciones de pago reales permanecen pendientes porque dependen de `club_payments_backend`/Stripe, actualmente en standby.
- Actualizado `PENDIENTES.md` para distinguir pruebas externas y dependencias reales de módulos ya cerrados.
- No se modifica Supabase remoto ni Payments/Stripe.


### 2026-09-27 — GPT-5.6 LUNA — pruebas iniciales de permisos
- Añadido `test/club_role_permissions_test.dart` para cubrir permisos de presidente, tesorero, secretario, roles de equipo y perfiles básicos.
- Se verifica que roles desconocidos o permisos desconocidos quedan denegados por defecto.
- Quedan como siguiente nivel las pruebas de integración RLS/RPC en una base de pruebas; no se toca Supabase remoto.


### 2026-09-27 — GPT-5.6 LUNA — endurecimiento técnico de publicidad web
- Añadido consentimiento publicitario persistente en navegador antes de cargar el script de AdSense.
- Si no existe una decisión del usuario, no se solicita publicidad.
- El banner usa anuncios no personalizados como medida provisional; no se presenta como sustituto de una CMP certificada.
- La CMP certificada por Google/IAB TCF, los IDs reales de AdSense y `ads.txt` siguen pendientes de configuración de la cuenta.
- No se introducen IDs ficticios, secretos ni configuración remota.


### 2026-09-27 — GPT-5.6 LUNA — cierre de permisos por ruta en equipos
- La ruta de jugadores de un equipo exige ahora `players_view`, en lugar de heredar `teams_view`.
- La ruta de personal mantiene `teams_view`.
- Se evita que un rol con acceso a equipos pero sin permiso de jugadores pueda abrir directamente una ruta de plantilla.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de verificaciones de calidad ya realizadas
- Marcada como completada la revisión de warnings/infos del analyzer tras la validación de `flutter analyze --no-pub` sin incidencias.
- Marcada como completada la prueba de exportación Excel, ya validada funcionalmente.
- Se mantienen abiertas únicamente las pruebas que requieren Chrome, dispositivos, staging, Supabase o servicios externos.

### 2026-09-27 — GPT-5.6 LUNA — cobertura del estado de autenticación
- Añadida prueba unitaria para conservar correctamente `passwordRecovery` y `mustChangePassword` en `AuthState.copyWith`.
- Añadida prueba del estado final tras completar el cambio de contraseña.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de matriz de permisos de rutas
- Centralizada la correspondencia entre rutas protegidas y permisos requeridos en `permissionForLocation`.
- Añadida cobertura unitaria para rutas principales, jugadores, personal, gestión de accesos y rutas públicas.
- Las subrutas futuras de jugadores/personal conservan el permiso de su módulo mediante coincidencia por segmento.
- Se marca como revisada la protección de rutas con sesión cerrada; las pruebas RLS/staging siguen abiertas por requerir infraestructura externa.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de estado residual de recuperación
- Un inicio de sesión normal limpia explícitamente `passwordRecovery` antes de seleccionar club.
- Añadida cobertura unitaria para impedir que el estado de recuperación se reutilice como una reautenticación normal.
- La prueba real del flujo completo Web/Chrome y staging permanece abierta por requerir infraestructura externa.

### 2026-09-27 — GPT-5.6 LUNA — cierre de accesos rápidos del dashboard
- El acceso directo a notificaciones se muestra solo con `notifications_view`.
- El enlace `Ver socios` del estado operativo se muestra solo con `members_view`.
- Se evita que el dashboard presente accesos a rutas que el usuario no puede abrir.

### 2026-09-27 — GPT-5.6 LUNA — cierre del nombramiento de presidente
- La gestión de accesos ya no ofrece `club_president` en el alta ordinaria.
- `manage-club-user` rechaza explícitamente ese rol también en backend, evitando saltarse la restricción desde una llamada directa a la Edge Function.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre y corrección de matriz de rutas
- Corregida la exposición de `permissionForLocation` para que la cobertura unitaria use exactamente la misma función que el router.
- Corregida la expectativa de subrutas de jugadores para mantener `players_view` también en `/players/edit`.
- Añadida cobertura de detalle de rifas, perfil, cambio de contraseña, Mis rifas y páginas públicas.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — corrección final de RLS de participaciones
- Corregida `038_permissions_rls_alignment.sql`: la política de lectura propia de `raffle_tickets` usa `buyer_profile_id`, que es la columna real del participante.
- Se evita que la migración futura falle por una columna inexistente o aplique una condición incorrecta.
- No se ejecuta la migración sobre Supabase remoto.

### 2026-09-27 — GPT-5.6 LUNA — cierre de lectura de Mis rifas
- Corregida la consulta de participaciones pagadas para usar `raffle_tickets.buyer_profile_id`.
- La pantalla `Mis rifas` queda alineada con el esquema real de participaciones.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — auditoría de acciones de módulos
- Equipos: edición y activación quedan detrás de `teams_manage`.
- Socios: `Cobrar cuota` requiere `members_manage` y `finance_manage`, porque registra también el movimiento de tesorería.
- Tesorería y Eventos mantienen sus acciones alineadas con `finance_manage` y `events_manage` respectivamente.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — cierre de lecturas del dashboard
- Las estadísticas del dashboard solo consultan socios, equipos y tesorería cuando el usuario dispone de sus permisos `*_view`, evitando fallos por RLS en roles con acceso limitado.
- La exportación Excel ahora genera solo las hojas de los módulos que el usuario puede consultar; la misma restricción se aplica al modo demo.
- No se modifica Supabase remoto ni Payments/Stripe.

### 2026-09-27 — GPT-5.6 LUNA — alineación de perfiles de jugadores
- Corregida la lectura de perfiles usada por jugadores: los roles con `players_view/manage` no necesitan `members_view` para mostrar nombres de jugadores.
- El alta de jugador resuelve la cuenta por email mediante `find_profile_for_player`, protegido por `players_manage`, sin ampliar la lectura general de perfiles.
- Preparada la migración `041_players_profile_rls.sql`; no se ejecuta Supabase remoto.

### 2026-09-27 — GPT-5.6 LUNA — alineación de perfiles del personal
- Corregida la lectura de perfiles usada por el personal: los roles con `teams_view/manage` no necesitan `members_view` para mostrar nombres.
- El alta de personal resuelve la cuenta por email mediante `find_profile_for_team_staff`, protegido por `teams_manage`.
- Preparada la migración `042_team_staff_profile_rls.sql`; no se ejecuta Supabase remoto.

### 2026-09-27 — GPT-5.6 LUNA — corrección de RLS de participaciones de rifas
- Corregida la política de lectura de `raffle_tickets`: la propiedad del comprador usa `buyer_profile_id`, no `profile_id`.
- Así se mantiene el acceso de un usuario a sus propias participaciones sin ampliar `raffles_view`.
- No se ejecuta Supabase remoto ni se modifica Payments/Stripe.


### 2026-09-29 — GPT-5.6 LUNA — mejora de estados del dashboard
- El dashboard deja de ocultar los estados de carga y error de sus estadísticas.
- Mientras se consultan las estadísticas muestra un estado de carga explícito.
- Si la consulta falla, muestra un mensaje no bloqueante y permite reintentar sin abandonar el dashboard.
- Se mantienen los permisos por módulo ya existentes y no se modifica Supabase remoto ni Payments/Stripe.
- Validación de compilación/análisis y prueba visual en Chrome: pendientes de ejecución local.
