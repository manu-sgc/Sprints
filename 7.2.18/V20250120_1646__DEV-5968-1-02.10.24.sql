---------------------------
-- task_id:    DEV-5968-1
-- version_db: 02.10.24.sql
---------------------------
-- Incluir campo para inclusão de uma hora inicio de aprazamento na tabela sotech.cdg_posto

-- select sotech.sys_create_field('sotech',  'cdg_posto',  'horainicioaprazamento',  'timestamp',  null,   null,   false,  '(idx)           - Horário de início de aprazamento');

-- Alterar campo para tipo time

alter table sotech.cdg_posto alter column horainicioaprazamento type time using horainicioaprazamento::time;

create or replace function sotech.cdg_posto_auditoria () returns trigger as                                                                                                                        
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_cdg_posto';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkposto else new.pkposto end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                  case when tg_op = 'INSERT' then '' else old.version::text                                            end, case when tg_op = 'DELETE' then '' else new.version::text                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                    case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end             end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                     case when tg_op = 'INSERT' then '' else old.uuid::text                                               end, case when tg_op = 'DELETE' then '' else new.uuid::text                                               end);
  -- fkunidadesaude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkunidadesaude',           case when tg_op = 'INSERT' then '' else old.fkunidadesaude::text                                     end, case when tg_op = 'DELETE' then '' else new.fkunidadesaude::text                                     end);
  -- codposto
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codposto',                 case when tg_op = 'INSERT' then '' else old.codposto                                                 end, case when tg_op = 'DELETE' then '' else new.codposto                                                 end);
  -- posto
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'posto',                    case when tg_op = 'INSERT' then '' else old.posto                                                    end, case when tg_op = 'DELETE' then '' else new.posto                                                    end);
  -- horainicioaprazamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'horainicioaprazamento',    case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.horainicioaprazamento::text)    end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.horainicioaprazamento::text)    end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.24');