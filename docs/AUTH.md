# SafeScales Student App Auth

This app shares Supabase project `mqeijlaukrmcirwadrhl` with the instructor dashboard.

## Sign-in paths

1. **Independent Learning** — email + password via Supabase Auth (`signInWithPassword` / `signUp`).
2. **Join a Class** — class code + username via Edge Function `class-code-auth`, then `auth.setSession`.

Passwords live only in **Supabase Auth** (`auth.users`). Profile data lives in `public."Users"`.  
**`Users.id` must equal `auth.users.id`.**

## Password reset / first-time Auth setup

1. On Independent Learning login, use **Forgot / set up password**.
2. App calls `resetPasswordForEmail` with `redirectTo` = current web origin, or `com.safescales.byu://set-password` on Android.
3. Opening the email link creates a `PASSWORD_RECOVERY` session.
4. `onAuthStateChange` defers async work (microtask) so `updateUser({ password })` cannot deadlock GoTrue’s lock.
5. After a successful password update, the app sets `Users.settings.auth_password_confirmed_at` and `must_set_password: false`. Auth user-metadata sync is best-effort and must not block the UI.

## Supabase Auth URL Configuration (required)

In the Supabase dashboard → **Authentication → URL Configuration**:

| Setting | Value |
|---------|--------|
| **Site URL** | Production student web URL (not `http://localhost:3000` unless local-only) |
| **Redirect URLs** | Production web origin, local web origin(s), and `com.safescales.byu://set-password` |

If `redirectTo` is not allowlisted, Auth falls back to Site URL — that caused localhost reset links in production.

## Profile columns

After Auth migration, progress is stored in `reading_progress` (mapped to app “modules” progress). Profile selects use:

`id, Username, Email, role, dragons, acquired_accessories, acquired_environments, joined_classes, settings, reading_progress, …`

Do not select non-existent columns such as `quizzes`. Errors from PostgREST / Auth are surfaced via `getErrorMessage` (reads `.message` from typed exceptions and plain maps).

## Missing profile

If Auth succeeds but `Users` has no row for that id (`PGRST116`), the UI shows that `Users.id` must match `auth.users.id` for that email — not a generic “Login failed”.

Verify linkage:

```sql
select u.id as users_id, a.id as auth_id, u."Email", u.role
from public."Users" u
full outer join auth.users a on lower(u."Email") = lower(a.email)
where lower(coalesce(u."Email", a.email)) = '<user-email>';
```

`users_id` and `auth_id` must match.

## Related code

- `lib/services/auth_service.dart`
- `lib/services/user_state_service.dart`
- `lib/utils/supabase_errors.dart`
- `lib/config/auth_redirect.dart`
- `lib/ui/screens/auth_screen.dart`
- `lib/ui/screens/set_password_screen.dart`
- Dashboard reference: `SafeScales-Dashboard/src/lib/auth.ts`
