-- ============================================================
-- VÔLEI DETRAN - MIGRAÇÃO (banco que JÁ existe)
-- ============================================================
-- NÃO apaga dados. Pode rodar quantas vezes quiser (idempotente).
--
-- Conserta a tabela de configurações e adiciona o parâmetro
-- "Vencedor fica até perder" (coluna vencedor_fica_sem_dois_times).
--
-- COMO USAR:
--   Supabase > seu projeto > SQL Editor > New query
--   Cole TUDO isto e clique em RUN.
-- ============================================================

-- 1) Garante que a tabela de configurações existe (com todas as colunas).
create table if not exists public.configuracoes_jogo (
    id integer primary key check (id = 1),
    jogadores_por_time integer not null default 4,
    minimo_mulheres integer not null default 1,
    regra_mulheres_50 boolean not null default true,
    vencedor_duas_volta_fila boolean not null default false,
    vencedor_fica_sem_dois_times boolean not null default false,
    updated_at timestamptz not null default now()
);

-- 2) Adiciona as colunas que possam faltar em bancos antigos.
alter table public.configuracoes_jogo
    add column if not exists jogadores_por_time integer not null default 4;
alter table public.configuracoes_jogo
    add column if not exists minimo_mulheres integer not null default 1;
alter table public.configuracoes_jogo
    add column if not exists regra_mulheres_50 boolean not null default true;
alter table public.configuracoes_jogo
    add column if not exists vencedor_duas_volta_fila boolean not null default false;
alter table public.configuracoes_jogo
    add column if not exists vencedor_fica_sem_dois_times boolean not null default false;
alter table public.configuracoes_jogo
    add column if not exists updated_at timestamptz not null default now();

-- 3) Garante a linha única de configuração (id = 1).
insert into public.configuracoes_jogo (id)
values (1)
on conflict (id) do nothing;

-- 4) Segurança (RLS) + políticas de escrita para administradores.
alter table public.configuracoes_jogo enable row level security;

drop policy if exists config_select_public on public.configuracoes_jogo;
create policy config_select_public on public.configuracoes_jogo
    for select to anon, authenticated using (true);

drop policy if exists config_insert_authenticated on public.configuracoes_jogo;
create policy config_insert_authenticated on public.configuracoes_jogo
    for insert to authenticated with check (true);

drop policy if exists config_update_authenticated on public.configuracoes_jogo;
create policy config_update_authenticated on public.configuracoes_jogo
    for update to authenticated using (true) with check (true);

drop policy if exists config_delete_authenticated on public.configuracoes_jogo;
create policy config_delete_authenticated on public.configuracoes_jogo
    for delete to authenticated using (true);

-- 5) Permissões.
grant usage on schema public to anon, authenticated;
grant select on public.configuracoes_jogo to anon, authenticated;
grant select, insert, update, delete on public.configuracoes_jogo to authenticated;

-- 6) Realtime (para sincronizar o site em vários dispositivos).
alter table public.configuracoes_jogo replica identity full;

do $$
begin
    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'configuracoes_jogo'
    ) then
        alter publication supabase_realtime add table public.configuracoes_jogo;
    end if;
end $$;

-- ============================================================
-- FIM. Após rodar, recarregue o site (Ctrl+F5) e salve as
-- configurações novamente.
-- ============================================================
