select
  p.proname as name,
  pg_get_function_identity_arguments(p.oid) as args,
  pg_get_function_result(p.oid) as returns
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = any (array[
    'create_workspace',
    'get_entitlements',
    'set_current_tenant_rpc',
    'create_invite_rpc',
    'get_invites_rpc',
    'accept_invite_rpc',
    'revoke_invite_rpc'
  ])
order by p.proname, args;