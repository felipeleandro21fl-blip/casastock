-- CASAStock: sincronização automática de estoque baixo -> lista de compras
-- MIGRAÇÃO NÃO DESTRUTIVA. Execute depois das migrações anteriores.
-- Não apaga usuários, casas, estoque ou compras existentes.

alter table public.shopping_items
  add column if not exists supply_id uuid references public.supplies(id) on delete cascade;

create index if not exists idx_shopping_supply on public.shopping_items(supply_id);

-- Evita que o mesmo insumo seja inserido automaticamente várias vezes.
create unique index if not exists uq_shopping_house_supply
  on public.shopping_items(household_id, supply_id)
  where supply_id is not null;

-- Atualiza o Realtime da lista de compras. Se já estiver publicado, o comando
-- pode retornar aviso; isso não é problema.
do $$
begin
  begin
    alter publication supabase_realtime add table public.shopping_items;
  exception when duplicate_object then
    null;
  end;
end $$;
