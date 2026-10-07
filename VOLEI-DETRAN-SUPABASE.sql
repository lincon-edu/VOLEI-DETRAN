-- ============================================================
-- VÔLEI DETRAN
-- Banco de dados completo - instalação nova
-- Supabase / PostgreSQL
--
-- IMPORTANTE:
-- Execute este arquivo em um banco novo ou somente depois de
-- fazer backup. O bloco inicial remove as tabelas existentes.
--
-- AUTENTICAÇÃO:
-- Os administradores NÃO são criados neste SQL.
-- Crie-os em:
-- Supabase > Authentication > Users
--
-- LEITURA:
--   pública (anon + authenticated)
--
-- ESCRITA:
--   somente usuários autenticados pelo Supabase Auth
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. LIMPEZA DAS ESTRUTURAS ANTIGAS
-- ============================================================

drop table if exists public.jogo_jogadores cascade;
drop table if exists public.estado_jogo cascade;
drop table if exists public.jogadores cascade;

-- ============================================================
-- 2. TABELA DE JOGADORES
-- ============================================================

create table public.jogadores (
    id bigint primary key,
    nome text not null,
    sexo char(1) not null
        check (sexo in ('M', 'F')),

    -- Status atual do jogador:
    -- confirmado = pode participar
    -- ausente    = não está presente
    -- pendente   = ainda não confirmou
    status text not null default 'confirmado'
        check (status in ('confirmado', 'ausente', 'pendente')),

    -- Mantida por compatibilidade com versões anteriores da aplicação.
    -- Deve sempre corresponder ao status.
    confirmado boolean not null default true,

    partidas integer not null default 0
        check (partidas >= 0),

    vitorias integer not null default 0
        check (vitorias >= 0 and vitorias <= partidas),

    espera integer not null default 0
        check (espera >= 0),

    -- Ordem original/cadastral usada como desempate.
    -- A ordem manual atual da fila é persistida em estado_jogo.fila.
    queue_order integer not null unique,

    created_at timestamptz not null default now(),

    -- Garante que confirmado e status não fiquem divergentes.
    constraint jogadores_status_confirmado_check
        check (confirmado = (status = 'confirmado'))
);

-- ============================================================
-- 3. ESTADO ÚNICO DO JOGO
-- ============================================================

create table public.estado_jogo (
    id integer primary key
        check (id = 1),

    iniciado boolean not null default false,

    -- Vitórias consecutivas atualmente contabilizadas.
    vitorias_time_a integer not null default 0
        check (vitorias_time_a >= 0),

    vitorias_time_b integer not null default 0
        check (vitorias_time_b >= 0),

    -- IDs dos jogadores atualmente no Time A.
    time_a bigint[] not null default '{}',

    -- IDs dos jogadores atualmente no Time B.
    time_b bigint[] not null default '{}',

    -- IDs dos jogadores na fila, NA ORDEM MANUAL ATUAL.
    fila bigint[] not null default '{}',

    updated_at timestamptz not null default now()
);

-- ============================================================
-- 4. DADOS INICIAIS
-- ============================================================

insert into public.jogadores
    (id, nome, sexo, status, confirmado, partidas, vitorias, espera, queue_order)
values
    (1,  'Victor',   'M', 'confirmado', true, 0, 0, 0, 1),
    (2,  'Joao V',   'M', 'confirmado', true, 0, 0, 0, 2),
    (3,  'Glauber',  'M', 'confirmado', true, 0, 0, 0, 3),
    (4,  'Lucas',    'M', 'confirmado', true, 0, 0, 0, 4),
    (5,  'Mateus',   'M', 'confirmado', true, 0, 0, 0, 5),
    (6,  'Gabriel',  'M', 'confirmado', true, 0, 0, 0, 6),
    (7,  'Rafael',   'M', 'confirmado', true, 0, 0, 0, 7),
    (8,  'João',     'M', 'confirmado', true, 0, 0, 0, 8),
    (9,  'Pedro',    'M', 'confirmado', true, 0, 0, 0, 9),
    (10, 'Tiago',    'M', 'confirmado', true, 0, 0, 0, 10),
    (11, 'Marcos',   'M', 'confirmado', true, 0, 0, 0, 11),
    (12, 'André',    'M', 'confirmado', true, 0, 0, 0, 12),
    (13, 'Felipe',   'M', 'confirmado', true, 0, 0, 0, 13),
    (14, 'Carlos',   'M', 'confirmado', true, 0, 0, 0, 14),
    (15, 'Eduardo',  'M', 'confirmado', true, 0, 0, 0, 15),
    (16, 'Marcelo',  'M', 'confirmado', true, 0, 0, 0, 16),
    (17, 'Gustavo',  'M', 'confirmado', true, 0, 0, 0, 17),
    (18, 'Fernando', 'M', 'confirmado', true, 0, 0, 0, 18),
    (19, 'Bruno',    'M', 'confirmado', true, 0, 0, 0, 19),
    (20, 'Diego',    'M', 'confirmado', true, 0, 0, 0, 20),
    (21, 'Leonardo', 'M', 'confirmado', true, 0, 0, 0, 21),
    (22, 'Thiago',   'M', 'confirmado', true, 0, 0, 0, 22),
    (23, 'Rodrigo',  'M', 'confirmado', true, 0, 0, 0, 23),
    (24, 'Ana',      'F', 'confirmado', true, 0, 0, 0, 24),
    (25, 'Julia',    'F', 'confirmado', true, 0, 0, 0, 25),
    (26, 'Beatriz',  'F', 'confirmado', true, 0, 0, 0, 26),
    (27, 'Mariana',  'F', 'confirmado', true, 0, 0, 0, 27),
    (28, 'Camila',   'F', 'confirmado', true, 0, 0, 0, 28),
    (29, 'Letícia',  'F', 'confirmado', true, 0, 0, 0, 29),
    (30, 'Amanda',   'F', 'confirmado', true, 0, 0, 0, 30);

insert into public.estado_jogo
    (id, iniciado, vitorias_time_a, vitorias_time_b, time_a, time_b, fila)
values
    (1, false, 0, 0, '{}', '{}', '{}');

-- ============================================================
-- 5. FUNÇÃO PARA MANTER status E confirmado SINCRONIZADOS
-- ============================================================

create or replace function public.sincronizar_status_jogador()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'INSERT' then
        new.confirmado := (new.status = 'confirmado');
        return new;
    end if;

    -- Se a aplicação alterou status, status é a fonte da verdade.
    if new.status is distinct from old.status then
        new.confirmado := (new.status = 'confirmado');
        return new;
    end if;

    -- Compatibilidade caso uma versão antiga altere confirmado.
    if new.confirmado is distinct from old.confirmado then
        new.status := case
            when new.confirmado then 'confirmado'
            else 'ausente'
        end;
        return new;
    end if;

    return new;
end;
$$;

create trigger trg_sincronizar_status_jogador
before insert or update on public.jogadores
for each row
execute function public.sincronizar_status_jogador();

-- ============================================================
-- 6. RLS
-- ============================================================

alter table public.jogadores enable row level security;
alter table public.estado_jogo enable row level security;

-- ============================================================
-- 7. POLICIES DE LEITURA PÚBLICA
-- ============================================================

create policy "jogadores_select_public"
on public.jogadores
for select
to anon, authenticated
using (true);

create policy "estado_select_public"
on public.estado_jogo
for select
to anon, authenticated
using (true);

-- ============================================================
-- 8. POLICIES DE ESCRITA
-- SOMENTE SUPABASE AUTHENTICATED
-- ============================================================

create policy "jogadores_insert_authenticated"
on public.jogadores
for insert
to authenticated
with check (true);

create policy "jogadores_update_authenticated"
on public.jogadores
for update
to authenticated
using (true)
with check (true);

create policy "jogadores_delete_authenticated"
on public.jogadores
for delete
to authenticated
using (true);

create policy "estado_insert_authenticated"
on public.estado_jogo
for insert
to authenticated
with check (true);

create policy "estado_update_authenticated"
on public.estado_jogo
for update
to authenticated
using (true)
with check (true);

create policy "estado_delete_authenticated"
on public.estado_jogo
for delete
to authenticated
using (true);

-- ============================================================
-- 9. GRANTS
-- ============================================================

grant usage on schema public to anon, authenticated;

grant select
on public.jogadores
to anon, authenticated;

grant select, insert, update, delete
on public.jogadores
to authenticated;

grant select
on public.estado_jogo
to anon, authenticated;

grant select, insert, update, delete
on public.estado_jogo
to authenticated;

-- ============================================================
-- 10. REALTIME
-- ============================================================

alter table public.jogadores replica identity full;
alter table public.estado_jogo replica identity full;

-- Adiciona as tabelas ao Realtime somente se ainda não estiverem
-- na publicação supabase_realtime.
do $$
begin
    if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'jogadores'
    ) then
        alter publication supabase_realtime add table public.jogadores;
    end if;

    if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'estado_jogo'
    ) then
        alter publication supabase_realtime add table public.estado_jogo;
    end if;
end
$$;

-- ============================================================
-- 11. VALIDAÇÕES INICIAIS
-- ============================================================

do $$
declare
    total_confirmados integer;
begin
    select count(*)
      into total_confirmados
      from public.jogadores
     where status = 'confirmado';

    if total_confirmados > 30 then
        raise exception
            'O banco possui % jogadores confirmados. O limite é 30.',
            total_confirmados;
    end if;
end
$$;

-- ============================================================
-- FIM
--
-- NÃO crie usuários administrativos aqui.
--
-- Crie os administradores em:
-- Supabase > Authentication > Users
--
-- O frontend deve utilizar apenas a chave pública/publishable
-- do Supabase. NUNCA coloque a service_role key no HTML.
-- ============================================================
