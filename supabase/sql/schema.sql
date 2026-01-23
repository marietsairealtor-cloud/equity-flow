-- Enable Row Level Security
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

-- Tenants table
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tenant memberships table
CREATE TABLE IF NOT EXISTS public.tenant_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, user_id)
);

-- Deals table
CREATE TABLE IF NOT EXISTS public.deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit log table
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    user_id UUID REFERENCES auth.users(id),
    changes JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to get current tenant ID from JWT claim
CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS UUID AS $$
BEGIN
    RETURN (current_setting('request.jwt.claims', true)::json->>'tenant_id')::UUID;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to check if user can write to current tenant
CREATE OR REPLACE FUNCTION public.can_write_current_tenant()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.tenant_memberships tm
        WHERE tm.user_id = auth.uid()
          AND tm.tenant_id = public.current_tenant_id()
          AND tm.role IN ('owner', 'admin')
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Audit Log Policies
CREATE POLICY audit_log_select_own_tenant ON public.audit_log
    FOR SELECT
    TO authenticated
    USING (tenant_id = current_tenant_id());

-- Deals Policies
CREATE POLICY deals_delete_own ON public.deals
    FOR DELETE
    TO authenticated
    USING (
        (tenant_id = current_tenant_id()) AND 
        (can_write_current_tenant() = true)
    );

CREATE POLICY deals_insert_own ON public.deals
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (tenant_id = current_tenant_id()) AND 
        (can_write_current_tenant() = true)
    );

CREATE POLICY deals_select_own ON public.deals
    FOR SELECT
    TO authenticated
    USING (tenant_id = current_tenant_id());

CREATE POLICY deals_update_own ON public.deals
    FOR UPDATE
    TO authenticated
    USING (
        (tenant_id = current_tenant_id()) AND 
        (can_write_current_tenant() = true)
    )
    WITH CHECK (
        (tenant_id = current_tenant_id()) AND 
        (can_write_current_tenant() = true)
    );

-- Tenant Memberships Policies
CREATE POLICY memberships_insert_self ON public.tenant_memberships
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY memberships_select_own ON public.tenant_memberships
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Tenants Policies
CREATE POLICY tenant_owner_admin_update ON public.tenants
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM tenant_memberships tm
            WHERE ((tm.user_id = auth.uid()) AND (tm.tenant_id = tenants.id) AND (tm.role = ANY (ARRAY['owner'::text, 'admin'::text])))
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM tenant_memberships tm
            WHERE ((tm.user_id = auth.uid()) AND (tm.tenant_id = tenants.id) AND (tm.role = ANY (ARRAY['owner'::text, 'admin'::text])))
        )
    );

CREATE POLICY tenants_select_if_member ON public.tenants
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM tenant_memberships tm
            WHERE ((tm.tenant_id = tenants.id) AND (tm.user_id = auth.uid()))
        )
    );

-- ============================================================================
-- INDEXES (for performance)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_tenant_memberships_user_id ON public.tenant_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_memberships_tenant_id ON public.tenant_memberships(tenant_id);
CREATE INDEX IF NOT EXISTS idx_deals_tenant_id ON public.deals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_tenant_id ON public.audit_log(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at);
