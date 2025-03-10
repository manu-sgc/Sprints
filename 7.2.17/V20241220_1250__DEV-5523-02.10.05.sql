---------------------------
-- task_id:    DEV-5523
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela ate_apac_solicitacao_procedimento

select sotech.sys_create_field('sotech',  'ate_apac_solicitacao_procedimento',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Refer�ncia com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'ate_apac_solicitacao_procedimento',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'ate_apac_solicitacao_procedimento',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualiza��o do registro');
select sotech.sys_create_field('sotech',  'ate_apac_solicitacao_procedimento',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'ate_apac_solicitacao_procedimento',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'ate_apac_solicitacao_procedimento',  'fkuser',   'sotech_ate_apac_solicitacao_procedimento_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'ate_apac_solicitacao_procedimento',  'ativo',    'sotech_ate_apac_solicitacao_procedimento_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'ate_apac_solicitacao_procedimento',  'uuid',     'sotech_ate_apac_solicitacao_procedimento_unq_uuid');
select sotech.sys_create_unq  ('sotech',  'ate_apac_solicitacao_procedimento',  'fkapacsolicitacao, fkprocedimento',    'sotech_ate_apac_sol_proc_unq_fkapacsolicitacao_fkprocedimento');

comment on column sotech.ate_apac_solicitacao_procedimento.pkapacsolicitacaoprocedimento  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_apac_solicitacao_procedimento.fkuser                         is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.ate_apac_solicitacao_procedimento.version                        is '(nn)            - Versionamento do registro';
comment on column sotech.ate_apac_solicitacao_procedimento.fkapacsolicitacao              is '(fk | idx | nn) - Referência com a tabela sotech.ate_apac_solicitacao';
comment on column sotech.ate_apac_solicitacao_procedimento.fkprocedimento                 is '(fk | idx | nn) - Referência com a tabela sotech.tbl_procedimento';
comment on column sotech.ate_apac_solicitacao_procedimento.principal                      is '(idx)           - Flag se é principal';
comment on column sotech.ate_apac_solicitacao_procedimento.quantidade                     is '()              - Quantidade de solicitações de procedimento';

update sotech.ate_apac_solicitacao_procedimento set fkuser      = 0     where sotech.ate_apac_solicitacao_procedimento.fkuser     is null;
update sotech.ate_apac_solicitacao_procedimento set version     = 0     where sotech.ate_apac_solicitacao_procedimento.version    is null;
update sotech.ate_apac_solicitacao_procedimento set principal   = false where sotech.ate_apac_solicitacao_procedimento.principal  is null;
update sotech.ate_apac_solicitacao_procedimento set quantidade  = 1     where sotech.ate_apac_solicitacao_procedimento.quantidade is null;

alter table sotech.ate_apac_solicitacao_procedimento alter column fkuser              set default 0;
alter table sotech.ate_apac_solicitacao_procedimento alter column fkuser              set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column version             set default 0;
alter table sotech.ate_apac_solicitacao_procedimento alter column version             set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column fkapacsolicitacao   set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column fkprocedimento      set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column principal           set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column principal           set default false; 
alter table sotech.ate_apac_solicitacao_procedimento alter column quantidade          set not null;
alter table sotech.ate_apac_solicitacao_procedimento alter column quantidade          set default 1;

create or replace function sotech.ate_apac_solicitacao_procedimento_tratamento() returns trigger as
$$ 
declare
  v_registros record;
  v_erro      text;
begin
  v_erro := '';
  -- fkuser
  if new.fkuser is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Us�rio n�o informado!');
  else
    if (select count(*) from ish.sys_usuario where ish.sys_usuario.pkusuario = new.fkuser) = 0 then
      v_erro := sotech.sys_set_erro(v_erro, 'Us�rio sem refer�ncia! (' || new.fkuser::text || ')');
    end if;
  end if;
  -- version
  if new.version is null then
    new.version := 0;
  else
    if new.version != (select sotech.ate_apac_solicitacao_procedimento.version from sotech.ate_apac_solicitacao_procedimento where sotech.ate_apac_solicitacao_procedimento.pkapacsolicitacaoprocedimento = new.pkapacsolicitacaoprocedimento) then
      v_erro := sotech.sys_set_erro(v_erro, 'Altera��o n�o permitida! �vers�o�');
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
    select into v_registros coalesce((select sotech.ate_apac_solicitacao_procedimento.pkapacsolicitacaoprocedimento from sotech.ate_apac_solicitacao_procedimento where sotech.ate_apac_solicitacao_procedimento.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_apac_solicitacao_procedimento.pkapacsolicitacaoprocedimento <> new.pkapacsolicitacaoprocedimento else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID j� cadastrado! UUID:' || new.uuid::text || ' -> C�d:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '� sotech.ate_apac_solicitacao_procedimento � Usu�rio: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkapacsolicitacaoprocedimento::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_apac_solicitacao_procedimento_auditoria() returns trigger as
$$
declare
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_apac_solicitacao_procedimento';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave := case when tg_op = 'DELETE' then old.pkapacsolicitacaoprocedimento else new.pkapacsolicitacaoprocedimento end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                     end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                      end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                        end);
  -- fkapacsolicitacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkapacsolicitacao',           case when tg_op = 'INSERT' then '' else old.fkapacsolicitacao::text                                             end, case when tg_op = 'DELETE' then '' else new.fkapacsolicitacao::text                                           end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',              case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                                end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                              end);
  -- principal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'principal',                   case when tg_op = 'INSERT' then '' else case when old.principal = true then 'S' else 'N' end                    end, case when tg_op = 'DELETE' then '' else case when new.principal = true then 'S' else 'N' end                  end);
  -- quantidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'quantidade',                  case when tg_op = 'INSERT' then '' else old.quantidade::text                                                    end, case when tg_op = 'DELETE' then '' else new.quantidade::text                                                  end);
  v_retorno := null;
  v_tabela := null;
  v_usuario := null;
  v_chave := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');