# Plan manual de pruebas por rol

> Ejecutar únicamente en Supabase staging con clubes y cuentas de prueba. Las tablas y RPC deben proteger el acceso aunque se oculte una acción en Flutter. 047–048 están aplicadas en el entorno objetivo según `supabase migration list`; verificarlo antes de probar.

## Preparación común

- Crear dos clubes de prueba y cuentas distintas para cada rol. Comprobar que ningún listado, exportación, URL ni RPC permite cruzar `club_id`.
- Para cada caso, probar primero la navegación visible y después pegar la URL directamente en una pestaña nueva/recargar.
- Si la sesión se restaura sin club seleccionado, onboarding debe conservar la URL interna solicitada; al elegir club debe reanudarse. Si el perfil tiene `must_change_password`, se fuerza `/profile/password` y después se reanuda el destino.
- Para una ruta sin permiso, se espera `/access-denied`. La RLS/RPC debe denegar igualmente llamadas directas aunque se invoquen sin Flutter.
- Verificar roles/permisos efectivos en `club_role_permissions`; la navegación Flutter no sustituye las políticas PostgreSQL.

## Presidente (`club_president`)

- [ ] Ve Dashboard, Socios, Equipos/Jugadores/Personal, Tesorería, Rifas, Noticias, Eventos, Notificaciones, Configuración, Accesos y Patrocinadores.
- [ ] Puede gestionar los módulos concedidos por `ClubRolePermissions`; puede invitar usuarios solo con roles permitidos, cambiar/revocar accesos y administrar patrocinadores.
- [ ] Cambiar/degradar/revocar al único presidente debe fallar. Nombrar otro `club_president` desde gestión ordinaria debe fallar; solo el mecanismo de administrador de plataforma puede hacerlo.
- [ ] La RPC `set_raffle_manual_winner` funciona solo para una Cesta finalizada con ticket `paid`; repetir/cambiar el resultado debe fallar. `draw_raffle_random_secure` debe registrar un ganador una vez y rechazar el segundo intento.
- [ ] Crear notificación `all_members`, `managers`, `members` y `staff`: cada cuenta receptora la ve en su bandeja; perfiles fuera del target no la ven. `target=profile` desde el repository Flutter debe rechazarse.
- [ ] Cambiar el club activo y repetir una URL de detalle debe cargar solo datos de ese club/ID.

## Tesorero (`club_treasurer`)

- [ ] Ve Dashboard, Tesorería y Notificaciones; en Tesorería puede crear movimientos por `finance_manage`.
- [ ] `/members`, `/teams`, `/raffles`, `/news`, `/events`, `/settings`, `/settings/access` y `/sponsors` desde el menú o URL directa deben denegarse.
- [ ] Una inserción/update directa contra módulos no asignados debe rechazarse por RLS/RPC aunque se construya fuera de Flutter.
- [ ] En notificaciones, recibe solo las entregas de su perfil/target; no ve notificaciones de otros usuarios mediante REST.

## Secretario (`club_secretary`)

- [ ] Ve Dashboard, Socios, Noticias, Eventos y Notificaciones; puede gestionar Socios/Noticias/Eventos conforme a `members_manage`, `news_manage` y `events_manage`.
- [ ] No ve ni abre por URL Tesorería, Rifas, Equipos/Jugadores, Accesos, Configuración de gestión ni Patrocinadores; se espera `/access-denied`.
- [ ] Invocar `set_raffle_manual_winner`, `draw_raffle_random_secure` o el sorteo legado `draw_raffle_random(uuid)` directamente debe fallar: no tiene `raffles_manage`, y el legado debe carecer de EXECUTE para authenticated.
- [ ] No puede nombrar presidente, cambiar permisos ni dejar el club sin presidente mediante RPC.

## Entrenador (`coach`)

- [ ] Ve Dashboard, Equipos, Plantilla y Notificaciones; tiene `players_view` y `players_manage` según la matriz.
- [ ] Puede gestionar jugadores según la regla existente, pero no gestionar personal de equipo si la operación exige `teams_manage`.
- [ ] No puede abrir por URL Socios, Tesorería, Rifas, Noticias, Eventos, Configuración, Accesos o Patrocinadores.
- [ ] Intenta leer/modificar jugadores o asignaciones de otro club con IDs conocidos: la RLS/integridad debe devolver cero filas/error, nunca datos cruzados.

## Jugador / familiar (`player`, `parent_guardian`)

- [ ] Ve Dashboard y Notificaciones; `players_view` solo corresponde a jugador/familiar conforme a la matriz.
- [ ] No puede gestionar jugadores, equipos, Socios, Finanzas, Rifas, contenido, accesos o patrocinadores; botones no aparecen y URL/RPC directas fallan.
- [ ] Prueba IDs de jugadores de otro club y perfiles ajenos: no se devuelven datos por RLS.
- [ ] El jugador/familiar solo ve entregas propias. El target de otras personas no aparece aunque conozca `notification_id`.

## Visitante anónimo

- [ ] Abre home pública, club, noticias, eventos, patrocinadores y `/r/:clubSlug/:raffleSlug` sin iniciar sesión.
- [ ] `clubs` permite solo `id/public_name/slug`; `raffles` solo las columnas públicas concedidas en 047. Intentar leer `tax_id`, dirección, email, teléfono, `created_by`, buyer/profile IDs o columnas internas debe fallar.
- [ ] La RPC pública de patrocinadores devuelve solo `id/name/logo_url/website`; nunca contacto.
- [ ] Reserva entre 1 y 10 números válidos de una rifa activa: crea reserva pendiente temporal. Número fuera de rango, duplicado, rifa cerrada o datos de comprador inválidos deben fallar.
- [ ] No puede consultar tablas de socios, perfiles, notificaciones, entregas, dispositivos, sponsors directamente ni ejecutar RPC administrativas/de sorteo/pago.

## Ciclo de contraseña, revocación y destinatarios

- [ ] Cuenta nueva creada por presidente inicia con `must_change_password=true`; rutas privadas se bloquean hasta cambiar contraseña.
- [ ] Tras revocar membresía, la sesión/token existente no permite leer datos del club por RLS ni mutar por RPC; probar también URL directa y volver a iniciar sesión.
- [ ] Revisar que el único presidente activo no pueda ser degradado ni revocado.
- [ ] Enviar targets grupales y comparar las filas de `notification_deliveries` con las membresías/staff activos esperados; las notificaciones `profile` solo llegan al perfil del ganador y el creador no recibe una entrega accidental.
- [ ] Probar pago/tickets solo con el proveedor simulado/no productivo. No activar Stripe, webhook, confirmación real ni suscripciones reales como parte de este plan.

## Ejecución Flutter Web

Sustituye los placeholders localmente; no los guardes en este archivo ni en Git:

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```
