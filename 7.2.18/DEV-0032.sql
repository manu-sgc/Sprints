---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.tbn_classificacao

select sotech.sys_create_field('sotech',  'tbn_classificacao',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'tbn_classificacao',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'tbn_classificacao',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'tbn_classificacao',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'tbn_classificacao',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'tbn_classificacao',  'fkuser',   'sotech_tbn_classificacao_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'tbn_classificacao',  'ativo',    'sotech_tbn_classificacao_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'tbn_classificacao',  'uuid',     'sotech_tbn_classificacao_unq_uuid');

comment on column sotech.tbn_classificacao.pkclassificacao  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_classificacao.fkservico        is '(fk | idx | nn) - Referência com a tabela sotech.tbn_servico';
comment on column sotech.tbn_classificacao.codclassificacao is '(idx | nn)      - Código da classificação';
comment on column sotech.tbn_classificacao.classificacao    is '(idx | nn)      - Nome da classificação';
comment on column sotech.tbn_classificacao.competenciaini   is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_classificacao.competenciafim   is '(idx | nn)      - Competência final';
comment on column sotech.tbn_classificacao.ativo            is '(idx | nn)      - Flag para desabilitar visualização do registro';
comment on column sotech.tbn_classificacao.uuid             is '(unq | nn)      - UUID do registro';
comment on column sotech.tbn_classificacao.fkuser           is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.tbn_classificacao.version          is '(nn)            - Versionamento do registro';

create or replace function sotech.tbn_classificacao_tratamento() returns trigger as
$$
declare 
  v_erro      text;
  v_registros record;
begin
  v_erro := '';
  -- fkuser
  if new.fkuser is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Usuário não informado!');
  else
    if (select count(*) from ish.sys_usuario where ish.sys_usuario.pkusuario = new.fkuser) = 0 then
      v_erro := sotech.sys_set_erro(v_erro, 'Usuário sem referência!(' || new.fkuser::text || ')');
    end if;
  end if;
  -- version
  if new.version is null then
    new.version := 0;
  else
    if new.version != (select sotech.tbn_classificacao.version from sotech.tbn_classificacao where sotech.tbn_classificacao.pkclassificacao = new.pkclassificacao) then
      v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «Versão»');
    end if;
  end if;
  -- ativo
  if new.ativo is null then
    new.ativo := true;
  end if;
  -- uuid
  if new.uuid is null then
    new.uuid := uuid_generate_v4();
  end if;
  if new.uuid is not null then
    select into v_registros coalesce((select sotech.tbn_classificacao.pkclassificacao from sotech.tbn_classificacao where sotech.tbn_classificacao.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_classificacao.pkclassificacao <> new.pkclassificacao else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo);
    end if;
  end if;
  -- tratamento de competência:
  if new.competenciaini::integer > new.competenciafim::integer then
    v_erro := sotech.sys_set_erro(v_erro, concat('Competência inicial: ', new.competenciaini, ' superior à competência final: ', new.competenciafim));
  end if;
  -- unique
  if new.fkservico is not null and new.codclassificacao is not null and new.competenciaini is not null and new.competenciafim is not null then
    select into v_registros coalesce((select sotech.tbn_classificacao.pkclassificacao from sotech.tbn_classificacao where sotech.tbn_classificacao.fkservico = new.fkservico and sotech.tbn_classificacao.codclassificacao = new.codclassificacao and (new.competenciaini between sotech.tbn_classificacao.competenciaini and sotech.tbn_classificacao.competenciafim or new.competenciafim between sotech.tbn_classificacao.competenciaini and sotech.tbn_classificacao.competenciafim) and case when tg_op = 'UPDATE' then sotech.tbn_classificacao.pkclassificacao <> new.pkclassificacao else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado!  Serviço: ' || new.fkservico::text || ' Código classificação: ' || new.codclassificacao::text || ' Competência inicial: ' || new.competenciaini::text || ' Competência fim: ' || new.competenciafim::text || ' -> Cód:' || v_registros.codigo);
    end if;
  end if;
  -- final
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_classificacao » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkclassificacao::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_classificacao_auditoria() returns trigger as
$$
declare 
  v_retorno  text;
  v_tabela   text;
  v_usuario  integer;
  v_chave    bigint;
begin
  v_tabela  := 'sotech_tbn_classificacao';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkclassificacao else new.pkclassificacao end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end,  case when tg_op = 'DELETE' then '' else new.version::text                                               end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end,  case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end,  case when tg_op = 'DELETE' then '' else new.uuid::text                                                  end);
  -- fkservico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkservico',                    case when tg_op = 'INSERT' then '' else old.fkservico::text                                            end,  case when tg_op = 'DELETE' then '' else new.fkservico::text                                             end);
  -- codclassificacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codclassificacao',             case when tg_op = 'INSERT' then '' else old.codclassificacao                                           end,  case when tg_op = 'DELETE' then '' else new.codclassificacao                                            end);
  -- classificacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'classificacao',                case when tg_op = 'INSERT' then '' else old.classificacao                                              end,  case when tg_op = 'DELETE' then '' else new.classificacao                                               end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end,  case when tg_op = 'DELETE' then '' else new.competenciaini                                              end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end,  case when tg_op = 'DELETE' then '' else new.competenciafim                                              end);
  v_retorno   := null;
  v_usuario := null;
  v_chave := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');