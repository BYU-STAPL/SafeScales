CREATE OR REPLACE FUNCTION public.prevent_users_privilege_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'Users.id cannot be changed';
  END IF;
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Users.role cannot be changed by clients';
  END IF;
  IF NEW."Email" IS DISTINCT FROM OLD."Email" THEN
    RAISE EXCEPTION 'Users.Email cannot be changed by clients';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO postgres, service_role, supabase_auth_admin;

REVOKE ALL ON FUNCTION public.prevent_users_privilege_escalation() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prevent_users_privilege_escalation() FROM anon, authenticated;
