// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): refuerza la restricción de nombramiento de presidente.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Role =
  | "club_president" | "club_treasurer" | "club_secretary" | "team_manager"
  | "coach" | "staff" | "member" | "parent_guardian" | "player" | "follower";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const body = await req.json();
    const { clubId, email, password, role, firstName, lastName } =
      body as { clubId: string; email: string; password: string; role: Role; firstName?: string; lastName?: string };

    if (!clubId || !email || !password || !role) throw new Error("Faltan datos obligatorios.");
    if (role === "club_president") throw new Error("El nombramiento de presidente está reservado al administrador de plataforma.");
    if (password.length < 8) throw new Error("La contraseña inicial debe tener al menos 8 caracteres.");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Autenticación requerida.");

    const callerClient = createClient(supabaseUrl, serviceKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user: caller }, error: callerError } = await callerClient.auth.getUser();
    if (callerError || !caller) throw new Error("Sesión no válida.");

    const admin = createClient(supabaseUrl, serviceKey);

    const { data: manager } = await admin
      .from("club_memberships")
      .select("role")
      .eq("club_id", clubId)
      .eq("profile_id", caller.id)
      .eq("is_active", true)
      .eq("role", "club_president")
      .maybeSingle();

    if (!manager) throw new Error("Solo el presidente puede gestionar los accesos de este club.");

    let targetUserId: string | undefined;
    const created = await admin.auth.admin.createUser({
      email: email.trim().toLowerCase(),
      password,
      email_confirm: true,
      user_metadata: { first_name: firstName?.trim() ?? "", last_name: lastName?.trim() ?? "" },
    });

    if (!created.error && created.data.user) {
      targetUserId = created.data.user.id;
    } else {
      const { data: profile } = await admin
        .from("profiles")
        .select("id")
        .eq("email", email.trim().toLowerCase())
        .maybeSingle();
      if (!profile) throw new Error("No se ha podido crear o localizar la cuenta para ese email.");
      targetUserId = profile.id;
    }

    const { error: profileError } = await admin.from("profiles").update({
      first_name: firstName?.trim() || null,
      last_name: lastName?.trim() || null,
      must_change_password: true,
    }).eq("id", targetUserId);
    if (profileError) throw profileError;

    const { error: membershipError } = await admin.from("club_memberships").upsert({
      club_id: clubId,
      profile_id: targetUserId,
      role,
      is_active: true,
    }, { onConflict: "club_id,profile_id,role" });
    if (membershipError) throw membershipError;

    await admin.from("audit_logs").insert({
      club_id: clubId,
      actor_profile_id: caller.id,
      action: "permission_change",
      entity_type: "club_membership",
      entity_id: targetUserId,
      data: { action: "create_or_activate", role, email: email.trim().toLowerCase() },
    });

    return new Response(JSON.stringify({ success: true, userId: targetUserId }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, message: error instanceof Error ? error.message : "Error interno." }), {
      status: 400,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
