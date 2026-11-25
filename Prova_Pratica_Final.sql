create table jogadores (
    id serial primary key,
    nickname varchar(50) not null unique,
    email varchar(100) not null unique,
    senha varchar(100) not null,
    status varchar(20) not null default 'ativo',
    check (status in ('ativo', 'inativo', 'banido'))
);

create table modalidades (
    id serial primary key,
    nome varchar(60) not null unique,
    categoria varchar(40) not null,
    descricao text
);

create table partidas (
    id serial primary key,
    titulo varchar(100) not null,
    evento varchar(100) not null,
    jogador_id integer not null references jogadores(id),
    modalidade_id integer not null references modalidades(id),
    data_agendamento timestamp not null,
    data_criacao timestamp,
    status varchar(20) not null default 'agendada',
    check (status in ('agendada', 'em andamento', 'concluida', 'cancelada'))
);

create table historico_partidas (
    id serial primary key,
    partida_id integer not null references partidas(id),
    jogador_id integer not null references jogadores(id),
    acao varchar(100) not null,
    data_registro timestamp default current_timestamp
);

insert into jogadores (nickname, email, senha, status) values
('MegelGM', 'megel@email.com', 'heauneao', 'ativo'),
('Nahhtan', 'nathan@email.com', 'hrsfbrs', 'ativo'),
('Jonga', 'jonga@email.com', 'hynet', 'ativo'),
('Xduckk', 'xduckk@email.com', 'tjuyb', 'banido');

insert into modalidades (nome, categoria, descricao) values
('valorant', 'fps', 'disputa tática entre equipes'),
('rocket league', 'esporte', 'partidas de futebol com carros'),
('minecraft', 'sobrevivencia', 'competição de construção e sobrevivência');

create or replace function fn_validar_partida()
returns trigger as $$
begin
    if not exists (
        select 1
        from jogadores
        where id = new.jogador_id
        and status = 'ativo'
    ) then
        raise exception 'jogador nao esta ativo';
    end if;

    new.data_criacao = current_timestamp;

    return new;
end;
$$ language plpgsql;

create trigger trg_validar_partida
before insert on partidas
for each row
execute function fn_validar_partida();

create or replace function fn_registrar_historico()
returns trigger as $$
begin
    insert into historico_partidas
    (partida_id, jogador_id, acao)
    values
    (new.id, new.jogador_id, 'partida cadastrada');

    return new;
end;
$$ language plpgsql;

create trigger trg_historico_partidas
after insert on partidas
for each row
execute function fn_registrar_historico();

insert into partidas
(titulo, evento, jogador_id, modalidade_id, data_agendamento, status)
values
('MegelGM vs Jonga', 'copa Senai', 1, 1, current_timestamp + interval '2 days', 'agendada'),
('disputa das Auras', 'arena games', 2, 2, current_timestamp + interval '4 days', 'agendada'),
('Ataque do Santinho', 'Aura Master', 3, 3, current_timestamp + interval '7 days', 'agendada');

create or replace function fn_buscar_jogadores(termo text)
returns table (
    id integer,
    nickname varchar(50),
    email varchar(100),
    status varchar(20)
) as $$
begin
    return query
    select
        j.id,
        j.nickname,
        j.email,
        j.status
    from jogadores j
    where j.nickname ilike '%' || termo || '%'
    or j.email ilike '%' || termo || '%';
end;
$$ language plpgsql;

create or replace view vw_painel_principal as
select
    j.nickname,
    p.titulo as confronto,
    m.categoria,
    p.data_agendamento as data_partida,
    p.status
from partidas p
inner join jogadores j on p.jogador_id = j.id
inner join modalidades m on p.modalidade_id = m.id;

create or replace view vw_cronograma_partidas as
select
    p.id,
    p.titulo,
    p.evento,
    j.nickname,
    p.data_agendamento,
    p.status,
    (p.data_agendamento::date - current_date) as dias_restantes
from partidas p
inner join jogadores j on p.jogador_id = j.id
order by p.data_agendamento asc;

select * from jogadores;
select * from modalidades;
select * from partidas;
select * from historico_partidas;

select * from vw_painel_principal;
select * from vw_cronograma_partidas;

select * from fn_buscar_jogadores('MegelGM');
