-- Muslim Essentials schema for Supabase (Postgres)
-- Run this entire file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins a
    where a.user_id = (select auth.uid())
  );
$$;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  category text not null default 'Other approved categories',
  subcategory text,
  image_url text,
  official_url text,
  affiliate_url text,
  price text,
  currency text,
  price_verified boolean not null default false,
  price_verification_date date,
  pros text,
  cons text,
  features text,
  screening_status text not null default 'manual_review'
    check (screening_status in ('manual_review','approved','rejected')),
  featured boolean not null default false,
  published boolean not null default false,
  keywords text,
  seo_title text,
  seo_description text,
  icon text,
  review_date date,
  verification_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint products_price_verification_check
    check (price_verified = false or (price is not null and currency is not null and price_verification_date is not null))
);

create table if not exists public.affiliate_programs (
  id uuid primary key default gen_random_uuid(),
  program_name text not null,
  affiliate_network text,
  program_url text,
  application_url text,
  tracking_url text,
  supported_countries text,
  commission_type text,
  commission_rate text,
  commission_verified boolean not null default false,
  payment_methods text,
  minimum_payout text,
  approval_status text not null default 'Researching'
    check (approval_status in ('Researching','Applied','Approved','Rejected')),
  notes text,
  verification_date date,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint programs_commission_verification_check
    check (commission_verified = false or (commission_type is not null and commission_rate is not null))
);

create table if not exists public.outbound_clicks (
  id bigint generated always as identity primary key,
  product_id uuid references public.products(id) on delete set null,
  clicked_at timestamptz not null default now()
);

create index if not exists products_public_category_idx
  on public.products (category, featured desc, name) where published = true;
create index if not exists programs_public_idx
  on public.affiliate_programs (program_name) where published = true;
create index if not exists clicks_product_date_idx
  on public.outbound_clicks (product_id, clicked_at desc);

-- Keep updated_at current on database changes.
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products
for each row execute function public.set_updated_at();
drop trigger if exists programs_set_updated_at on public.affiliate_programs;
create trigger programs_set_updated_at before update on public.affiliate_programs
for each row execute function public.set_updated_at();

alter table public.admins enable row level security;
alter table public.products enable row level security;
alter table public.affiliate_programs enable row level security;
alter table public.outbound_clicks enable row level security;

-- Public visitors may read only published products and programs.
drop policy if exists "Public can read published products" on public.products;
create policy "Public can read published products" on public.products
for select to anon, authenticated using (published = true or public.is_admin());

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products" on public.products
for insert to authenticated with check (public.is_admin());
drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products" on public.products
for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products" on public.products
for delete to authenticated using (public.is_admin());

drop policy if exists "Public can read published programs" on public.affiliate_programs;
create policy "Public can read published programs" on public.affiliate_programs
for select to anon, authenticated using (published = true or public.is_admin());
drop policy if exists "Admins can insert programs" on public.affiliate_programs;
create policy "Admins can insert programs" on public.affiliate_programs
for insert to authenticated with check (public.is_admin());
drop policy if exists "Admins can update programs" on public.affiliate_programs;
create policy "Admins can update programs" on public.affiliate_programs
for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Admins can delete programs" on public.affiliate_programs;
create policy "Admins can delete programs" on public.affiliate_programs
for delete to authenticated using (public.is_admin());

-- Only admins can read the admin roster. Users cannot grant themselves admin access.
drop policy if exists "Admins can read admins" on public.admins;
create policy "Admins can read admins" on public.admins
for select to authenticated using (public.is_admin());

-- Do not expose raw click rows to the public. Count a click via a narrow RPC function.
create or replace function public.record_outbound_click(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.products p where p.id = p_product_id and p.published = true and p.affiliate_url is not null) then
    insert into public.outbound_clicks(product_id) values (p_product_id);
  end if;
end;
$$;
revoke all on function public.record_outbound_click(uuid) from public;
grant execute on function public.record_outbound_click(uuid) to anon, authenticated;

-- Grant table access; RLS policies remain the authorization boundary.
grant usage on schema public to anon, authenticated;
grant select on public.products, public.affiliate_programs to anon, authenticated;
grant insert, update, delete on public.products, public.affiliate_programs to authenticated;
grant select on public.admins to authenticated;
grant usage, select on sequence public.outbound_clicks_id_seq to anon, authenticated;
