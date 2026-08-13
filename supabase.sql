-- CasaStock Compartilhado
-- Execute este script no Supabase SQL Editor.
-- Ele cria casas, membros, estoque, lista de compras e as políticas de segurança.

create extension if not exists pgcrypto;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique default upper(substr(encode(gen_random_bytes(6),'hex'),1,8)),
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (household_id,user_id)
);

create table if not exists public.supplies (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  category text not null check (category in ('Alimentos','Higiene pessoal','Limpeza','Outros')),
  unit text not null default 'un.',
  quantity numeric not null default 0 check (quantity >= 0),
  minimum numeric not null default 0 check (minimum >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  quantity text,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists idx_members_user on public.household_members(user_id);
create index if not exists idx_supplies_house on public.supplies(household_id);
create index if not exists idx_shopping_house on public.shopping_items(household_id);

-- Helper: verifica se o usuário atual pertence à casa.
create or replace function public.is_house_member(p_household uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household and user_id = auth.uid()
  );
$$;

-- Criação segura de casa + inclusão automática do criador.
create or replace function public.create_household(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Você precisa estar logado.'; end if;
  insert into public.households(name, owner_id) values (trim(p_name), auth.uid()) returning id into new_id;
  insert into public.household_members(household_id,user_id) values (new_id,auth.uid());
  return new_id;
end;
$$;

-- Entrada por código. O código não precisa ficar público em consultas.
create or replace function public.join_household(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare h_id uuid;
begin
  if auth.uid() is null then raise exception 'Você precisa estar logado.'; end if;
  select id into h_id from public.households where invite_code = upper(trim(p_code));
  if h_id is null then raise exception 'Código de convite inválido.'; end if;
  insert into public.household_members(household_id,user_id)
    values(h_id,auth.uid()) on conflict do nothing;
  return h_id;
end;
$$;

grant execute on function public.create_household(text) to authenticated;
grant execute on function public.join_household(text) to authenticated;
grant execute on function public.is_house_member(uuid) to authenticated;

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.supplies enable row level security;
alter table public.shopping_items enable row level security;

drop policy if exists "members can read their households" on public.households;
create policy "members can read their households" on public.households for select to authenticated
using (public.is_house_member(id));

drop policy if exists "users can read own memberships" on public.household_members;
create policy "users can read own memberships" on public.household_members for select to authenticated
using (user_id = auth.uid());

drop policy if exists "members can read supplies" on public.supplies;
create policy "members can read supplies" on public.supplies for select to authenticated
using (public.is_house_member(household_id));

drop policy if exists "members can insert supplies" on public.supplies;
create policy "members can insert supplies" on public.supplies for insert to authenticated
with check (public.is_house_member(household_id));

drop policy if exists "members can update supplies" on public.supplies;
create policy "members can update supplies" on public.supplies for update to authenticated
using (public.is_house_member(household_id))
with check (public.is_house_member(household_id));

drop policy if exists "members can delete supplies" on public.supplies;
create policy "members can delete supplies" on public.supplies for delete to authenticated
using (public.is_house_member(household_id));

drop policy if exists "members can read shopping" on public.shopping_items;
create policy "members can read shopping" on public.shopping_items for select to authenticated
using (public.is_house_member(household_id));

drop policy if exists "members can insert shopping" on public.shopping_items;
create policy "members can insert shopping" on public.shopping_items for insert to authenticated
with check (public.is_house_member(household_id));

drop policy if exists "members can update shopping" on public.shopping_items;
create policy "members can update shopping" on public.shopping_items for update to authenticated
using (public.is_house_member(household_id))
with check (public.is_house_member(household_id));

drop policy if exists "members can delete shopping" on public.shopping_items;
create policy "members can delete shopping" on public.shopping_items for delete to authenticated
using (public.is_house_member(household_id));

-- Permissões para o papel autenticado.
grant select on public.households, public.household_members, public.supplies, public.shopping_items to authenticated;
grant insert, update, delete on public.supplies, public.shopping_items to authenticated;

-- Realtime para sincronizar alterações entre celulares.
alter publication supabase_realtime add table public.supplies;
alter publication supabase_realtime add table public.shopping_items;
