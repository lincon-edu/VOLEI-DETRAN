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

-- ============================================================
-- ⚠️ BANCO QUE JÁ EXISTE (NÃO rode este arquivo inteiro, ele
--    apaga os dados!). Rode o arquivo "VOLEI-DETRAN-MIGRACAO.sql"
--    no SQL Editor. Ele NÃO apaga nada e adiciona o parâmetro
--    "Vencedor fica até perder" (coluna vencedor_fica_sem_dois_times),
--    garantindo também a tabela configuracoes_jogo, as políticas e
--    as permissões - que é o que faz o botão Salvar funcionar.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. LIMPEZA DAS ESTRUTURAS ANTIGAS
-- ============================================================

drop table if exists public.apostas cascade;
drop table if exists public.sessoes_apostadores cascade;
drop table if exists public.partidas_apostas cascade;
drop table if exists public.apostadores cascade;
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
-- 3.1 TABELA DE CONFIGURAÇÕES DO JOGO
-- ============================================================

create table public.configuracoes_jogo (
    id integer primary key
        check (id = 1),

    -- Jogadores por time.
    jogadores_por_time integer not null default 4
        check (jogadores_por_time between 2 and 10),

    -- Mínimo de mulheres por time.
    minimo_mulheres integer not null default 1
        check (minimo_mulheres >= 0),

    -- Se ligado: mulheres >= 50% dos confirmados -> mínimo de 2.
    regra_mulheres_50 boolean not null default true,

    -- Se ligado: quem vence 2 seguidas e sai volta na frente da fila.
    vencedor_duas_volta_fila boolean not null default false,

    -- Se ligado: sem 2 times completos na fila, o vencedor fica até perder.
    vencedor_fica_sem_dois_times boolean not null default false,

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

insert into public.configuracoes_jogo
    (id, jogadores_por_time, minimo_mulheres, regra_mulheres_50, vencedor_duas_volta_fila, vencedor_fica_sem_dois_times)
values
    (1, 4, 1, true, false, false);

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
alter table public.configuracoes_jogo enable row level security;

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

create policy "config_select_public"
on public.configuracoes_jogo
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

create policy "config_insert_authenticated"
on public.configuracoes_jogo
for insert
to authenticated
with check (true);

create policy "config_update_authenticated"
on public.configuracoes_jogo
for update
to authenticated
using (true)
with check (true);

create policy "config_delete_authenticated"
on public.configuracoes_jogo
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

grant select
on public.configuracoes_jogo
to anon, authenticated;

grant select, insert, update, delete
on public.configuracoes_jogo
to authenticated;

-- ============================================================
-- 10. REALTIME
-- ============================================================

alter table public.jogadores replica identity full;
alter table public.estado_jogo replica identity full;
alter table public.configuracoes_jogo replica identity full;

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

    if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'configuracoes_jogo'
    ) then
        alter publication supabase_realtime add table public.configuracoes_jogo;
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

    if total_confirmados > 40 then
        raise exception
            'O banco possui % jogadores confirmados. O limite é 40.',
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

-- ============================================================
-- VÔLEI DETRAN - APOSTAS FICTÍCIAS
-- Migração aditiva: não apaga jogadores, partidas ou histórico.
-- Execute no Supabase SQL Editor.
-- ============================================================

create extension if not exists pgcrypto;

-- Usuários de apostas: senha guardada somente como hash bcrypt.
create table if not exists public.apostadores (
    id uuid primary key default gen_random_uuid(),
    username text not null unique,
    password_hash text not null,
    saldo numeric(12,2) not null default 50.00 check (saldo >= 0),
    created_at timestamptz not null default now()
);

-- Sessões aleatórias; o token puro fica somente no navegador do usuário.
create table if not exists public.sessoes_apostadores (
    token_hash text primary key,
    apostador_id uuid not null references public.apostadores(id) on delete cascade,
    expires_at timestamptz not null,
    created_at timestamptz not null default now()
);

-- Cada registro representa uma partida e congela times/ODDs no início.
create table if not exists public.partidas_apostas (
    id bigint generated by default as identity primary key,
    started_at timestamptz not null default now(),
    closes_at timestamptz not null default (now() + interval '1 minute'),
    time_a_ids bigint[] not null default '{}',
    time_b_ids bigint[] not null default '{}',
    odd_a numeric(8,2) not null default 1.00 check (odd_a >= 1.00),
    odd_b numeric(8,2) not null default 1.00 check (odd_b >= 1.00),
    status text not null default 'aberta' check (status in ('aberta','encerrada','cancelada')),
    vencedor text null check (vencedor in ('A','B') or vencedor is null),
    settled_at timestamptz null
);

create table if not exists public.apostas (
    id bigint generated by default as identity primary key,
    apostador_id uuid not null references public.apostadores(id) on delete cascade,
    partida_id bigint not null references public.partidas_apostas(id) on delete restrict,
    lado text not null check (lado in ('A','B')),
    valor numeric(12,2) not null check (valor > 0),
    odd numeric(8,2) not null check (odd >= 1.00),
    status text not null default 'pendente' check (status in ('pendente','ganhou','perdeu','cancelada')),
    retorno numeric(12,2) not null default 0 check (retorno >= 0),
    created_at timestamptz not null default now(),
    constraint aposta_unica_por_lado unique (apostador_id, partida_id, lado)
);

alter table public.apostadores enable row level security;
alter table public.sessoes_apostadores enable row level security;
alter table public.partidas_apostas enable row level security;
alter table public.apostas enable row level security;

-- Os dados privados de usuário/apostas só são acessados pelas funções abaixo.
revoke all on public.apostadores from anon, authenticated;
revoke all on public.sessoes_apostadores from anon, authenticated;
revoke all on public.apostas from anon, authenticated;
grant select on public.partidas_apostas to anon, authenticated;
grant insert, update on public.partidas_apostas to authenticated;

drop policy if exists partidas_apostas_select_public on public.partidas_apostas;
create policy partidas_apostas_select_public on public.partidas_apostas
    for select to anon, authenticated using (true);
drop policy if exists partidas_apostas_insert_auth on public.partidas_apostas;
create policy partidas_apostas_insert_auth on public.partidas_apostas
    for insert to authenticated with check (true);
drop policy if exists partidas_apostas_update_auth on public.partidas_apostas;
create policy partidas_apostas_update_auth on public.partidas_apostas
    for update to authenticated using (true) with check (true);

-- Criação de usuário: login simples e senha com no mínimo 6 caracteres.
create or replace function public.registrar_apostador(p_username text, p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_username text := lower(trim(p_username));
    v_id uuid;
    v_token text;
    v_saldo numeric(12,2);
begin
    if v_username is null or v_username !~ '^[a-z0-9_.-]{3,24}$' then
        raise exception 'O login deve ter de 3 a 24 caracteres: letras, números, ponto, hífen ou sublinhado.';
    end if;
    if p_password is null or length(p_password) < 6 or length(p_password) > 128 then
        raise exception 'A senha deve ter entre 6 e 128 caracteres.';
    end if;
    insert into public.apostadores(username, password_hash, saldo)
    values (v_username, crypt(p_password, gen_salt('bf')), 50.00)
    returning id, saldo into v_id, v_saldo;
    v_token := encode(gen_random_bytes(32), 'hex');
    insert into public.sessoes_apostadores(token_hash, apostador_id, expires_at)
    values (encode(digest(v_token, 'sha256'), 'hex'), v_id, now() + interval '30 days');
    return jsonb_build_object('ok', true, 'token', v_token,
        'user', jsonb_build_object('id', v_id, 'username', v_username, 'saldo', v_saldo));
end;
$$;

create or replace function public.login_apostador(p_username text, p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_user public.apostadores%rowtype;
    v_token text;
begin
    select * into v_user from public.apostadores where username = lower(trim(p_username));
    if not found or p_password is null or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
        raise exception 'Login ou senha inválidos.';
    end if;
    v_token := encode(gen_random_bytes(32), 'hex');
    insert into public.sessoes_apostadores(token_hash, apostador_id, expires_at)
    values (encode(digest(v_token, 'sha256'), 'hex'), v_user.id, now() + interval '30 days');
    return jsonb_build_object('ok', true, 'token', v_token,
        'user', jsonb_build_object('id', v_user.id, 'username', v_user.username, 'saldo', v_user.saldo));
end;
$$;

create or replace function public.obter_apostador(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_user public.apostadores%rowtype;
begin
    select a.* into v_user
      from public.sessoes_apostadores s
      join public.apostadores a on a.id = s.apostador_id
     where s.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex')
       and s.expires_at > now();
    if not found then return jsonb_build_object('ok', false); end if;
    return jsonb_build_object('ok', true,
        'user', jsonb_build_object('id', v_user.id, 'username', v_user.username, 'saldo', v_user.saldo));
end;
$$;

-- O prazo de 60 segundos é verificado no banco, não apenas na interface.
create or replace function public.apostar_partida(p_token text, p_partida_id bigint, p_lado text, p_valor numeric)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_apostador_id uuid;
    v_saldo numeric(12,2);
    v_valor numeric(12,2) := round(p_valor, 2);
    v_odd numeric(8,2);
    v_partida public.partidas_apostas%rowtype;
begin
    if p_lado not in ('A','B') then raise exception 'Time inválido.'; end if;
    if v_valor is null or v_valor <= 0 then raise exception 'O valor da aposta deve ser maior que zero.'; end if;
    select apostador_id into v_apostador_id
      from public.sessoes_apostadores
     where token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex') and expires_at > now();
    if not found then raise exception 'Sessão expirada. Entre novamente.'; end if;
    select * into v_partida from public.partidas_apostas where id = p_partida_id for update;
    if not found or v_partida.status <> 'aberta' or now() > v_partida.closes_at then
        raise exception 'O prazo de apostas desta partida terminou.';
    end if;
    v_odd := case when p_lado = 'A' then v_partida.odd_a else v_partida.odd_b end;
    select saldo into v_saldo from public.apostadores where id = v_apostador_id for update;
    if v_valor > v_saldo then raise exception 'Saldo insuficiente para esta aposta.'; end if;
    insert into public.apostas(apostador_id, partida_id, lado, valor, odd)
    values (v_apostador_id, p_partida_id, p_lado, v_valor, v_odd);
    update public.apostadores set saldo = saldo - v_valor where id = v_apostador_id returning saldo into v_saldo;
    return jsonb_build_object('ok', true, 'saldo', v_saldo, 'odd', v_odd, 'valor', v_valor);
end;
$$;

-- Liquidação explícita via RPC. A rotina é transacional e idempotente.
-- O trigger antigo é removido para impedir liquidação duplicada.
drop trigger if exists trg_processar_resultado_apostas on public.partidas_apostas;
drop function if exists public.processar_resultado_apostas();

create or replace function public.encerrar_partida_apostas(
    p_partida_id bigint,
    p_vencedor text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_partida public.partidas_apostas%rowtype;
    v_apostas_liquidadas integer := 0;
begin
    if auth.uid() is null then
        raise exception 'Somente um administrador autenticado pode encerrar a partida.';
    end if;
    if p_vencedor not in ('A', 'B') then
        raise exception 'Time vencedor inválido.';
    end if;

    select * into v_partida
      from public.partidas_apostas
     where id = p_partida_id
     for update;

    if not found then
        raise exception 'Partida de apostas não encontrada.';
    end if;

    -- Se a mesma confirmação for repetida, não paga duas vezes.
    if v_partida.status = 'encerrada'
       and v_partida.vencedor = p_vencedor
       and v_partida.settled_at is not null then
        return jsonb_build_object('ok', true, 'ja_liquidada', true,
                                  'partida_id', p_partida_id);
    end if;

    if v_partida.status <> 'aberta' then
        raise exception 'A partida não está aberta para liquidação.';
    end if;

    -- Marca cada aposta pendente e congela o retorno calculado pela ODD registrada.
    update public.apostas
       set status = case when lado = p_vencedor then 'ganhou' else 'perdeu' end,
           retorno = case when lado = p_vencedor then round(valor * odd, 2) else 0 end
     where partida_id = p_partida_id
       and status = 'pendente';
    get diagnostics v_apostas_liquidadas = row_count;

    -- Credita o retorno total das apostas vencedoras. O valor apostado já foi
    -- debitado ao apostar, então retorno = valor x ODD (inclui a aposta original).
    update public.apostadores a
       set saldo = a.saldo + x.total
      from (
          select apostador_id, sum(retorno) as total
            from public.apostas
           where partida_id = p_partida_id
             and status = 'ganhou'
           group by apostador_id
      ) x
     where a.id = x.apostador_id;

    update public.partidas_apostas
       set status = 'encerrada',
           vencedor = p_vencedor,
           settled_at = now()
     where id = p_partida_id;

    return jsonb_build_object('ok', true, 'ja_liquidada', false,
                              'partida_id', p_partida_id,
                              'vencedor', p_vencedor,
                              'apostas_liquidadas', v_apostas_liquidadas);
end;
$$;

revoke all on function public.encerrar_partida_apostas(bigint, text) from public, anon;
grant execute on function public.encerrar_partida_apostas(bigint, text) to authenticated;

create or replace function public.historico_apostas_apostador(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_id uuid; v_result jsonb;
begin
    select apostador_id into v_id from public.sessoes_apostadores
     where token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex') and expires_at > now();
    if not found then raise exception 'Sessão expirada. Entre novamente.'; end if;
    select coalesce(jsonb_agg(jsonb_build_object(
        'id', b.id, 'partida_id', b.partida_id, 'lado', b.lado, 'valor', b.valor,
        'odd', b.odd, 'status', b.status, 'retorno', b.retorno, 'created_at', b.created_at
    ) order by b.created_at desc), '[]'::jsonb)
    into v_result from public.apostas b where b.apostador_id = v_id;
    return v_result;
end;
$$;

create or replace function public.ranking_apostadores()
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
    select coalesce(jsonb_agg(jsonb_build_object(
        'username', x.username, 'saldo', x.saldo, 'apostas', x.apostas,
        'vitorias', x.vitorias, 'derrotas', x.derrotas, 'lucro', round(x.saldo - 50.00, 2)
    ) order by x.saldo desc, x.username), '[]'::jsonb)
    from (
        select a.username, a.saldo,
               count(b.id)::integer as apostas,
               count(b.id) filter (where b.status = 'ganhou')::integer as vitorias,
               count(b.id) filter (where b.status = 'perdeu')::integer as derrotas
          from public.apostadores a left join public.apostas b on b.apostador_id = a.id
         group by a.id, a.username, a.saldo
    ) x;
$$;

revoke all on function public.registrar_apostador(text,text) from public;
revoke all on function public.login_apostador(text,text) from public;
revoke all on function public.obter_apostador(text) from public;
revoke all on function public.apostar_partida(text,bigint,text,numeric) from public;
revoke all on function public.historico_apostas_apostador(text) from public;
revoke all on function public.ranking_apostadores() from public;
grant execute on function public.registrar_apostador(text,text) to anon, authenticated;
grant execute on function public.login_apostador(text,text) to anon, authenticated;
grant execute on function public.obter_apostador(text) to anon, authenticated;
grant execute on function public.apostar_partida(text,bigint,text,numeric) to anon, authenticated;
grant execute on function public.historico_apostas_apostador(text) to anon, authenticated;
grant execute on function public.ranking_apostadores() to anon, authenticated;

-- Realtime apenas para estado público das partidas de aposta.
alter table public.partidas_apostas replica identity full;
do $$
begin
    if not exists (
        select 1 from pg_publication_tables
         where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'partidas_apostas'
    ) then alter publication supabase_realtime add table public.partidas_apostas; end if;
end $$;

-- ============================================================
-- FIM DA MIGRAÇÃO DE APOSTAS FICTÍCIAS
-- ============================================================
