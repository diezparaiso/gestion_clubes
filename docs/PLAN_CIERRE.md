# Plan de cierre del MVP

> Auditoría de GitHub Copilot, 2026-10-05. Fase 1: solo lectura; no se modificaron código ni migraciones existentes.

## Alcance y método

Los porcentajes estiman el cumplimiento local de la definición estricta de «terminado» solicitada: no son porcentajes de código escrito. Sin acceso a Supabase de staging/producción no se puede afirmar que las migraciones estén aplicadas, que las políticas funcionen con roles reales ni que los datos demo aparezcan efectivamente en producción. Se revisaron README, documentación, `PENDIENTES.md`, `AI_CHANGELOG.md`, router, estructura de features y las 46 migraciones `001`–`046`. No se encontraron archivos `AUDITORIA_*.md` ni `AUDITORIA*.md`.

El README sigue siendo el texto de plantilla «A new Flutter project»; `docs/03_database.md`, la arquitectura maestra y el informe del 04-09-2026 son propuestas/referencias históricas. En discrepancias, este plan toma como estado local vigente el código y las migraciones. El estado de aplicación remota no es verificable aquí.

## Inventario

| Módulo | Avance real | Estado local y brechas principales |
|---|---:|---|
| Autenticación | 65% | Login, alta, recuperación, perfil, selección de clubes y cambio obligatorio de contraseña están implementados. Falta validar el ciclo completo en Web/staging. Al restaurar una sesión, el router envía a `/onboarding`; la selección siempre termina en `/dashboard`, por lo que se pierde la ruta privada solicitada al recargar. |
| Clubes, usuarios y permisos | 60% | Alta de club, acceso a clubes existentes, roles, gestión de accesos, matriz UI y migraciones centrales de permisos/RLS están presentes. Falta probar RLS/RPC con roles reales y recarga de rutas. Las políticas de `profiles` permiten leer filas completas, no solo columnas necesarias, a perfiles con permisos de socios/jugadores/personal; verificar exposición de email, teléfono y fecha de nacimiento y aplicar mínimo privilegio. |
| Socios | 55% | CRUD, filtros, estado de carga/error, domicilio, serialización manual y exportación existen. Datos de demo siguen activos. No hay tests específicos; faltan historial, importación/cuotas como gestión completa y auditoría de cambios. El acceso «Cobrar cuota» usa `MockPaymentProvider` y registra después un ingreso en Tesorería, aunque no haya pago real. |
| Equipos, jugadores y personal | 60% | Temporadas/equipos, asignación de jugadores y personal, controles de club en migraciones y páginas con estados/reintento están implementados. No hay tests de reglas de este módulo ni validación real RLS. Las rutas de detalle reciben el ID y consultan datos, pero usan `extra` para el título, con fallback genérico al recargar. |
| Tesorería | 40% | Cuentas, movimientos, categorías, cálculo de saldo, validación de entrada y exportación están presentes. El repositorio inserta movimientos directamente en `financial_transactions`; falta una operación server-side única con controles/auditoría para las operaciones contables sensibles. No hay tests contables ni auditoría de cambios; el saldo y movimientos demo siguen habilitados. |
| Dashboard | 50% | Métricas de socios, equipos y saldo consultan repositories respetando permisos de lectura. No cubre rifas/actividad/alertas con datos completos y no hay tests propios; modo demo ofrece métricas de muestra. |
| Rifas (sin pagos reales) | 40% | Entidades, páginas pública/administrativa, reservas RPC, tipos, lectura de histórico y operaciones de sorteo server-side están en el código. Hay tests de entidad y reglas, pero no se prueban las RPC/RLS con base aislada. Dos incompatibilidades de esquema en las RPC impiden completar sorteos y resultados mensuales; se detallan abajo. Falta historia administrativa completa y validación de términos. Checkout, Stripe y renovaciones reales permanecen bloqueados, como se pidió. |
| Comunicación: noticias y eventos | 65% | CRUD, exposición pública con proyecciones explícitas y estados de pantalla están implementados. No hay tests propios ni pruebas RLS de staging; quedan funciones de comunicación automatizada e imágenes fuera del estado verificado. |
| Notificaciones | 30% | Centro de usuario, lectura/no leídas, entregas por perfil y RPC de marcado como leído existen. Crear una notificación no llama a `deliver_notification`, así que no se crean entregas para mostrarla en la bandeja. La política de lectura de `notifications` solo exige `notifications_view` y no aplica `target`; además, las RPC de rifas usan tipos/destinatarios que no cumplen el `CHECK` vigente. No hay tests específicos. Push y registro de dispositivo en el ciclo de vida no están activos. |
| Patrocinadores | 45% | CRUD protegido por permiso, auditoría de altas/ediciones, consulta pública y páginas interna/pública existen. La RPC pública `get_public_sponsors` devuelve `contact_email`, en contra de la regla de no exponer emails públicos; la migración 044 no cambia esa RPC. No hay tests ni prueba RLS real. |
| Auditoría | 25% | `audit_logs` es inmutable y hay auditoría en algunas operaciones de accesos, patrocinadores y sorteos. No se auditan consistentemente movimientos financieros, socios ni cambios de equipos/jugadores/noticias/eventos. La RPC de sorteo de la migración 034 intenta escribir en una columna y enum de acción que no existen según la migración 016. No hay tests de auditoría. |
| Privacidad y consentimiento de anuncios | 45% | Preferencia local explícita, bloqueo de carga previa al consentimiento, opción para revisar y página informativa están implementados. La política es provisional, no hay CMP certificada/configuración legal definitiva y no se puede confirmar una compilación de producción. La configuración de anuncios queda deshabilitada sin IDs de entorno. Retirar el consentimiento no descarga un script de terceros que ya se haya cargado. |
| Pagos (solo lectura) | 0% de pagos reales | No se encontró uso de Stripe/backend de pagos reales en `lib`; `pubspec.yaml` declara el paquete local `club_payments` y Socios instancia `MockPaymentProvider`. El modo simulado puede crear un movimiento real de libro contable local/remoto tras un resultado simulado. No se tocó esta implementación. Pagos reales, webhooks y renovaciones siguen sin estar implementados/activados; cualquier acción sobre ellos requiere decisión expresa. |

## Hallazgos que condicionan el cierre

1. **Crítico — exposición pública de datos del club.** La migración 007 añade una política de SELECT anónimo sobre filas de `clubs` que tengan una rifa activa. RLS limita filas, no columnas: si el rol `anon` tiene el permiso de tabla habitual, esa política permite solicitar columnas privadas de `clubs` (por ejemplo `tax_id`, dirección, email y teléfono). La RPC `get_public_club` sí proyecta columnas explícitas, pero no elimina el acceso directo creado por la política. Confirmar permisos de tabla en staging y retirar/reemplazar esa vía en una migración nueva.
2. **Crítico — email en respuesta pública.** `get_public_sponsors` en 019 devuelve `contact_email`; 044 alinea permisos de gestión, pero deja la RPC pública intacta. Preparar una migración nueva que retire el email de la proyección pública. Si cambia su `RETURNS TABLE`, aplicar `DROP FUNCTION` y recrearla, como exige la regla del proyecto.
3. **Crítico — RPC de sorteo incompatible con auditoría.** La migración 016 define `audit_logs.data` y `audit_action` con `raffle_draw`; la 034 inserta en `metadata` y utiliza `raffle_manual_winner`/`raffle_random_winner`. No existe una migración posterior que añada esa columna/enum. Las RPC de sorteo fallan al registrar auditoría y la transacción se revierte.
4. **Crítico — resultado mensual incompatible con restricciones de notificación.** La 012 solo admite tipos `news/event/raffle/system/other` y targets `all_members/managers/members/staff`; las RPC de 034 y 035 insertan `raffle_winner` o `raffle_monthly_result` y target `profile`. Las restricciones rechazan la inserción y revierten el ganador/resultado.
5. **Alto — reparto de notificaciones incompleto y RLS insuficiente.** `NotificationRepository.createNotification` solo inserta en `notifications`; no invoca la RPC `deliver_notification`. `NotificationDeliveryRepository` solo lista entregas personales, así que las nuevas notificaciones no llegan a la bandeja. La política final de lectura de `notifications` filtra por permiso de módulo, no por destinatario/target. Definir un flujo atómico de creación y entrega, y filtrar también las lecturas directas.
6. **Alto — operaciones financieras sin flujo transaccional/auditoría completos.** El cobro simulado de Socios registra un ingreso tras `MockPaymentProvider`; el cobro no representa una confirmación de pago real. Tesorería crea filas por REST directamente y no escribe `audit_logs`. Mantener pagos reales desactivados y separar claramente el flujo simulado antes del cierre financiero.
7. **Alto — perfiles con lectura de fila completa.** Las políticas añadidas en 038, 041 y 042 autorizan filas de `profiles` asociadas a permisos de socios, jugadores o personal, pero RLS no limita columnas. Revisar privilegios de columna y consultas necesarias, especialmente para datos de menores y perfiles compartidos entre clubes.
8. **Alto — deep links privados no recuperan destino.** En un arranque con sesión Supabase restaurada, `AuthController.build` empieza en `needsClub`; el router redirige a onboarding y la selección conduce siempre al dashboard. La URL original no se conserva ni se retoma.
9. **Medio — datos de demostración permanecen en código de ejecución.** Muchos repositories devuelven registros de muestra si Supabase no está configurado (incluidos clubes, socios, equipos, tesorería, rifas, noticias/eventos, notificaciones y patrocinadores). No se inspeccionó un artefacto/despliegue, así que no se puede asegurar si aparecen en producción; un build sin variables puede presentar datos demo como si fueran reales.
10. **Medio — tests concentrados.** Hay seis archivos de tests para autenticación, permisos, integridad, rutas y reglas/entidades de rifas. No hay tests específicos de repositories/reglas para socios, tesorería, equipos/jugadores/personal, notificaciones, patrocinadores, privacidad ni auditoría; tampoco pruebas de RLS con perfiles aislados por club.

## Tareas priorizadas

### Crítico

- Cerrar proyecciones públicas y permisos de SELECT: clubs, patrocinadores y cualquier endpoint público; eliminar columnas privadas y revisar privilegios reales de `anon`.
- Corregir mediante migraciones nuevas las incompatibilidades de las RPC de rifas frente a `audit_logs` y a los `CHECK` de notificaciones. Añadir pruebas SQL de rechazo/éxito sin ejecutar migraciones en remoto.
- Proteger operaciones de Tesorería con validación/registro server-side y auditoría coherente; no activar ni integrar pagos reales.

### Alto

- Implementar creación y entrega personal de notificaciones como una operación consistente; alinear destinatarios con roles reales y restringir la lectura de contenido a los receptores.
- Revisar mínimo privilegio de `profiles` y aislamiento por club/rol para datos personales y de menores.
- Recuperar club y URL de destino al restaurar sesión; probar deep links privados en recarga/nueva pestaña.
- Completar auditoría de operaciones sensibles y comprobar que las acciones enum/columnas coinciden con el esquema real.
- Añadir tests locales de reglas y aislamiento entre clubes para socios, finanzas, equipos, personal, notificaciones, patrocinadores y auditoría.

### Medio

- Añadir pruebas de serialización y coherencia demo/Supabase en los módulos sin cobertura; sustituir IDs/datos de muestra ambiguos por un estado demo visible y explícito o impedir su uso en build productivo.
- Completar faltantes operativos concretos por módulo: histórico de socios, ledger/conciliación y reportes, historial de rifas, indicadores reales del dashboard y flujo real de soporte para solicitudes de incorporación.
- Verificar mensajes de validación/éxito/error y coherencia de las pantallas con permisos, especialmente cobros simulados y notificaciones.

### Bajo

- Validar manualmente Flutter Web, responsive, instalación/recarga PWA y accesibilidad visual.
- Cerrar texto legal, CMP y configuración publicitaria solo cuando existan datos de cuenta y revisión jurídica. No activar anuncios por defecto ni añadir proveedor push sin decisión.

## Orden propuesto de cierre

1. **Clubes, autenticación y permisos:** resolver exposición pública/columnas privadas, aislamiento RLS y retorno de deep links; validar la matriz por rol.
2. **Auditoría transversal:** fijar contrato de tabla/acciones y cobertura de operaciones sensibles antes de cerrar escrituras.
3. **Comunicación y notificaciones:** entrega por usuario y RLS por destinatario; después verificar noticias/eventos y sus permisos públicos.
4. **Tesorería:** transacciones contables, inmutabilidad/correcciones y auditoría; dejar sin activar cobros reales.
5. **Socios:** reglas, serialización, historial y tests. Mantener el cobro simulado fuera del flujo operativo hasta decisión expresa.
6. **Rifas sin pagos reales:** reparar las RPC/migraciones, probar reglas y aislamiento; conservar checkout/webhooks desactivados.
7. **Equipos, jugadores y personal:** cerrar integridad y serialización con tests de asignación entre clubes.
8. **Patrocinadores:** retirar el email público, probar permisos y validar consulta pública mínima.
9. **Dashboard:** completar métricas desde repositorios reales, permisos y estados.
10. **Privacidad/consentimiento:** validar revocación, texto legal y comportamiento Web; ads permanecen desactivados hasta disponer de configuración y revisión.
11. **Pagos:** solo reabrir si el propietario lo autoriza expresamente; fuera del alcance de cierre actual.

## Migraciones y riesgos de despliegue

- Última migración local: `046_password_flag_security.sql`; la siguiente numeración correlativa disponible es `047`.
- No se creó ninguna migración en esta fase y no se ejecutó `supabase db push`.
- `PENDIENTES.md` identifica 043–046 como preparadas/pendientes de validación o despliegue, pero no es evidencia del estado remoto. Confirmar el historial real de migraciones en staging antes de aplicar una futura `047`; no volver a editar migraciones ya aplicadas.
- No se puede certificar RLS, RPC, Edge Function `manage-club-user`, configuración de Auth/SMTP, entorno de producción, CMP ni pagos sin staging/credenciales/artefacto de despliegue. No se solicitaron ni inspeccionaron secretos.
- Los riesgos de privacidad pública, sorteos que fallan por restricciones, notificaciones que no llegan y demo fallback deben resolverse antes de declarar el MVP listo para producción.

## Verificación ejecutada

- `flutter analyze --no-pub`: correcto, `No issues found!`.
- `flutter test`: correcto, `All tests passed` (39 tests).
- No se ejecutó `flutter test --reporter expanded`, `flutter build web`, pruebas contra Supabase ni revisión visual/PWA; quedan para las fases correspondientes.
- Comandos de cierre previstos por módulo: `flutter analyze --no-pub`; `flutter test --reporter expanded`; `git diff --check`. Para validación externa, usar una base de staging aislada y usuarios de cada rol/club; nunca aplicar migraciones automáticamente desde esta sesión.

## Actualización de cierre — 2026-10-06

> Esta actualización supersede los estados de migraciones y riesgos de RPC de la auditoría inicial del 2026-10-05. El resto de porcentajes y riesgos funcionales conserva el carácter de estimación estática.

- Migraciones 001–048 verificadas en Local y Remote mediante `supabase migration list`; 047 y 048 se aplicaron con `supabase db push` en entorno de datos de prueba.
- 047 restringe grants públicos por columnas, perfiles/notificaciones, propietarios de tickets y operaciones de sorteo; 048 sustituyó la política pública de clubs y revocó el EXECUTE legado `draw_raffle_random(uuid)`.
- Se desplegó `manage-club-user` con `--use-api`; falta configurar `ALLOWED_ORIGINS` para el dominio frontend y probar la función con usuarios de staging.
- `flutter analyze --no-pub`: sin incidencias. `flutter test`: 42 pruebas pasaron tras los cambios de bloques 1–6.
- `supabase db query --linked -f docs/sql/security_checks.sql` no pudo ejecutarse: HTTP 400 / SQLSTATE 42809 (`"min" is an aggregate function`). No se probaron comandos SQL alternativos. Ejecutar el precheck y bloques restantes en SQL Editor según `docs/sql/security_checks_pending.md`.
- Quedan pendientes las pruebas manuales en staging definidas en `docs/TEST_PLAN_ROLES.md`, la revisión de grants/RLS con resultados reales y la configuración CORS de la Edge Function.
