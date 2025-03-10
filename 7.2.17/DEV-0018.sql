---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.tbl_municipio

select sotech.sys_create_field      ('sotech',  'tbl_municipio',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbl_municipio',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbl_municipio',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbl_municipio',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbl_municipio',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbl_municipio',  'fkuser',   'sotech_tbl_municipio_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbl_municipio',  'ativo',    'sotech_tbl_municipio_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbl_municipio',  'uuid',     'sotech_tbl_municipio_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbl_municipio');
select sotech.sys_create_triggers   ('sotech',  'tbl_municipio',  'pktblmunicipio',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbl_municipio',  'pktblmunicipio',  'tratamento');

comment on column sotech.tbl_municipio.pktblmunicipio is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbl_municipio.codibge        is '(unq | nn)      - Código do IBGE';
comment on column sotech.tbl_municipio.municipio      is '(idx | nn)      - Nome do município';
comment on column sotech.tbl_municipio.atualizado     is '(idx | nn)      - Flag se está atualizado';

create or replace function sotech.tbl_municipio_tratamento () returns trigger as
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
    if new.version != (select sotech.tbl_municipio.version from sotech.tbl_municipio where sotech.tbl_municipio.pktblmunicipio = new.pktblmunicipio) then
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
    select into v_registros coalesce((select sotech.tbl_municipio.pktblmunicipio from sotech.tbl_municipio where sotech.tbl_municipio.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbl_municipio.pktblmunicipio <> new.pktblmunicipio else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if length(trim(coalesce(new.codibge, ''))) > 0 then
    select into v_registros coalesce((select sotech.tbl_municipio.pktblmunicipio from sotech.tbl_municipio where lower(trim(unaccent(sotech.tbl_municipio.codibge))) = lower(trim(unaccent(new.codibge))) and case when tg_op = 'UPDATE' then sotech.tbl_municipio.pktblmunicipio <> new.pktblmunicipio else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Código IBGE: ' || new.codibge || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbl_municipio » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pktblmunicipio::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbl_municipio_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbl_municipio';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pktblmunicipio else new.pktblmunicipio end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- codibge
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codibge',               case when tg_op = 'INSERT' then '' else old.codibge                                                    end, case when tg_op = 'DELETE' then '' else new.codibge                                                         end);
  -- municipio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'municipio',             case when tg_op = 'INSERT' then '' else old.municipio                                                  end, case when tg_op = 'DELETE' then '' else new.municipio                                                       end);
  -- atualizado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'atualizado',            case when tg_op = 'INSERT' then '' else case when old.atualizado = true then 'S' else 'N' end          end, case when tg_op = 'DELETE' then '' else case when new.atualizado = true then 'S' else 'N' end               end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');