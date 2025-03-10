---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.ate_chamada

select sotech.sys_create_field      ('sotech',  'ate_chamada',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'ate_chamada',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'ate_chamada',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'ate_chamada',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'ate_chamada',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_chamada',  'fkuser',   'sotech_ate_chamada_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'ate_chamada',  'ativo',    'sotech_ate_chamada_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'ate_chamada',  'uuid',     'sotech_ate_chamada_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'ate_chamada');
select sotech.sys_create_triggers   ('sotech',  'ate_chamada',  'pkchamada',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_chamada',  'pkchamada',  'tratamento');

comment on column sotech.ate_chamada.pkchamada       is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_chamada.fkatendimento   is '(fk | idx)      - Referência com a tabela sotech.ate_atendimento';
comment on column sotech.ate_chamada.fkchekin        is '(fk | idx)      - Referência com a tabela sotech.ate_chekin';
comment on column sotech.ate_chamada.fkusuario       is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.ate_chamada.datachamada     is '(idx | nn)      - Data da chamada';
comment on column sotech.ate_chamada.chamadas        is '(nn)            - Chamadas';
comment on column sotech.ate_chamada.chamada         is '(idx | nn)      - Chamada';
comment on column sotech.ate_chamada.ordem           is '(idx | nn)      - Ordem da chamada';
comment on column sotech.ate_chamada.fkguichesenha   is '(fk | idx)      - Referência com a tabela sotech.ate_guiche_senhas';
comment on column sotech.ate_chamada.dataatendimento is '()              - Data do atendimento';

alter table sotech.ate_chamada alter column fkusuario set default 0;

create or replace function sotech.ate_chamada_tratamento () returns trigger as
$$
declare
  v_registros record;
  v_erro      text;
begin
  v_erro := '';
  -- fkuser
  if new.fkuser is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Usuário não informado!');
  else
    if (select count(*) from ish.sys_usuario where ish.sys_usuario.pkusuario = new.fkuser) = 0 then
      v_erro := sotech.sys_set_erro(v_erro, 'Usuário sem referência! (' || new.fkuser::text || ')');
    end if;
  end if;
  -- version
  if new.version is null then
    new.version := 0;
  else
    if new.version != (select sotech.ate_chamada.version from sotech.ate_chamada where sotech.ate_chamada.pkchamada = new.pkchamada) then
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
    select into v_registros coalesce((select sotech.ate_chamada.pkchamada from sotech.ate_chamada where sotech.ate_chamada.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_chamada.pkchamada <> new.pkchamada else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.ate_chamada » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkchamada::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_chamada_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_chamada';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkchamada else new.pkchamada end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                case when tg_op = 'INSERT' then '' else old.version::text                                         end, case when tg_op = 'DELETE' then '' else new.version::text                                              end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                  case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end          end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end               end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                   case when tg_op = 'INSERT' then '' else old.uuid::text                                            end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                 end);
  -- fkatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatendimento',          case when tg_op = 'INSERT' then '' else old.fkatendimento::text                                   end, case when tg_op = 'DELETE' then '' else new.fkatendimento::text                                        end);
  -- fkchekin
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkchekin',               case when tg_op = 'INSERT' then '' else old.fkchekin::text                                        end, case when tg_op = 'DELETE' then '' else new.fkchekin::text                                             end);
  -- datachamada
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datachamada',            case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datachamada::text)           end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datachamada::text)                end);
  -- chamadas
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'chamadas',               case when tg_op = 'INSERT' then '' else old.chamadas::text                                        end, case when tg_op = 'DELETE' then '' else new.chamadas::text                                             end);
  -- chamada
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'chamada',                case when tg_op = 'INSERT' then '' else old.chamada::text                                         end, case when tg_op = 'DELETE' then '' else new.chamada::text                                              end);
  -- ordem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ordem',                  case when tg_op = 'INSERT' then '' else old.ordem::text                                           end, case when tg_op = 'DELETE' then '' else new.ordem::text                                                end);
  -- fkguichesenha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkguichesenha',          case when tg_op = 'INSERT' then '' else old.fkguichesenha::text                                   end, case when tg_op = 'DELETE' then '' else new.fkguichesenha::text                                        end);
  -- dataatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'dataatendimento',        case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.dataatendimento::text)       end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.dataatendimento::text)            end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');