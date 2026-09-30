# Stripe centralizado y liquidación a clubes

- create-raffle-checkout crea Checkout en la cuenta de la plataforma. Valida/reserva números y calcula el importe desde raffles.ticket_price; no acepta un precio del navegador.
- stripe-webhook valida Stripe-Signature y solo procesa Checkout pagado. Registra la venta con ID de sesión idempotente, marca tickets y crea saldo pendiente.
- Comisión de plataforma: 5 % del bruto. Saldo contable del club: 95 %. En este modelo la plataforma soporta las comisiones de procesamiento de Stripe.
- Los fondos se cobran en la cuenta de la plataforma. Para transferir el saldo a los clubes, cada uno deberá completar onboarding de Stripe Connect y disponer de una cuenta conectada verificada. Esta entrega deja el ledger de saldos, pero NO automatiza transferencias; no pagar automáticamente hasta implementar transferencias idempotentes, conciliación y gestión de reembolsos.
- Secrets de Supabase: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, PUBLIC_APP_URL.
- Configurar webhook Stripe para checkout.session.completed y checkout.session.async_payment_succeeded. Aplicar migraciones 043 y 044 y desplegar ambas funciones.
- Pendiente: conectar la pantalla Flutter al endpoint, liberar reservas al cancelar/expirar, gestionar reembolsos y transferencias Connect, probar todo en Stripe test mode. No se han aplicado migraciones ni configurado secretos en el proyecto remoto.
