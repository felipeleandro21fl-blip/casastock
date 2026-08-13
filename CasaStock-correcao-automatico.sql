-- CASASTOCK: CORREÇÃO DEFINITIVA
-- A própria base de dados coloca o item na lista quando quantity <= minimum.
-- Execute este SQL uma única vez no Supabase.
-- NÃO apaga nenhum cadastro existente.

alter table public.shopping_items
  add column if not exists supply_id uuid references public.supplies(id) on delete cascade;

create index if not exists idx_shopping_supply on public.shopping_items(supply_id);

create unique index if not exists uq_shopping_house_supply
  on public.shopping_items(household_id, supply_id)
  where supply_id is not null;

create or replace function public.auto_add_low_stock_to_shopping()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.quantity <= new.minimum then
    insert into public.shopping_items
      (household_id, supply_id, name, quantity, note)
    values
      (
        new.household_id,
        new.id,
        new.name,
        'Comprar ' || greatest(0, new.minimum - new.quantity) || ' ' || new.unit,
        'Gerado automaticamente por estoque baixo'
      )
    on conflict (household_id, supply_id)
    where supply_id is not null
    do update set
      name = excluded.name,
      quantity = excluded.quantity,
      note = excluded.note;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_auto_add_low_stock on public.supplies;

create trigger trg_auto_add_low_stock
after insert or update of quantity, minimum, name, unit
on public.supplies
for each row
execute function public.auto_add_low_stock_to_shopping();

-- Corrige também os itens que JÁ estão abaixo do mínimo.
insert into public.shopping_items
  (household_id, supply_id, name, quantity, note)
select
  s.household_id,
  s.id,
  s.name,
  'Comprar ' || greatest(0, s.minimum - s.quantity) || ' ' || s.unit,
  'Gerado automaticamente por estoque baixo'
from public.supplies s
where s.quantity <= s.minimum
on conflict (household_id, supply_id)
where supply_id is not null
do update set
  name = excluded.name,
  quantity = excluded.quantity,
  note = excluded.note;
