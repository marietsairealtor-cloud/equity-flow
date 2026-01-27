-- Expose v_entitlements to anon (PostgREST schema cache uses anon)

grant select on public.v_entitlements to anon;

-- PostgREST listens on channel "pgrst"
notify pgrst, 'reload schema';