# Despliegue de Edge Functions

## manage-club-user

Desde la raíz del repositorio:

```powershell
.\supabase_2.117.0-beta.18_windows_amd64\supabase.exe functions deploy manage-club-user --use-api
```

`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` se leen del entorno de Supabase Edge Functions; no guardes sus valores en el repositorio.

La función permite CORS únicamente desde los orígenes enumerados en `ALLOWED_ORIGINS` (lista separada por comas y comparación exacta). Configura el dominio real que sirve Flutter Web en Supabase Secrets o con un placeholder sustituido localmente:

```powershell
.\supabase_2.117.0-beta.18_windows_amd64\supabase.exe secrets set ALLOWED_ORIGINS="https://<dominio-frontend>"
```

No añadas `*`. Hasta configurar el origen de producción, las peticiones del navegador deben fallar el preflight; las solicitudes sin cabecera Origin solo se aceptan si presentan un JWT válido.

## Reinicio / actualización

Las Edge Functions no mantienen un proceso que requiera reinicio manual. Para activar una nueva versión, vuelve a desplegarla con el mismo comando `functions deploy`. Confirma el deployment en el panel de Supabase y prueba la invocación desde un presidente activo.
