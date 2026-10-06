// MODIFICADO POR GITHUB COPILOT (2026-10-06): autentica actor, restringe roles y evita exponer datos de cuentas existentes.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const allowedRoles = new Set([
  "club_treasurer",
  "club_secretary",
  "team_manager",
  "coach",
  "staff",
  "member",
  "parent_guardian",
  "player",
  "follower",
]);

type CreateUserRequest = {
  clubId: unknown;
  email: unknown;
  password: unknown;
  role: unknown;
  firstName: unknown;
  lastName: unknown;
};

const responseHeaders = (origin: string | null, allowed: boolean): HeadersInit => {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Vary": "Origin",
  };
  if (origin && allowed) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Access-Control-Allow-Headers"] = "authorization, x-client-info, apikey, content-type";
    headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
  }
  return headers;
};

function allowedOrigins(): Set<string> {
  return new Set(
    (Deno.env.get("ALLOWED_ORIGINS") ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0),
  );
}

function normalizeName(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.normalize("NFKC").trim().replace(/\s+/g, " ");
  if (normalized.length < 1 || normalized.length > 80 || /[\u0000-\u001f\u007f]/.test(normalized)) return null;
  return normalized;
}

function normalizeEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (normalized.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) return null;
  return normalized;
}

function isUuid(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function jsonResponse(
  origin: string | null,
  originAllowed: boolean,
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: responseHeaders(origin, originAllowed),
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");
  const origins = allowedOrigins();
  const originAllowed = origin === null || origins.has(origin);

  if (!originAllowed) {
    return jsonResponse(null, false, 403, { success: false, message: "Solicitud no autorizada." });
  }
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: responseHeaders(origin, true),
    });
  }
  if (req.method !== "POST") {
    return jsonResponse(origin, true, 405, { success: false, message: "Método no permitido." });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
    }

    const authorization = req.headers.get("Authorization") ?? "";
    const tokenMatch = /^Bearer\s+(\S+)$/i.exec(authorization);
    if (!tokenMatch) {
      return jsonResponse(origin, true, 401, { success: false, message: "Autenticación requerida." });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: userData, error: userError } = await admin.auth.getUser(tokenMatch[1]);
    const actor = userData.user;
    if (userError || !actor) {
      return jsonResponse(origin, true, 401, { success: false, message: "Autenticación no válida." });
    }

    let body: CreateUserRequest;
    try {
      body = await req.json() as CreateUserRequest;
    } catch {
      return jsonResponse(origin, true, 400, { success: false, message: "Solicitud no válida." });
    }

    const clubId = body?.clubId;
    const email = normalizeEmail(body?.email);
    const firstName = normalizeName(body?.firstName);
    const lastName = normalizeName(body?.lastName);
    const password = body?.password;
    const role = body?.role;

    if (!isUuid(clubId) || !email || !firstName || !lastName ||
        typeof password !== "string" || password.length < 8 || password.length > 128 ||
        typeof role !== "string" || !allowedRoles.has(role)) {
      return jsonResponse(origin, true, 400, { success: false, message: "Los datos enviados no son válidos." });
    }

    const { data: president, error: membershipCheckError } = await admin
      .from("club_memberships")
      .select("id")
      .eq("club_id", clubId)
      .eq("profile_id", actor.id)
      .eq("role", "club_president")
      .eq("is_active", true)
      .maybeSingle();
    if (membershipCheckError) {
      return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
    }
    if (!president) {
      return jsonResponse(origin, true, 403, { success: false, message: "No tienes permisos para gestionar accesos." });
    }

    let targetProfileId: string;
    let isNewUser = false;
    const { data: createdUser, error: createError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { first_name: firstName, last_name: lastName },
    });

    if (!createError && createdUser.user) {
      targetProfileId = createdUser.user.id;
      isNewUser = true;
    } else {
      const { data: existingProfile, error: profileLookupError } = await admin
        .from("profiles")
        .select("id")
        .eq("email", email)
        .maybeSingle();
      if (profileLookupError || !existingProfile) {
        return jsonResponse(origin, true, 400, { success: false, message: "No se pudo crear el acceso." });
      }
      targetProfileId = existingProfile.id as string;
    }

    if (isNewUser) {
      const { error: profileUpdateError } = await admin
        .from("profiles")
        .update({
          first_name: firstName,
          last_name: lastName,
          must_change_password: true,
        })
        .eq("id", targetProfileId);
      if (profileUpdateError) {
        return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
      }
    }

    const { error: membershipUpsertError } = await admin
      .from("club_memberships")
      .upsert({
        club_id: clubId,
        profile_id: targetProfileId,
        role,
        is_active: true,
      }, { onConflict: "club_id,profile_id,role" });
    if (membershipUpsertError) {
      return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
    }

    const { error: auditError } = await admin.from("audit_logs").insert({
      club_id: clubId,
      actor_profile_id: actor.id,
      action: "permission_change",
      entity_type: "club_membership",
      entity_id: targetProfileId,
      data: { action: isNewUser ? "create_access" : "activate_access", role },
    });
    if (auditError) {
      return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
    }

    return jsonResponse(origin, true, 200, { success: true });
  } catch {
    return jsonResponse(origin, true, 500, { success: false, message: "No se pudo completar la solicitud." });
  }
});
