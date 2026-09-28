# Flujo funcional de incorporación de clubes

> MODIFICADO POR GPT-5.6 LUNA (2026-09-28): define el flujo funcional de soporte e incorporación previo a la implementación del backend.

## Objetivo
Definir qué debe ocurrir desde que un club solicita incorporarse hasta que dispone de su espacio operativo, sin implementar todavía persistencia ni Stripe.

## 1. Entrada pública

Flujo: `/` → `Incorporar mi club` → `/solicitar-incorporacion`.

La solicitud recoge solo información necesaria para identificar al club y contactar con su responsable.

Datos iniciales:
- Nombre del club.
- CIF/NIF.
- Localidad y provincia.
- Tipo de entidad.
- Sitio web opcional.
- Persona de contacto.
- Email y teléfono.
- Intereses funcionales.
- Observaciones.
- Aceptación de la información de privacidad.

No se solicita IBAN ni ningún dato bancario.

## 2. Recepción futura

En la versión operativa, el envío debe crear una solicitud en `club_onboarding_requests` con estado inicial `requested`.

El backend debe validar de nuevo los datos recibidos. La validación del navegador nunca debe considerarse suficiente.

## 3. Bandeja de soporte

El equipo autorizado de soporte dispondrá de una bandeja con identificador, fecha, club, CIF/NIF, localidad, contacto, estado y última actualización.

Estados de revisión: `requested` → `reviewing` → `approved` o `rejected`.

Los cambios de estado deben quedar auditados con usuario y fecha.

## 4. Revisión

1. Abrir la solicitud.
2. Comprobar los datos aportados.
3. Solicitar información adicional si fuese necesario.
4. Aprobar o rechazar.
5. Dejar una nota interna.
6. Evitar duplicar un club ya existente.

La pantalla de soporte no debe mostrar ni permitir modificar datos bancarios.

## 5. Alta del club

Al aprobar una solicitud:
1. Crear el registro del club.
2. Generar/validar su slug público.
3. Crear la vinculación del responsable con el club.
4. Crear o completar su acceso.
5. Asignar `club_president` mediante el mecanismo autorizado.
6. Pasar el club a estado de onboarding/configuración.

Debe existir una comprobación que impida que un usuario se apropie de un club existente mediante un CIF/NIF conocido.

## 6. Configuración inicial

El presidente completa logo, nombre público, contacto, descripción, web/redes y configuración inicial del club.

Estados operativos: `onboarding` → `active`, con `suspended` como estado de bloqueo posterior.

## 7. Configuración financiera

Se mantiene separada del alta básica.

Flujo previsto: `Club → Plataforma → Stripe Connect → Stripe onboarding/KYC → cuenta bancaria`.

La plataforma debe almacenar únicamente `stripe_connected_account_id`, `stripe_status`, `stripe_charges_enabled` y `stripe_payouts_enabled`.

No debe almacenar IBAN, credenciales bancarias ni secretos Stripe.

## 8. Seguridad mínima del backend futuro

- RLS o endpoint server-side.
- Validación server-side.
- Rate limiting.
- Protección anti-spam/CAPTCHA si procede.
- Auditoría de cambios de estado.
- Acceso restringido de soporte.
- No exposición de solicitudes entre clubes.
- Idempotencia en la creación del club para evitar dobles altas.

## 9. Fases

### Fase A — frontend
Implementada: landing pública, formulario de solicitud, explicación del proceso, navegación pública y login.

### Fase B — backend de solicitudes
Pendiente: `club_onboarding_requests`, recepción segura, RLS/políticas, bandeja de soporte, estados y auditoría.

### Fase C — alta autónoma
Pendiente: wizard, creación segura del club, vinculación del responsable y logo/storage.

### Fase D — Stripe Connect
Pendiente: cuenta conectada, onboarding de Stripe, webhooks de estado y estado financiero visible para el presidente.

## Regla de alcance actual
En esta fase no se modifica Supabase remoto, migraciones, RPC, Edge Functions, Stripe, `club_payments` ni `club_payments_backend`.
