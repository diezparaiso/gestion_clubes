<!-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): sincroniza el inventario de módulos cerrados y pendientes reales. -->
# PENDIENTES DEL PROYECTO

> Última actualización: 2026-09-27 — GPT-5.6 LUNA

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
- [ ] Ejecutar migraciones 032–040 en Supabase cuando corresponda (solo mediante despliegue controlado).
- [ ] Verificar todas las políticas RLS en una base de pruebas.
- [x] Revisar cada pantalla contra club_role_permissions.
- [x] Separar permisos _view y _manage en la UI en los módulos ya cerrados.
- [x] Revisar dashboard/sidebar para ocultar acciones no permitidas por rol.
- [x] Verificar revoke_member_access y su política de seguridad en código/migraciones.
- [ ] Revisar Edge Function manage-club-user desplegada con secretos solo en Supabase.
- [x] Añadir cobertura inicial de seguridad para la matriz de permisos por rol; quedan pruebas de integración RLS/RPC para staging.
- [x] Cambio de rol impide dejar el club sin presidente.
- [x] Nombramiento de presidente reservado al administrador de plataforma.
- [x] Alta de accesos bloquea también en backend el rol `club_president`.
- [x] Gestión de accesos restringida al presidente.

## 4. Perfil y autenticación
- [ ] Probar flujo completo de must_change_password en Web/Chrome y staging.
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
- [ ] Probar Flutter Web en Chrome.
- [ ] Probar responsive móvil/tablet/escritorio.
- [x] Verificar rutas con sesión cerrada mediante la matriz de permisos de ubicación y cobertura unitaria.
- [x] Cubrir rutas de detalle de rifas, perfil, Mis rifas y páginas públicas en la matriz.
- [ ] Verificar RLS con perfiles de cada rol.
- [x] Hacer prueba de exportación Excel.
- [ ] Hacer prueba completa de rifas con Supabase de staging.

## 6. No hacer sin petición expresa
- No ejecutar migraciones contra Supabase live.
- No activar pagos reales.
- No introducir secretos Stripe en el repositorio.
- No publicar IDs de Google ficticios.
- No implementar auto-refresh artificial de publicidad.
- No modificar Payments/Stripe mientras el backend de pagos esté en standby.

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

### Próximo bloque sin pagos
- [ ] Auditoría responsive del resto de pantallas.
- [ ] Revisar UX de dashboard y navegación móvil.
- [ ] Completar/repasar CRUD y estados de Noticias.
- [ ] Revisar módulo de patrocinadores/publicidad del club.
- [ ] Revisar centro de Notificaciones y estados vacíos/error.
- [ ] Revisar Perfil y gestión de cuenta.
- [ ] Auditoría integral Equipos → Jugadores → Personal.
- [ ] Auditoría de Rifas excluyendo checkout/pago real.
- [ ] Mejorar mensajes de error y estados de carga de la aplicación.
- [ ] Ampliar tests unitarios que no dependan de Supabase/Stripe.
- [ ] Revisar permisos de UI frente a `*_view` / `*_manage`.
- [ ] Revisar PWA y comportamiento móvil/tablet/escritorio.

### Bloqueado deliberadamente
- [ ] Integración real de `club_payments`.
- [ ] Integración de `club_payments_backend`.
- [ ] Stripe Connect, Checkout, PaymentIntent, webhooks e idempotencia.
- [ ] Suscripciones y renovaciones reales.
- [ ] Cualquier cambio remoto en Supabase.
- [ ] Cualquier despliegue de migraciones/RPC/Edge Functions que requiera validación externa.

> Regla de trabajo: cualquier archivo modificado por ChatGPT debe llevar un marcador `MODIFICADO POR GPT-5.6 LUNA` y cada intervención debe registrarse también en `AI_CHANGELOG.md`. No se consideran terminadas las tareas que dependan de infraestructura externa hasta validarlas allí.
