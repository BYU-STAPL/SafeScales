import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type StaffProfile = {
  id: string;
  role: string;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function syntheticEmail(userId: string): string {
  return `${userId}@class.safescales.internal`;
}

function randomPassword(): string {
  return `${crypto.randomUUID()}-Aa1!`;
}

function isStaffRole(role: string | null | undefined): boolean {
  return ["instructor", "researcher", "admin"].includes(
    String(role ?? "").toLowerCase(),
  );
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return jsonResponse({ error: "Server misconfigured" }, 500);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing Authorization bearer token" }, 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: "Invalid session" }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: callerProfile, error: profileError } = await admin
      .from("Users")
      .select("id, role")
      .eq("id", user.id)
      .single();

    if (profileError || !callerProfile || !isStaffRole(callerProfile.role)) {
      return jsonResponse({ error: "Staff access required" }, 403);
    }

    const staff = callerProfile as StaffProfile;
    const body = await req.json();
    const action = String(body.action ?? "");

    const assertsInstructsClass = async (classId: string) => {
      if (["researcher", "admin"].includes(staff.role.toLowerCase())) {
        return;
      }
      const { data: classRow, error } = await admin
        .from("classes")
        .select("id, instructor_id")
        .eq("id", classId)
        .single();
      if (error || !classRow) {
        throw new Error("Class not found");
      }
      if (classRow.instructor_id !== staff.id) {
        throw new Error("You do not instruct this class");
      }
    };

    if (action === "create_classroom_student") {
      const username = String(body.username ?? "").trim();
      const classId = body.classId ? String(body.classId) : null;
      if (!username) {
        return jsonResponse({ error: "username is required" }, 400);
      }
      if (classId) {
        await assertsInstructsClass(classId);
      }

      const userId = crypto.randomUUID();
      const email = syntheticEmail(userId);
      const password = randomPassword();

      const { error: createAuthError } = await admin.auth.admin.createUser({
        id: userId,
        email,
        password,
        email_confirm: true,
        user_metadata: { username, classroom: true, role: "student" },
      });
      if (createAuthError) {
        return jsonResponse({ error: createAuthError.message }, 500);
      }

      const updates: Record<string, unknown> = {
        Username: username,
        role: "student",
      };
      if (classId) {
        updates.joined_classes = [classId];
      }

      const { data: profile, error: updateError } = await admin
        .from("Users")
        .update(updates)
        .eq("id", userId)
        .select("*")
        .single();

      if (updateError) {
        return jsonResponse({ error: updateError.message }, 500);
      }

      return jsonResponse({ profile });
    }

    if (action === "enroll_student") {
      const userId = String(body.userId ?? "");
      const classId = String(body.classId ?? "");
      if (!userId || !classId) {
        return jsonResponse({ error: "userId and classId are required" }, 400);
      }
      await assertsInstructsClass(classId);

      const { data: profile, error: fetchError } = await admin
        .from("Users")
        .select("id, joined_classes")
        .eq("id", userId)
        .single();
      if (fetchError || !profile) {
        return jsonResponse({ error: "Student not found" }, 404);
      }

      const joined = Array.isArray(profile.joined_classes)
        ? profile.joined_classes.map(String)
        : [];
      if (!joined.includes(classId)) {
        joined.push(classId);
      }

      const { data: updated, error: updateError } = await admin
        .from("Users")
        .update({ joined_classes: joined })
        .eq("id", userId)
        .select("id, Username, Email, role, joined_classes, modules")
        .single();
      if (updateError) {
        return jsonResponse({ error: updateError.message }, 500);
      }
      return jsonResponse({ profile: updated });
    }

    if (action === "unenroll_student") {
      const userId = String(body.userId ?? "");
      const classId = String(body.classId ?? "");
      if (!userId || !classId) {
        return jsonResponse({ error: "userId and classId are required" }, 400);
      }
      await assertsInstructsClass(classId);

      const { data: profile, error: fetchError } = await admin
        .from("Users")
        .select("id, joined_classes")
        .eq("id", userId)
        .single();
      if (fetchError || !profile) {
        return jsonResponse({ error: "Student not found" }, 404);
      }

      const joined = (Array.isArray(profile.joined_classes)
        ? profile.joined_classes.map(String)
        : []
      ).filter((id) => id !== classId);

      const { data: updated, error: updateError } = await admin
        .from("Users")
        .update({ joined_classes: joined })
        .eq("id", userId)
        .select("id, Username, Email, role, joined_classes, modules")
        .single();
      if (updateError) {
        return jsonResponse({ error: updateError.message }, 500);
      }
      return jsonResponse({ profile: updated });
    }

    if (action === "list_class_students") {
      const classId = String(body.classId ?? "");
      if (!classId) {
        return jsonResponse({ error: "classId is required" }, 400);
      }
      await assertsInstructsClass(classId);

      const { data: students, error } = await admin
        .from("Users")
        .select("id, Username, Email, role, modules, joined_classes")
        .contains("joined_classes", [classId]);
      if (error) {
        return jsonResponse({ error: error.message }, 500);
      }
      return jsonResponse({ students: students ?? [] });
    }

    if (action === "set_username") {
      const userId = String(body.userId ?? "");
      const username = String(body.username ?? "").trim();
      const classId = String(body.classId ?? "");
      if (!userId || !username || !classId) {
        return jsonResponse(
          { error: "userId, username, and classId are required" },
          400,
        );
      }
      await assertsInstructsClass(classId);

      const { data: profile, error: fetchError } = await admin
        .from("Users")
        .select("id, joined_classes")
        .eq("id", userId)
        .single();
      if (fetchError || !profile) {
        return jsonResponse({ error: "Student not found" }, 404);
      }
      const joined = Array.isArray(profile.joined_classes)
        ? profile.joined_classes.map(String)
        : [];
      if (!joined.includes(classId)) {
        return jsonResponse({ error: "Student is not in this class" }, 403);
      }

      const { data: updated, error: updateError } = await admin
        .from("Users")
        .update({ Username: username })
        .eq("id", userId)
        .select("id, Username, Email, role, joined_classes, modules")
        .single();
      if (updateError) {
        return jsonResponse({ error: updateError.message }, 500);
      }
      return jsonResponse({ profile: updated });
    }

    return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = /not found/i.test(message)
      ? 404
      : /do not instruct|Staff access|Invalid session/i.test(message)
        ? 403
        : 500;
    return jsonResponse({ error: message }, status);
  }
});
