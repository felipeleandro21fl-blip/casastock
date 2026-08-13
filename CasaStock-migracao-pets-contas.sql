-- MIGRAÇÃO NÃO DESTRUTIVA DO CASASTOCK
-- Execute DEPOIS do supabase.sql original.
-- Não apaga usuários, casas, estoque ou lista de compras.

-- 1) Adiciona a categoria Pets ao estoque.
alter table public.supplies drop constraint if exists supplies_category_check;
alter table public.supplies add constraint supplies_category_check
check (category in ('Alimentos','Higiene pessoal','Limpeza','Pets','Outros'));

-- 2) Cria contas a pagar.
create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  due_date date not null,
  paid boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_bills_house on public.bills(household_id);
create index if not exists idx_bills_due on public.bills(household_id,due_date);

alter table public.bills enable row level security;

drop policy if exists "members can read bills" on public.bills;
create policy "members can read bills" on public.bills for select to authenticated
using (public.is_house_member(household_id));

drop policy if exists "members can insert bills" on public.bills;
create policy "members can insert bills" on public.bills for insert to authenticated
with check (public.is_house_member(household_id));

drop policy if exists "members can update bills" on public.bills;
create policy "members can update bills" on public.bills for update to authenticated
using (public.is_house_member(household_id))
with check (public.is_house_member(household_id));

drop policy if exists "members can delete bills" on public.bills;
create policy "members can delete bills" on public.bills for delete to authenticated
using (public.is_house_member(household_id));

grant select,insert,update,delete on public.bills to authenticated;

-- Sincronização em tempo real das contas.
alter publication supabase_realtime add table public.bills;
