---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.esus_inep

select sotech.sys_create_field      ('sotech',  'esus_inep',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'esus_inep',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'esus_inep',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'esus_inep',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'esus_inep',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'esus_inep',  'fkuser',   'sotech_esus_inep_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'esus_inep',  'ativo',    'sotech_esus_inep_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'esus_inep',  'uuid',     'sotech_esus_inep_unq_uuid');

comment on column sotech.esus_inep.pkinep         is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.esus_inep.fkuser         is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.esus_inep.version        is '(nn)            - Versionamento do registro';
comment on column sotech.esus_inep.codlocalidade  is '(idx | nn)      - Código da localidade';
comment on column sotech.esus_inep.codinep        is '(unq | nn)      - Código inep';
comment on column sotech.esus_inep.inep           is '(idx | nn)      - Descrição do inep';

update sotech.esus_inep set fkuser  = 0 where sotech.esus_inep.fkuser  is null;
update sotech.esus_inep set version = 0 where sotech.esus_inep.version is null;

alter table sotech.esus_inep alter column fkuser        set default 0;
alter table sotech.esus_inep alter column fkuser        set not null;
alter table sotech.esus_inep alter column version       set default 0;
alter table sotech.esus_inep alter column version       set not null;
alter table sotech.esus_inep alter column codlocalidade set not null;
alter table sotech.esus_inep alter column codinep       set not null;
alter table sotech.esus_inep alter column inep          set not null;

create or replace function sotech.esus_inep_tratamento () returns trigger as
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
    if new.version != (select sotech.esus_inep.version from sotech.esus_inep where sotech.esus_inep.pkinep = new.pkinep) then
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
    select into v_registros coalesce((select sotech.esus_inep.pkinep from sotech.esus_inep where sotech.esus_inep.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.esus_inep.pkinep <> new.pkinep else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if length(trim(coalesce(new.codinep, ''))) > 0 then
    select into v_registros coalesce((select sotech.esus_inep.pkinep from sotech.esus_inep where lower(trim(unaccent(sotech.esus_inep.codinep))) = lower(trim(unaccent(new.codinep))) and case when tg_op = 'UPDATE' then sotech.esus_inep.pkinep <> new.pkinep else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Código INEP: ' || new.codinep || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
	-- tratando versão
	if tg_op = 'UPDATE' then
		if new.version != (select sotech.esus_inep.version from sotech.esus_inep where sotech.esus_inep.pkinep = new.pkinep) then
			v_erro := v_erro || 'Alteração não permitida! «Versão»' || chr(13);
		end if;
	end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.esus_inep » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkinep::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.esus_inep_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'esus_inep';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkinep else new.pkinep end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- codlocalidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codlocalidade',               case when tg_op = 'INSERT' then '' else old.codlocalidade::text                                                 end, case when tg_op = 'DELETE' then '' else new.codlocalidade::text                                                      end);
  -- codinep
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codinep',                     case when tg_op = 'INSERT' then '' else old.codinep                                                             end, case when tg_op = 'DELETE' then '' else new.codinep                                                                  end);
  -- inep
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'inep',                        case when tg_op = 'INSERT' then '' else old.inep                                                                end, case when tg_op = 'DELETE' then '' else new.inep                                                                     end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');