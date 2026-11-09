import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ClassRow = {
  id: string;
  code: string;
  course_modules: unknown;
  assets: unknown;
  default_habitat: unknown;
  default_item: unknown;
};

type UserRow = Record<string, unknown> & {
  id: string;
  Username?: string | null;
  Email?: string | null;
  joined_classes?: string[] | null;
  acquired_environments?: unknown;
  acquired_accessories?: unknown;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function parseDefaultIds(value: unknown): string[] {
  if (value == null) return [];
  if (Array.isArray(value)) {
    return value
      .map((e) => e?.toString().trim())
      .filter((s): s is string => !!s && s.length > 0);
  }
  if (typeof value === "string") {
    const s = value.trim();
    if (!s) return [];
    try {
      const decoded = JSON.parse(s);
      if (Array.isArray(decoded)) {
        return decoded
          .map((e) => e?.toString().trim())
          .filter((s): s is string => !!s && s.length > 0);
      }
      return [s];
    } catch {
      return [s];
    }
  }
  return [];
}

function resolveDefaultIdsFromAssets(
  classAssets: Array<Record<string, unknown>>,
  defaultHabitatIds: string[],
  defaultItemIds: string[],
): { envIds: string[]; itemIds: string[] } {
  const assetIdsByType = new Map<string, string>();
  for (const asset of classAssets) {
    const id = asset.id?.toString();
    if (!id) continue;
    const type = asset.type?.toString();
    if (type === "environment" || type === "accessory") {
      assetIdsByType.set(id, type);
    }
  }

  return {
    envIds: defaultHabitatIds.filter(
      (id) => assetIdsByType.get(id) === "environment",
    ),
    itemIds: defaultItemIds.filter(
      (id) => assetIdsByType.get(id) === "accessory",
    ),
  };
}

function asIdList(raw: unknown): string[] {
  if (raw == null) return [];
  if (Array.isArray(raw)) {
    return raw.map((e) => e?.toString()).filter((s): s is string => !!s);
  }
  if (typeof raw === "object") {
    return Object.values(raw as Record<string, unknown>)
      .map((e) => e?.toString())
      .filter((s): s is string => !!s);
  }
  return [];
}

function syntheticEmail(userId: string): string {
  return `${userId}@class.safescales.internal`;
}

function randomPassword(): string {
  // bcrypt truncates above 72 bytes; keep well under that limit.
  return `${crypto.randomUUID()}-Aa1!`;
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

    const body = await req.json();
    const classCode = String(body.classCode ?? "")
      .replace(/\x1B\[[0-9;]*[a-zA-Z]/g, "")
      .trim();
    const username = String(body.username ?? "").trim();

    if (!classCode || !username) {
      return jsonResponse(
        { error: "classCode and username are required" },
        400,
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const anon = createClient(supabaseUrl, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: classMatches, error: classError } = await admin
      .from("classes")
      .select("id, code, course_modules, assets, default_habitat, default_item")
      .ilike("code", classCode);

    if (classError) {
      return jsonResponse({ error: classError.message }, 500);
    }
    if (!classMatches || classMatches.length === 0) {
      return jsonResponse({ error: "Invalid class code" }, 400);
    }

    const classRow = classMatches[0] as ClassRow;
    const classId = classRow.id;
    const classAssets = Array.isArray(classRow.assets)
      ? (classRow.assets as Array<Record<string, unknown>>)
      : [];
    const { envIds: defaultEnvIds, itemIds: defaultItemIds } =
      resolveDefaultIdsFromAssets(
        classAssets,
        parseDefaultIds(classRow.default_habitat),
        parseDefaultIds(classRow.default_item),
      );

    const { data: usernameMatches, error: userLookupError } = await admin
      .from("Users")
      .select("*")
      .eq("Username", username);

    if (userLookupError) {
      return jsonResponse({ error: userLookupError.message }, 500);
    }

    const candidates = (usernameMatches ?? []) as UserRow[];
    const alreadyInClass = candidates.find((u) =>
      (u.joined_classes ?? []).map(String).includes(classId),
    );
    let profile = alreadyInClass ?? candidates[0] ?? null;
    let isNewJoin = false;
    let isWelcomeBack = false;

    if (profile) {
      const joined = [...(profile.joined_classes ?? [])].map(String);
      if (joined.includes(classId)) {
        isWelcomeBack = true;
      } else {
        joined.push(classId);
        const updates: Record<string, unknown> = {
          joined_classes: joined,
        };

        if (defaultEnvIds.length > 0) {
          const acquiredEnvs = asIdList(profile.acquired_environments);
          let changed = false;
          for (const id of defaultEnvIds) {
            if (!acquiredEnvs.includes(id)) {
              acquiredEnvs.push(id);
              changed = true;
            }
          }
          if (changed) updates.acquired_environments = acquiredEnvs;
        }

        if (defaultItemIds.length > 0) {
          const acquiredAcc = asIdList(profile.acquired_accessories);
          let changed = false;
          for (const id of defaultItemIds) {
            if (!acquiredAcc.includes(id)) {
              acquiredAcc.push(id);
              changed = true;
            }
          }
          if (changed) updates.acquired_accessories = acquiredAcc;
        }

        const { data: updated, error: updateError } = await admin
          .from("Users")
          .update(updates)
          .eq("id", profile.id)
          .select("*")
          .single();
        if (updateError) {
          return jsonResponse({ error: updateError.message }, 500);
        }
        profile = updated as UserRow;
        isNewJoin = true;
      }
    } else {
      const userId = crypto.randomUUID();
      const initialReadingProgress: Record<string, unknown> = {};
      const moduleIds = Array.isArray(classRow.course_modules)
        ? classRow.course_modules
        : [];
      for (const moduleId of moduleIds) {
        initialReadingProgress[String(moduleId)] = {
          reading: {
            completed: false,
            completed_at: null,
            bookmarks: [],
          },
        };
      }

      const initialDragonData: Record<string, unknown> = {};
      for (const asset of classAssets) {
        if (asset.type !== "dragon") continue;
        const dragonId = asset.id?.toString();
        if (!dragonId) continue;
        initialDragonData[dragonId] = {
          name: "no name",
          phases: ["egg"],
        };
      }

      const initialDragonEnvironments: Record<string, unknown> = {};
      const firstDefaultEnvId = defaultEnvIds[0];
      if (firstDefaultEnvId) {
        for (const dragonId of Object.keys(initialDragonData)) {
          initialDragonEnvironments[dragonId] = firstDefaultEnvId;
        }
      }

      const tempPassword = randomPassword();
      const email = syntheticEmail(userId);
      const { error: createAuthError } = await admin.auth.admin.createUser({
        id: userId,
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { username, classroom: true },
      });
      if (createAuthError) {
        return jsonResponse({ error: createAuthError.message }, 500);
      }

      // Trigger inserts a stub; update classroom profile fields (avoid role/Email).
      const { data: createdProfile, error: profileError } = await admin
        .from("Users")
        .update({
          Username: username,
          joined_classes: [classId],
          settings: { fontSize: 1.0, isDarkMode: false },
          dragons: initialDragonData,
          acquired_accessories: defaultItemIds,
          acquired_environments: defaultEnvIds,
          dragon_preferred_phases: {},
          dragon_environments: initialDragonEnvironments,
          dragon_dressup: {},
          reading_progress: initialReadingProgress,
        })
        .eq("id", userId)
        .select("*")
        .single();

      if (profileError) {
        return jsonResponse({ error: profileError.message }, 500);
      }

      profile = createdProfile as UserRow;

      const { data: sessionData, error: signInError } = await anon.auth
        .signInWithPassword({ email, password: tempPassword });
      if (signInError || !sessionData.session) {
        return jsonResponse(
          { error: signInError?.message ?? "Failed to create session" },
          500,
        );
      }

      return jsonResponse({
        access_token: sessionData.session.access_token,
        refresh_token: sessionData.session.refresh_token,
        user: sessionData.user,
        profile,
        welcome_back: false,
        joined_new_class: true,
      });
    }

    // Existing profile: ensure Auth user exists, then mint a session.
    const userId = String(profile.id);
    let email =
      (typeof profile.Email === "string" && profile.Email.includes("@")
        ? profile.Email
        : null) ?? syntheticEmail(userId);
    const tempPassword = randomPassword();

    const { data: existingAuth, error: getUserError } = await admin.auth.admin
      .getUserById(userId);

    if (getUserError || !existingAuth.user) {
      const { error: createAuthError } = await admin.auth.admin.createUser({
        id: userId,
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { username, classroom: true },
      });
      if (createAuthError) {
        // Email may already belong to another auth user; fall back to synthetic.
        email = syntheticEmail(userId);
        const { error: retryError } = await admin.auth.admin.createUser({
          id: userId,
          email,
          password: tempPassword,
          email_confirm: true,
          user_metadata: { username, classroom: true },
        });
        if (retryError) {
          return jsonResponse({ error: retryError.message }, 500);
        }
      }
    } else {
      email = existingAuth.user.email ?? email;
      const { error: updateAuthError } = await admin.auth.admin.updateUserById(
        userId,
        { password: tempPassword, email_confirm: true },
      );
      if (updateAuthError) {
        return jsonResponse({ error: updateAuthError.message }, 500);
      }
    }

    const { data: sessionData, error: signInError } = await anon.auth
      .signInWithPassword({ email, password: tempPassword });
    if (signInError || !sessionData.session) {
      return jsonResponse(
        { error: signInError?.message ?? "Failed to create session" },
        500,
      );
    }

    const { data: freshProfile } = await admin
      .from("Users")
      .select("*")
      .eq("id", userId)
      .single();

    return jsonResponse({
      access_token: sessionData.session.access_token,
      refresh_token: sessionData.session.refresh_token,
      user: sessionData.user,
      profile: freshProfile ?? profile,
      welcome_back: isWelcomeBack,
      joined_new_class: isNewJoin,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});
