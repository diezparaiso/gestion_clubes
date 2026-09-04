Informe de Estado del Proyecto
Fecha: 04/09/2026

Los porcentajes son estimaciones funcionales, no una medición por líneas de código. Indican cuánto del bloque previsto está usable y cuánto falta para considerarlo completo.

Resumen general
Área	Estado	Avance
Fase 0: base técnica y documentación	Parcial	80%
Fase 1: autenticación y navegación	Parcial	75%
Fase 2: clubes, usuarios y permisos	Parcial	60%
Fase 3: socios y numeración	Parcial	75%
Fase 4: equipos, jugadores y personal	Parcial	80%
Fase 5: tesorería	Parcial	75%
Fase 6: dashboard	Parcial	70%
Fase 7: rifas y sorteos	Casi terminado en modo simulado	90%
Fase 8: pagos reales	No iniciado	0%
Fase 9: comunicación	Parcial avanzado	70%
Fase 10: patrocinadores	No iniciado	0%
Fase 11: porras	No iniciado	0%
Estimación global actual: 60% del MVP técnico previsto.

Fase 0: Base técnica
Estado: parcialmente terminado, 80%.

Terminado:

Flutter Web/PWA.
Riverpod.
go_router.
Supabase.
Arquitectura por funcionalidades.
Migraciones versionadas.
GitHub.
Primeros tests.
Supabase enlazado.
Migraciones 001-015 aplicadas remotamente.
Pendiente:

Completar documentación estructurada prevista en docs.
Crear decisiones ADR formales.
Añadir configuración de entorno documentada.
Limpiar o ignorar los archivos locales del CLI de Supabase.
Configurar una rutina estable de compilación y despliegue.
Fase 1: Autenticación y navegación
Estado: parcialmente terminado, 75%.

Terminado:

Login.
Registro.
Cierre de sesión.
Onboarding para crear club.
Redirecciones según autenticación.
Rutas privadas y públicas.
Navegación responsive básica.
Pendiente:

Recuperación de contraseña.
Magic Link.
OAuth.
Gestión real de perfil.
Selección entre varios clubes.
Control de permisos por ruta y rol.
Página de acceso no autorizado.
Fase 2: Clubes, usuarios y permisos
Estado: parcialmente terminado, 60%.

Terminado:

Creación de club.
clubs.
profiles.
club_memberships.
Roles base.
RLS inicial.
Configuración pública del club.
Edición de nombre público y redes sociales.
Pendiente:

Invitar usuarios.
Asignar y revocar roles desde la interfaz.
Gestión de directiva.
club_officials.
Matriz de permisos completa.
Soporte real para usuarios pertenecientes a varios clubes.
Auditoría de cambios de permisos.
Fase 3: Socios
Estado: parcialmente terminado, 75%.

Terminado:

Gestión básica de socios.
Número de socio independiente.
Estados de socio.
Migración de base de datos.
Aislamiento por club.
Pendiente:

Historial completo de cambios.
Cuotas.
Renovaciones.
Importación masiva.
Tests específicos.
Auditoría de renumeraciones.
Mejoras de filtros y exportación.
Fase 4: Equipos, jugadores y personal
Estado: parcialmente terminado, 80%.

Terminado:

Equipos.
Temporadas.
Jugadores.
Plantillas.
Personal técnico.
Pantallas y repositorios básicos.
Migraciones 003-005.
Pendiente:

Validaciones avanzadas entre club, equipo y persona.
Historial de asignaciones.
Gestión completa de temporadas.
Permisos específicos para entrenadores.
Tests de relaciones y permisos.
Fase 5: Tesorería
Estado: parcialmente terminado, 75%.

Terminado:

Cuentas financieras.
Ingresos.
Gastos.
Categorías.
Saldo.
Cuenta principal.
Exportación CSV.
Migración 006.
Pendiente:

Auditoría financiera.
Bloqueo de modificaciones históricas.
Conciliación.
Informes más completos.
Permisos diferenciados entre presidente y tesorero.
Tests contables automatizados.
Fase 6: Dashboard
Estado: parcialmente terminado, 70%.

Terminado:

Dashboard responsive.
Sidebar en escritorio.
Navegación móvil.
Métricas principales.
Saldo.
Socios.
Accesos rápidos.
Pendiente:

Métricas completamente conectadas a datos reales.
El contador de rifas todavía contiene valores demo.
Dashboard específico por rol.
Actividad reciente real.
Alertas.
Eventos y notificaciones reales en los indicadores.
Fase 7: Rifas
Estado: muy avanzado en modo simulado, 90%.

Terminado:

Creación de rifas.
Listado administrativo.
Detalle de rifa.
Participaciones.
Página pública:
/r/:clubSlug/:raffleSlug
Disponibilidad de números.
QR.
Reservas temporales de 15 minutos.
RPC segura para reservar números.
Liberación de reservas expiradas.
Sorteo aleatorio.
Solo participan tickets pagados.
Registro único del sorteo.
Estado drawn.
Deep links administrativos.
Tests básicos.
Migraciones 007-009.
Pendiente:

Interfaz completa para confirmar, cancelar o reembolsar tickets.
Historial visible de sorteos.
Auditoría formal de reservas y sorteos.
Gestión de bases legales.
Control de términos y condiciones.
Pago real mediante proveedor externo.
Los pagos reales deben seguir desactivados.

Fase 8: Pagos reales
Estado: intencionadamente no iniciado, 0%.

No se ha implementado:

Stripe, Redsys, PayPal u otro proveedor.
Webhooks.
Confirmación server-side.
Idempotencia.
Devoluciones.
Conciliación.
Comisiones.
Esto es correcto según la arquitectura. Antes de activarlo hay que revisar legalidad, fiscalidad, protección de menores y proveedor.

Fase 9: Comunicación
Estado: parcialmente avanzado, 70%.

Terminado:

Noticias autenticadas en /news.
Noticias públicas en /club/:clubSlug/news.
Eventos autenticados en /events.
Eventos públicos en /club/:clubSlug/events.
Bandeja de notificaciones en /notifications.
Creación de notificaciones internas.
Portada pública /club/:clubSlug.
Enlaces públicos de web y redes sociales.
Configuración pública en /settings.
Migraciones 010-015.
Pendiente:

Push real.
user_devices conectado al ciclo de vida de la aplicación.
Selección de proveedor push.
Relación de destinatarios por usuario.
Marcar notificaciones como leídas.
Notificaciones automáticas al publicar noticias o crear eventos.
Gestión de eventos más completa.
Imágenes para noticias y eventos.
Fase 10: Patrocinadores
Estado: no iniciado, 0%.

Pendiente completamente:

Patrocinadores.
Contratos.
Importes.
Fechas.
Beneficios.
Estado.
Visibilidad pública.
Integración con dashboard y tesorería.
Fase 11: Porras
Estado: no iniciado, 0%.

Debe permanecer bloqueado hasta realizar el análisis jurídico correspondiente.

Pendientes técnicos importantes
Prioridad alta:

Añadir audit_logs y auditoría real.
Revisar las políticas RLS de notificaciones para que target tenga efecto real.
Completar gestión de usuarios y roles.
Añadir tests de permisos, reservas y sorteos.
Verificar todas las RPC directamente contra Supabase.
Completar la configuración de producción y despliegue.
Prioridad media:

Marcar notificaciones como leídas.
Completar eventos y noticias con imágenes.
Mejorar métricas del dashboard.
Completar perfiles y directiva.
Añadir filtros e importación de socios.
Prioridad baja o posterior:

Firebase Cloud Messaging.
Patrocinadores.
Pagos reales.
Porras.
Aplicaciones móviles específicas.
Estado de calidad
flutter analyze: validado sin errores en las últimas comprobaciones.
Tests actuales: 5 pruebas de dominio.
Supabase: migraciones 001-015 aplicadas.
GitHub: actualizado.
Compilación web: pendiente de ejecutar; fue detenida anteriormente por indicación del usuario.
Pagos reales: desactivados correctamente.
Árbol de código: los commits están publicados; quedan archivos locales del CLI de Supabase sin versionar.
Prioridad recomendada inmediata
El siguiente orden aconsejado es:

Implementar auditoría y revisar RLS.
Completar permisos y gestión de usuarios.
Añadir tests de seguridad y reglas de negocio.
Mejorar notificaciones internas.
Seleccionar proveedor push.
Ejecutar una compilación web limpia.
Preparar patrocinadores como siguiente módulo funcional.
En términos de producto, el proyecto ya tiene una base sólida de gestión de clubes, tesorería, rifas y comunicación. Lo que falta ahora es principalmente endurecer seguridad, permisos, auditoría, pruebas y preparación para producción.

## Complemento operativo para cualquier IA

### Punto de entrada del programa

La ejecución comienza en `lib/main.dart`:

1. Inicializa Flutter.
2. Ejecuta `SupabaseService.initialize()`.
3. Arranca `ClubPlatformApp` dentro de `ProviderScope`.

La configuración de Supabase depende de `SUPABASE_URL` y `SUPABASE_ANON_KEY` mediante `--dart-define`. Sin esos valores, los repositorios usan datos demo y no deben interpretarse como persistencia real.

### Mapa de responsabilidades

- `lib/app/router.dart`: autenticación, deep links y asociación entre URL y Page.
- `lib/app/app.dart`: `MaterialApp.router`, tema y configuración global.
- `lib/app/app_theme.dart`: colores, tipografía, superficies y componentes Material.
- `lib/core/services/supabase_service.dart`: inicialización y detección de Supabase configurado.
- `lib/features/*/domain/entities`: modelos inmutables y deserialización.
- `lib/features/*/data/repositories`: acceso a Supabase y fallback demo.
- `lib/features/*/presentation/pages`: pantallas, formularios y estados de carga/error.
- `supabase/migrations`: contrato real de PostgreSQL, RLS, funciones y restricciones.
- `test`: pruebas unitarias y widget; no colocar lógica de Supabase real en tests unitarios.

Una modificación de negocio debe reflejarse en las dos fronteras: entidad/repositorio Flutter y tabla/RPC/RLS de Supabase. No resolver una regla de seguridad únicamente en la Page.

### Contratos que hay que respetar

- La base usa nombres SQL `snake_case`; Dart usa nombres `camelCase`.
- `EventVisibility.clubOnly` se serializa como `club_only`; el parser ya contempla esa diferencia.
- `RaffleStatus.soldOut` y cualquier enum Dart compuesto no coinciden automáticamente con un valor SQL como `sold_out`. Antes de añadir estados, crear un mapeo explícito en ambos sentidos.
- Los datos públicos deben llegar mediante RPC o consulta con columnas explícitas. No usar `select('*')` en páginas públicas.
- Un `buyer_profile_id`, email, teléfono, dirección, fecha de nacimiento, `tax_id` o token de dispositivo nunca puede aparecer en una RPC pública.
- Las operaciones que cambian dinero, tickets confirmados, sorteos, permisos o historial deben ser transacciones/RPC server-side.

### Riesgos técnicos ya localizados

1. `notifications_select_member` permite leer todas las notificaciones del club y no aplica todavía el campo `target`. Antes de producción debe existir una relación de entrega por usuario o una política/RPC que filtre destinatarios.
2. `user_devices` tiene repositorio y RLS, pero ningún punto del ciclo de vida de la app registra el dispositivo. No inventar Firebase ni un proveedor hasta tomar esa decisión.
3. `raffle_draws` registra el sorteo, pero el flujo todavía necesita auditoría formal y una consulta administrativa del historial.
4. El dashboard mantiene algún dato demo en métricas de rifas y actividad. Toda métrica nueva debe proceder de un provider/repository, no de literales en la Page.
5. La ruta administrativa `/raffles/:raffleId` soporta recarga directa recuperando la rifa por `club_id` e ID. Cualquier nueva ruta autenticada debe seguir ese patrón y no depender solo de `state.extra`.
6. `get_public_club` se amplió mediante `DROP FUNCTION` y recreación en `015`; futuras migraciones que cambien un `RETURNS TABLE` deben seguir este procedimiento.

### Cómo implementar el siguiente bloque

Para cada feature nueva, crear como mínimo:

```text
lib/features/<feature>/domain/entities/<entity>.dart
lib/features/<feature>/data/repositories/<entity>_repository.dart
lib/features/<feature>/presentation/pages/<feature>_page.dart
supabase/migrations/<NNN>_<feature>.sql
```

La Page debe cubrir loading, error, vacío, validación y éxito. El Repository debe tener una ruta Supabase y una ruta demo explícita. La migración debe incluir tipos, tabla, índices, trigger `set_updated_at` si aplica, RLS y funciones públicas/privadas separadas.

Para modificar una tabla existente:

1. Crear una migración nueva, nunca editar una ya aplicada.
2. Mantener compatibilidad con datos existentes.
3. Comprobar permisos de lectura y escritura por rol.
4. Aplicar la migración en Supabase.
5. Añadir una prueba de deserialización o regla de negocio.

### Próximo trabajo recomendado, en orden técnico

#### 1. Auditoría y permisos

Crear `016_audit_logs.sql` con `audit_logs`, RLS de lectura para managers y una función privada de inserción. Después conectar primero sorteos, cambios de roles, movimientos financieros y exportaciones. No permitir que el cliente escriba libremente acciones de auditoría.

#### 2. Seguridad de notificaciones

Crear una tabla de entregas, por ejemplo `notification_deliveries`, con `notification_id`, `profile_id`, `read_at` y timestamps. La bandeja debe consultar solo entregas del usuario actual y los managers deben poder crear notificaciones mediante una RPC controlada.

#### 3. Tests de negocio

Separar una prueba por regla: número de rifa duplicado, reserva expirada, sorteo sin tickets pagados, segundo sorteo, visibilidad pública de eventos/posts y aislamiento entre clubes. Usar repositorios falsos o entidades puras; no depender de una base remota en unit tests.

#### 4. Integración de dispositivos

Solo después de decidir proveedor: implementar el permiso específico de Web/Android/iOS, registrar token con `registerDevice`, eliminarlo con `unregisterDevice` y probar revocación. El envío debe residir en backend/Edge Function, nunca en el cliente con secretos.

#### 5. Producción web

Antes de desplegar, ejecutar análisis, tests y build en una terminal limpia; inspeccionar rutas públicas, variables de entorno, `web/index.html`, service worker y deep links del hosting. `build/` es salida generada y no debe editarse manualmente.

### Protocolo de trabajo para la IA

Antes de editar:

- Leer este informe y la arquitectura maestra.
- Localizar la Page, entidad, Repository, ruta y migración relacionada.
- Formular una hipótesis concreta sobre el comportamiento.
- Elegir una prueba que pueda refutarla.

Durante la implementación:

- Mantener Riverpod, `go_router`, Supabase y feature-first.
- Usar nombres de código en inglés y textos de interfaz en español.
- No introducir Bloc, GetX, Firebase, otro backend ni pagos reales sin decisión explícita.
- No modificar migraciones aplicadas; añadir una nueva.
- No usar claves, contraseñas ni tokens en archivos o commits.
- No incluir `build/`, ZIPs, ejecutables ni `.temp/` del CLI en Git.

Después de editar:

```powershell
flutter analyze --no-pub
flutter test --reporter expanded
git diff --check
```

Con Supabase enlazado, aplicar solo la migración nueva:

```powershell
.\supabase_2.117.0-beta.18_windows_amd64\supabase.exe db push
```

Si la CLI solicita una contraseña, introducirla directamente en la terminal y no compartirla con la IA.

### Definición de terminado para una feature

Una feature no se considera terminada porque la pantalla cargue en modo demo. Debe cumplir simultáneamente:

- modelo y serialización comprobados;
- Repository demo y Supabase coherentes;
- RLS probado contra el club correcto;
- loading, vacío, error y validaciones visibles;
- deep link si la ruta es navegable;
- prueba de la regla principal;
- migración aplicada si usa Supabase;
- sin datos privados en consultas públicas;
- análisis y tests en verde;
- documentación de cualquier decisión nueva.

### Decisiones que siguen bloqueadas

- Firebase Cloud Messaging y proveedor push.
- Pagos reales y proveedor de pagos.
- Porras y cualquier mecánica regulada.
- Publicación automática en redes sociales.
- Offline y sincronización local.

Hasta tomar esas decisiones, el código debe continuar con simulación, RPCs seguras, datos demo y estados explícitos, sin crear una falsa apariencia de pago o entrega push real.