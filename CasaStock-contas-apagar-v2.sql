-- Migração não destrutiva: melhora Contas a pagar.
alter table public.bills add column if not exists category text not null default 'Outros';
alter table public.bills add column if not exists recurrence text not null default 'none';
alter table public.bills add column if not exists note text;

alter table public.bills drop constraint if exists bills_category_check;
alter table public.bills add constraint bills_category_check
check (category in ('Moradia','Energia','Água','Internet','Telefone','Alimentação','Transporte','Pets','Cartão','Assinaturas','Outros'));

alter table public.bills drop constraint if exists bills_recurrence_check;
alter table public.bills add constraint bills_recurrence_check
check (recurrence in ('none','monthly'));
