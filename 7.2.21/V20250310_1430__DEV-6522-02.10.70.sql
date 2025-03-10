---------------------------
-- task_id:    DEV-6522
-- version_db: 02.10.70.sql
---------------------------
-- Normatização tabela sotech.tbn_cep

select sotech.sys_create_field      ('sotech',  'tbn_cep',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_cep',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_cep',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_cep',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_cep',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_cep',  'fkuser',   'sotech_tbn_cep_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_cep',  'ativo',    'sotech_tbn_cep_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_cep',  'uuid',     'sotech_tbn_cep_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_cep');
select sotech.sys_create_triggers   ('sotech',  'tbn_cep',  'pkcep',    'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_cep',  'pkcep',    'tratamento');

comment on column sotech.tbn_cep.pkcep        is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_cep.fkmunicipio  is '(fk | idx | nn) - Referência com a tabela sotech.tbn_municipio';
comment on column sotech.tbn_cep.fkbairro     is '(fk | idx | nn) - Referência com a tabela sotech.tbn_bairro';
comment on column sotech.tbn_cep.fklogradouro is '(fk | idx | nn) - Referência com a tabela sotech.tbn_logradouro';
comment on column sotech.tbn_cep.cep          is '(nn)            - Cep da residência';
comment on column sotech.tbn_cep.logradouro   is '(idx | nn)      - Logradouro da residência';
comment on column sotech.tbn_cep.complemento  is '(nn)            - Complemento da residência';

create or replace function sotech.tbn_cep_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_cep.version from sotech.tbn_cep where sotech.tbn_cep.pkcep = new.pkcep) then
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
    select into v_registros coalesce((select sotech.tbn_cep.pkcep from sotech.tbn_cep where sotech.tbn_cep.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_cep.pkcep <> new.pkcep else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.tbn_cep » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkcep::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_cep_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_cep';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkcep else new.pkcep end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkmunicipio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkmunicipio',           case when tg_op = 'INSERT' then '' else old.fkmunicipio::text                                          end, case when tg_op = 'DELETE' then '' else new.fkmunicipio::text                                               end);
  -- fkbairro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkbairro',              case when tg_op = 'INSERT' then '' else old.fkbairro::text                                             end, case when tg_op = 'DELETE' then '' else new.fkbairro::text                                                  end);
  -- fklogradouro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fklogradouro',          case when tg_op = 'INSERT' then '' else old.fklogradouro::text                                         end, case when tg_op = 'DELETE' then '' else new.fklogradouro::text                                              end);
  -- cep
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'cep',                  	case when tg_op = 'INSERT' then '' else old.cep                                                        end, case when tg_op = 'DELETE' then '' else new.cep                                                             end);
  -- logradouro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'logradouro',            case when tg_op = 'INSERT' then '' else old.logradouro                                                 end, case when tg_op = 'DELETE' then '' else new.logradouro                                                      end);
  -- complemento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'complemento',           case when tg_op = 'INSERT' then '' else old.complemento                                                end, case when tg_op = 'DELETE' then '' else new.complemento                                                     end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.70');