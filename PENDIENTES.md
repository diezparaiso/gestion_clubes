<!-- MODIFICADO POR GITHUB COPILOT (2026-10-06): actualiza cierre 032-048, Edge Function y plan por rol. -->
# PENDIENTES DEL PROYECTO

> Última actualización: 2026-10-06 — GITHUB COPILOT

> Los puntos marcados como pendientes de staging, Supabase, proveedores o producción requieren una validación externa y no se cierran solo con cambios de código.
> Inventario de trabajo pendiente. La trazabilidad cronológica permanece en AI_CHANGELOG.md.

## 1. Pagos y rifas

### Bloqueado por proveedor externo
- [ ] Recuperar/terminar club_payments_backend.
- [ ] Eliminar de forma segura cualquier secreto Stripe expuesto en la historia de Git antes de volver a publicar ese repositorio.
- [ ] Configurar Stripe en entorno seguro.
- [ ] Integrar checkout real de participaciones de rifa.
- [ ] Implementar suscripciones Stripe reales para la modalidad mensual.
- [ ] Webhook de pago confirmado.
- [ ] Webhook de renovación mensual.
- [ ] Webhook de pago fallido / cancelación.
- [ ] Hacer que el webhook invoque record_raffle_payment(...) con service_role.
- [ ] Asociar correctamente profile_id, número, referencia de pago y recibo.
- [ ] Evitar duplicados mediante idempotencia de eventos Stripe.
- [ ] Generar PDF/recibo real y conservar referencia.
- [ ] Email transaccional al socio después del pago con número y recibo.
- [ ] Email de renovación mensual.
- [ ] Email de pago fallido.
- [ ] Probar renovación, cancelación y reintentos en Stripe Test.

### Ya preparado en la aplicación
- [x] Modalidad Cesta.
- [x] Modalidad Sorteo puro.
- [x] Modalidad Mensual.
- [x] Números únicos por rifa.
- [x] Sorteo criptográficamente aleatorio.
- [x] Ganador manual de Cesta después del cierre.
- [x] Histórico mensual.
- [x] Pantalla Mis rifas.
- [x] Trazabilidad de recibos en raffle_tickets.
- [x] RPC de confirmación de pago restringida a service_role.
- [x] No se ejecutan migraciones remotamente desde este flujo.

## 2. Publicidad Google

### Pendiente de datos de la cuenta
- [ ] ADSENSE_PUBLISHER_ID real (ca-pub-...).
- [ ] ADSENSE_AD_SLOT real.
- [ ] Crear/configurar ads.txt con el pub-... real.
- [ ] Configurar una CMP certificada por Google e integrada con IAB TCF para anuncios personalizados en EEE, Reino Unido y Suiza.
- [x] Añadir bloqueo local previo a cualquier solicitud AdSense y persistir la decisión del usuario.
- [x] Añadir página pública de privacidad/cookies y permitir revisar o cambiar la preferencia publicitaria.
- [ ] Revisar política de privacidad/cookies y consentimiento con el texto jurídico definitivo.
- [ ] Activar Auto ads en la cuenta.
- [ ] Ajustar anclas y barras laterales para que no sean invasivas.
- [ ] Verificar anuncios en producción.

### Ya preparado
- [x] AdsConfig.
- [x] AdsService.
- [x] Banner global responsive para Flutter Web.
- [x] Integración global sobre MaterialApp.router.
- [x] Sin refrescos artificiales.
- [x] Sin IDs ficticios.

## 3. Seguridad y permisos
- [x] Aplicadas migraciones 032–048 en Supabase remoto el 2026-10-06; `supabase migration list` confirmó Local=Remote.
- [x] Aplicadas las migraciones 047 (`security_hardening`) y 048 (`public_raffle_acl_and_legacy_draw`) mediante `supabase db push`.
- [ ] Ejecutar manualmente `docs/sql/security_checks.sql` en SQL Editor; `supabase db query --linked -f` falló con SQLSTATE 42809. Pasos en `docs/sql/security_checks_pending.md`.
- [ ] Verificar todas las políticas RLS en una base de pruebas.
- [x] Auditar repositories con escrituras directas y alinear sus fronteras RLS con la matriz central; migración 045 aplicada.
- [x] Revisar cada pantalla contra club_role_permissions.
- [x] Separar permisos _view y _manage en la UI en los módulos ya cerrados.
- [x] Revisar dashboard/sidebar para ocultar acciones no permitidas por rol.
- [x] Verificar revoke_member_access y su política de seguridad en código/migraciones.
- [x] Endurecer y desplegar `manage-club-user` mediante `--use-api`; secretos permanecen solo en el entorno de Supabase.
- [ ] Configurar `ALLOWED_ORIGINS` con el origen real de Flutter Web y probar el alta con presidente activo y cuentas nueva/existente.
- [x] Añadir cobertura inicial de seguridad para la matriz de permisos por rol; quedan pruebas de integración RLS/RPC para staging.
- [x] Añadido `docs/TEST_PLAN_ROLES.md` con pruebas manuales por rol, UI, URL directa, revocación, sorteos y targets de notificación.
- [x] Cambio de rol impide dejar el club sin presidente.
- [x] Nombramiento de presidente reservado al administrador de plataforma.
- [x] Alta de accesos bloquea también en backend el rol `club_president`.
- [x] Gestión de accesos restringida al presidente.
- [x] Alinear Patrocinadores con el permiso central sponsors_manage; migraciones 043–044 aplicadas, pendientes de validar por rol en staging.
- [x] Alinear las políticas de escritura principales con *_manage mediante migración 045; pendiente de validar por rol en staging.
- [ ] Verificar grants efectivos, RLS, RPC públicas y funciones SECURITY DEFINER en staging con `docs/sql/security_checks.sql`.

## 4. Perfil y autenticación
- [ ] Probar flujo completo de must_change_password en Web/Chrome y staging.
- [x] Blindar también en backend el indicador must_change_password; migración 046 aplicada, pendiente de probar en staging.
- [x] Blindar por código que un inicio de sesión normal no herede el estado `passwordRecovery`.
- [ ] Probar cambio de contraseña en móvil y web.
- [x] Implementar y revisar recuperación de contraseña.
- [x] Añadir cobertura unitaria del estado de recuperación y cambio obligatorio de contraseña.
- [x] Revisar selección de club con múltiples clubes.

## 5. Calidad técnica
- [x] Ejecutar flutter analyze --no-pub.
- [x] Ejecutar flutter test --reporter expanded.
- [x] Ejecutar git diff --check.
- [x] Revisar warnings e infos del analyzer.
- [ ] Probar Flutter Web en Chrome (validación manual local).
- [ ] Probar responsive móvil/tablet/escritorio.
- [x] Verificar rutas con sesión cerrada mediante la matriz de permisos de ubicación y cobertura unitaria.
- [x] Cubrir rutas de detalle de rifas, perfil, Mis rifas y páginas públicas en la matriz.
- [ ] Verificar RLS con perfiles de cada rol.
- [ ] Ejecutar el plan manual `docs/TEST_PLAN_ROLES.md` en staging; configurar `ALLOWED_ORIGINS` con el host real del frontend antes de probar altas.
- [x] Hacer prueba de exportación Excel.
- [ ] Hacer prueba completa de rifas con Supabase de staging.

## 6. No hacer sin petición expresa
- No ejecutar migraciones contra Supabase live.
- No activar pagos reales.
- No introducir secretos Stripe en el repositorio.
- No publicar IDs de Google ficticios.
- No implementar auto-refresh artificial de publicidad.
- No modificar Payments/Stripe mientras el backend de pagos esté en standby.

## 8. Incorporación de nuevos clubes — 2026-09-28

### Fase 1 implementada
- [x] Crear ruta pública `/solicitar-incorporacion`.
- [x] Crear formulario responsive de solicitud.
- [x] Añadir acceso desde login.
- [x] Documentar arquitectura futura de onboarding.
- [x] Dejar explícito que los datos bancarios no se introducen en la plataforma.
- [x] Añadir información/aceptación de privacidad al formulario de solicitud.
- [x] Añadir tipo de entidad y web opcional al formulario.

### Pendiente para hacerla operativa
- [ ] Crear persistencia `club_onboarding_requests` en Supabase.
- [ ] Crear RLS y/o endpoint server-side para recepción segura.
- [ ] Añadir protección anti-spam/rate limiting/CAPTCHA si la solicitud queda abierta a anónimos.
- [ ] Crear bandeja de solicitudes para soporte.
- [ ] Definir datos de contacto reales de soporte.
- [ ] Implementar alta autónoma del club.
- [ ] Integrar Stripe Connect para onboarding financiero.
- [ ] Guardar únicamente `stripe_connected_account_id` y estados de Stripe.
- [ ] Probar flujo completo de alta, aprobación, activación y cobros.

> La Fase 1 es deliberadamente frontend-only. El botón de envío muestra una confirmación de interfaz, pero todavía no transmite ni almacena datos.

## Orden recomendado para continuar
1. Completar pruebas de seguridad/RLS en una base de pruebas, sin tocar Supabase live.
2. Completar pruebas responsive/Web y del flujo de autenticación.
3. Retomar club_payments_backend cuando se solicite.
4. Activar comprobantes + emails con pagos reales.
5. Activar renovación mensual real.
6. Configurar AdSense/CMP.
7. Pruebas completas de producción.

## 7. Trabajo de desarrollo en curso — 2026-09-28

### Implementado en rama `ai/non-payments-development`
- [x] Mejorado responsive de Socios: cabecera, buscador y filtros.
- [x] Mejorado responsive de Tesorería: cabecera, buscador y filtros.
- [x] Mejorado responsive de Eventos: cabecera, buscador y filtro público.
- [x] Mejorado responsive de Equipos: cabecera, buscador y filtro de inactivos.
- [x] Todos estos cambios quedan aislados de Supabase remoto y Payments/Stripe.
- [x] Registrados los cambios en `AI_CHANGELOG.md`.
- [x] Marcados los cuatro archivos fuente modificados con `MODIFICADO POR GPT-5.6 LUNA`.

### Trabajo cerrado en esta ronda
- [x] Centro de Notificaciones.
- [x] Flujo Equipos → Jugadores → Personal.

### Navegación pública
- [x] Crear landing pública de la plataforma en `/`.
- [x] Hacer que `/` sea la entrada inicial de la aplicación.
- [x] Conectar login y solicitud de incorporación con retorno a la landing pública.
- [x] Mantener acceso **Acceder** desde la home pública.
- [x] Añadir acceso **Acceder** también en Noticias, Eventos y Patrocinadores públicos.
- [ ] Diseñar/validar consulta pública de Equipos sin exponer datos privados; no crear una página pública contra las tablas actuales mientras su lectura siga restringida a usuarios autenticados.
- [x] Separar conceptualmente la entrada pública de la plataforma (`/`) de la web pública de cada club (`/club/:clubSlug`).

### Próximo bloque sin pagos
- [x] Cerrar módulo de Patrocinadores: gestión interna, rutas, navegación y escaparate público.
- [x] Auditoría responsive final del resto de pantallas; quedan solo comprobaciones manuales en Chrome.
- [x] Revisar UX de dashboard y navegación móvil: acceso a la web pública, identidad del usuario y cabecera responsive.
- [ ] Completar revisión visual del dashboard en Flutter Web/Chrome (validación manual local).
- [x] Completar/repasar CRUD y estados de Noticias.
- [x] Cerrar centro de Notificaciones y estados vacíos/error.
- [x] Revisar Perfil y gestión de cuenta.
- [x] Mejorar responsive de Configuración del club y acceso a Usuarios y permisos.
- [x] Cerrar flujo Equipos → Jugadores → Personal: CRUD/estado, navegación, filtros, responsive y estados vacíos.
- [x] Auditoría de Rifas excluyendo checkout/pago real: listado, detalle, Cesta, Sorteo puro, Mensual, área del socio y página pública.
- [x] Mejorar mensajes de error y estados de carga del dashboard.\n- [ ] Mejorar mensajes de error y estados de carga del resto de la aplicación.\n- [x] Mejorar estados de error y reintento de las páginas públicas de Noticias, Eventos y Patrocinadores.
- [x] Mejorar estado de error y reintento del listado de Socios.
- [x] Mejorar estado de error y reintento de Noticias.
- [x] Mejorar estado de error y reintento de Eventos.
- [x] Mejorar estado de error y reintento de Plantilla.
- [x] Mejorar estado de error y reintento de Personal.
- [x] Mejorar estado de error y reintento de Equipos.
- [x] Mejorar estados de error y reintento del módulo de Rifas sin pagos reales.
- [x] Mejorar estado de error y reintento de Usuarios y permisos.
- [x] Mejorar estado de error y reintento de Miembros del Club.
- [x] Ampliar tests unitarios que no dependan de Supabase/Stripe.
- [x] Revisar permisos de UI frente a `*_view` / `*_manage`.
- [x] Auditoría estática de PWA y comportamiento móvil/tablet/escritorio; queda prueba manual de instalación/ejecución en Chrome.

### Bloqueado deliberadamente
- [ ] Integración real de `club_payments`.
- [ ] Integración de `club_payments_backend`.
- [ ] Stripe Connect, Checkout, PaymentIntent, webhooks e idempotencia.
- [ ] Suscripciones y renovaciones reales.
- [ ] Cualquier cambio remoto en Supabase.
- [ ] Cualquier despliegue de migraciones/RPC/Edge Functions que requiera validación externa.

> Regla de trabajo: cualquier archivo modificado por ChatGPT debe llevar un marcador `MODIFICADO POR GPT-5.6 LUNA` y cada intervención debe registrarse también en `AI_CHANGELOG.md`. No se consideran terminadas las tareas que dependan de infraestructura externa hasta validarlas allí.


### Cierre incremental — 2026-09-29
- [x] Web pública del club: estado de carga, error recuperable al cargar el club y reintento de la actualidad (noticias/eventos).
- [x] Auditoría estática final de responsive, PWA, cobertura de tests y permisos en la rama `ai/non-payments-development`.
- [ ] Validación local final: `flutter analyze --no-pub`, `flutter test --reporter expanded`, `flutter build web` y revisión visual/instalación PWA en Chrome.
