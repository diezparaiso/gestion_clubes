# Arquitectura de incorporación de clubes

> MODIFICADO POR GPT-5.6 LUNA (2026-09-28): documento inicial de arquitectura para el alta de clubes.

## Objetivo

Permitir que cualquier club pueda iniciar por sí mismo su incorporación a Plataforma Clubes, sin pedir datos bancarios a la plataforma y sin convertir el formulario inicial en un proceso de pagos.

## Fase 1 — solicitud de incorporación

Implementada en esta rama:

- Ruta pública: `/solicitar-incorporacion`.
- Enlace desde la pantalla de login.
- Formulario responsive con:
  - nombre del club;
  - CIF/NIF;
  - localidad y provincia;
  - persona de contacto;
  - email y teléfono;
  - intereses funcionales;
  - observaciones.
- Mensaje explícito para no introducir IBAN ni otros datos bancarios.
- La pantalla valida los datos y muestra una confirmación de interfaz.
- **Importante:** esta fase todavía no persiste ni envía la solicitud. La conexión con soporte requiere backend/persistencia y se hará en una fase posterior.

## Fase 2 — cola de solicitudes

Cuando se habilite backend:

### Nueva entidad recomendada

`club_onboarding_requests`

Campos previstos:

- `id`
- `requester_user_id` (si se exige cuenta antes de solicitar)
- `club_name`
- `tax_id`
- `legal_name`
- `club_type`
- `address`
- `city`
- `province`
- `postal_code`
- `website`
- `contact_name`
- `contact_email`
- `contact_phone`
- `interests`
- `notes`
- `status`
- `reviewed_at`
- `reviewed_by`
- `created_at`
- `updated_at`

Estados recomendados:

`requested` → `reviewing` → `approved` / `rejected`

Después de aprobar:

`approved` → `onboarding` → `active`

## Fase 3 — alta autónoma del club

Wizard recomendado:

1. Crear cuenta del responsable.
2. Verificar email.
3. Introducir datos legales del club.
4. Subir logo.
5. Configurar información pública.
6. Aceptar condiciones y privacidad.
7. Crear el espacio privado del club.
8. Asignar al responsable como `club_president`.
9. Configurar cobros mediante Stripe Connect si el club los necesita.
10. Activar el club cuando se hayan completado las verificaciones necesarias.

El alta debe evitar que un usuario pueda crear o asumir arbitrariamente un club existente. La identidad del responsable y la vinculación con el club deben quedar auditadas.

## Stripe Connect

La plataforma **no debe recoger ni almacenar el IBAN del club** en su propio formulario.

La arquitectura prevista es:

- Plataforma → crea la cuenta conectada de Stripe.
- Plataforma → conserva únicamente el identificador de la cuenta conectada y su estado.
- Stripe → realiza el onboarding financiero/KYC y solicita los datos bancarios que correspondan.
- Backend/webhooks → actualiza el estado de capacidades de cobro y pagos.
- Flutter → muestra el estado al presidente del club.

Datos previstos en `clubs` o en una entidad financiera separada:

- `stripe_connected_account_id`
- `stripe_status`
- `stripe_charges_enabled`
- `stripe_payouts_enabled`

No almacenar:

- IBAN;
- número de cuenta;
- credenciales bancarias;
- secretos Stripe.

## Seguridad y privacidad

La solicitud contiene datos de contacto de personas físicas, por lo que el futuro almacenamiento debe quedar cubierto por la política de privacidad y controles de acceso adecuados.

Para una solicitud pública real deberán considerarse además:

- protección frente a spam/abuso;
- validación server-side;
- rate limiting;
- CAPTCHA/Turnstile si procede;
- RLS o endpoint server-side que impida que un solicitante vea solicitudes de otros clubes;
- auditoría de cambios de estado.

## Qué NO se modifica en esta fase

- Supabase remoto.
- Migraciones/RPC/Edge Functions.
- Stripe Connect.
- `club_payments`.
- `club_payments_backend`.

Esto mantiene la incorporación de clubes desacoplada del bloque de pagos hasta que el backend financiero esté preparado.
