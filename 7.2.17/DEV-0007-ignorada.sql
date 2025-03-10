---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.cdg_pacientes

select sotech.sys_create_field      ('sotech',  'cdg_pacientes',  'fkuser',     'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'cdg_pacientes',  'version',    'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'cdg_pacientes',  'ativo',      'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'cdg_pacientes',  'uuid',       'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'cdg_pacientes',  'fkuser',     'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'cdg_pacientes',  'fkuser',     'sotech_cdg_pacientes_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'cdg_pacientes',  'ativo',      'sotech_cdg_pacientes_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'cdg_pacientes',  'uuid',       'sotech_cdg_pacientes_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'cdg_pacientes');
select sotech.sys_create_triggers   ('sotech',  'cdg_pacientes',  'pkpaciente', 'auditoria');
select sotech.sys_create_triggers   ('sotech',  'cdg_pacientes',  'pkpaciente', 'tratamento');

comment on column sotech.cdg_pacientes.pkpaciente is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.cdg_pacientes.pacientes  is '(idx)           - Vetor / Código do paciente';

create or replace function sotech.cdg_pacientes_tratamento () returns trigger as
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
    if new.version != (select sotech.cdg_pacientes.version from sotech.cdg_pacientes where sotech.cdg_pacientes.pkpaciente = new.pkpaciente) then
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
    select into v_registros coalesce((select sotech.cdg_pacientes.pkpaciente from sotech.cdg_pacientes where sotech.cdg_pacientes.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.cdg_pacientes.pkpaciente <> new.pkpaciente else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.cdg_pacientes » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkpaciente::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.cdg_pacientes_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_cdg_pacientes';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkpaciente else new.pkpaciente end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- pacientes
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'pacientes',             case when tg_op = 'INSERT' then '' else old.pacientes::text                                            end, case when tg_op = 'DELETE' then '' else new.pacientes::text                                                 end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');