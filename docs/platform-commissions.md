# Comisiones de plataforma (superadmin)

La migración `043_platform_commissions.sql` añade el libro de ventas y comisiones de la plataforma sin mezclarlo con `financial_transactions`, que sigue siendo la tesorería privada de cada club.

## Modelo inicial
- Comisión por defecto: **5 %** por venta confirmada.
- Se guarda una copia de `commission_rate` en cada venta: cambiar la tasa futura no recalcula el histórico.
- La comisión se redondea a céntimos por venta.
- El informe global devuelve venta bruta, importe reembolsado, comisión generada y comisión neta estimada por club.
- La tabla tiene una clave idempotente `(source, source_sale_id)` para que reintentar un webhook no duplique ventas.
- Las tablas no son legibles ni modificables directamente por `anon` o `authenticated`; la inserción se hace con la función `record_platform_sale` desde backend confiable con rol `service_role`.
- `get_platform_admin_report` exige el claim firmado `app_metadata.platform_admin=true`; no debe colocarse en `user_metadata`, que el propio usuario puede editar.

## Despliegue
1. Revisa el SQL en Supabase y ejecuta las migraciones en orden si aún no están aplicadas.
2. Marca al propietario desde un entorno administrativo confiable actualizando su usuario de Auth para incluir `app_metadata.platform_admin=true` y renueva su sesión/JWT. No habilites este claim desde el cliente Flutter.
3. Integra `record_platform_sale` en el webhook/backend de la pasarela después de verificar criptográficamente el evento de pago. Envía el ID estable de la venta en `target_source_sale_id`; nunca llames a esta función con la clave anon desde la app.
4. Para devoluciones, actualiza el flujo backend para registrar el reembolso y recalcular la comisión neta; la migración deja preparados los campos `status` y `refunded_amount`, pero no expone un RPC de reembolso al cliente.
5. Construye la pantalla superadmin consumiendo `get_platform_admin_report` y muestra por separado comisión generada y comisión neta. El reporte no puede considerar una comisión como cobrada hasta integrar conciliación/pago real al propietario.

## Importante
El repositorio contiene reservas de rifas y recibos, pero no se ha verificado una integración de pasarela que confirme pagos automáticamente. Por ello, esta migración prepara el ledger y las funciones seguras; **no registra ventas por sí sola**. Hasta integrar un webhook de pago, el informe de ventas y comisiones estará vacío. Tampoco se ha ejecutado esta migración contra un proyecto Supabase real desde el repositorio.
