---------------------------
-- task_id:    DEV-6678
-- version_db: 02.10.71.sql
---------------------------
-- Normatização das tabela em lote sotech.esus_inep, sotech.tbn_procedimentocid, sotech.tbn_bairro, sotech.crl_fichaitens, sotech.ate_movimentacao_leito, sotech.tbn_procedimentocbo, sotech.est_estoque, sotech.ate_chamada, sotech.tbn_procedimentocompatibilidade, sotech.tbn_procedimentomodalidade, sotech.tbl_municipio, sotech.tbn_procedimentodetalhe, sotech.tbn_procedimentoregistro

-- sotech.esus_inep
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

-- sotech.tbn_procedimentocid
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocid',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocid',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocid',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocid',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentocid',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocid',  'fkuser',   'sotech_tbn_procedimentocid_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocid',  'ativo',    'sotech_tbn_procedimentocid_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentocid',  'uuid',     'sotech_tbn_procedimentocid_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentocid');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocid',  'pkprocedimentocid',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocid',  'pkprocedimentocid',  'tratamento');

comment on column sotech.tbn_procedimentocid.pkprocedimentocid is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentocid.fkprocedimento    is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocid.fkcid             is '(fk | idx | nn) - Referência com a tabela sotech.tbn_cid';
comment on column sotech.tbn_procedimentocid.principal         is '(idx | nn)      - Principal';
comment on column sotech.tbn_procedimentocid.competenciaini    is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentocid.competenciafim    is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentocid_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentocid.version from sotech.tbn_procedimentocid where sotech.tbn_procedimentocid.pkprocedimentocid = new.pkprocedimentocid) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentocid.pkprocedimentocid from sotech.tbn_procedimentocid where sotech.tbn_procedimentocid.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocid.pkprocedimentocid <> new.pkprocedimentocid else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimento is not null and new.fkcid is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentocid.pkprocedimentocid from sotech.tbn_procedimentocid where sotech.tbn_procedimentocid.fkprocedimento = new.fkprocedimento and sotech.tbn_procedimentocid.fkcid = new.fkcid and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocid.pkprocedimentocid <> new.pkprocedimentocid else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Procedimento: ' || new.fkprocedimento::text || ' CID: ' || new.fkcid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentocid » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentocid::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentocid_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentocid';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentocid else new.pkprocedimentocid end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',        case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                            end);
  -- fkcid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkcid',                 case when tg_op = 'INSERT' then '' else old.fkcid::text                                                end, case when tg_op = 'DELETE' then '' else new.fkcid::text                                                     end);
  -- principal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'principal',             case when tg_op = 'INSERT' then '' else old.principal                                                  end, case when tg_op = 'DELETE' then '' else new.principal                                                       end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',        case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',        case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.tbn_bairro
select sotech.sys_create_field      ('sotech',  'tbn_bairro',  'fkuser',      'integer',  null,             '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_bairro',  'version',     'integer',  null,             '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_bairro',  'ativo',       'boolean',  null,             'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_bairro',  'uuid',        'uuid',     null,             'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_bairro',  'fkuser',      'ish',      'sys_usuario',    'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_bairro',  'fkuser',      'sotech_tbn_bairro_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_bairro',  'ativo',       'sotech_tbn_bairro_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_bairro',  'uuid',        'sotech_tbn_bairro_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_bairro');
select sotech.sys_create_triggers   ('sotech',  'tbn_bairro',  'pkbairro',  'auditoria');

comment on column sotech.tbn_bairro.pkbairro  	is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_bairro.fkmunicipio is '(fk | idx | nn) - Referência com a tabela sotech.tbn_municipio';
comment on column sotech.tbn_bairro.bairro      is '(idx | nn)      - Nome do bairro';
comment on column sotech.tbn_bairro.uuid        is '(unq | nn)      - UUID do registro';
comment on column sotech.tbn_bairro.ativo       is '(idx | nn)      - Flag para desabilitar visualização do registro';

create or replace function sotech.tbn_bairro_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_bairro.version from sotech.tbn_bairro where sotech.tbn_bairro.pkbairro = new.pkbairro) then
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
    select into v_registros coalesce((select sotech.tbn_bairro.pkbairro from sotech.tbn_bairro where sotech.tbn_bairro.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_bairro.pkbairro <> new.pkbairro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkmunicipio is not null and length(trim(coalesce(new.bairro, ''))) > 0 then
    select into v_registros coalesce((select sotech.tbn_bairro.pkbairro from sotech.tbn_bairro where sotech.tbn_bairro.fkmunicipio = new.fkmunicipio and lower(trim(unaccent(sotech.tbn_bairro.bairro))) = lower(trim(unaccent(new.bairro))) and case when tg_op = 'UPDATE' then sotech.tbn_bairro.pkbairro <> new.pkbairro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Município: ' || new.fkmunicipio::text || ' Bairro: ' || new.bairro || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_bairro » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkbairro::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_bairro_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_bairro';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkbairro else new.pkbairro end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkmunicipio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkmunicipio',           case when tg_op = 'INSERT' then '' else old.fkmunicipio::text                                          end, case when tg_op = 'DELETE' then '' else new.fkmunicipio::text                                               end);
  -- bairro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'bairro',                case when tg_op = 'INSERT' then '' else old.bairro                                                     end, case when tg_op = 'DELETE' then '' else new.bairro                                                          end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.crl_fichaitens
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'fkuser',  'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'version', 'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'ativo',   'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'uuid',    'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'crl_fichaitens',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'crl_fichaitens',  'fkuser',  'sotech_crl_fichaitens_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'crl_fichaitens',  'ativo',   'sotech_crl_fichaitens_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'crl_fichaitens',  'uuid',    'sotech_crl_fichaitens_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'crl_fichaitens');
select sotech.sys_create_triggers   ('sotech',  'crl_fichaitens',  'pkfichaitem',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'crl_fichaitens',  'pkfichaitem',  'tratamento');

comment on column sotech.crl_fichaitens.pkfichaitem  	  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.crl_fichaitens.fkficha         is '(fk | idx | nn) - Referência com a tabela sotech.crl_ficha';
comment on column sotech.crl_fichaitens.fktipodado      is '(fk | idx)      - Referência com a tabela sotech.crl_tipodado';
comment on column sotech.crl_fichaitens.fkestilo        is '(fk | idx)      - Referência com a tabela sotech.crl_estilo';
comment on column sotech.crl_fichaitens.tipo            is '(idx | nn)      - Tipo da ficha';
comment on column sotech.crl_fichaitens.fichaitem       is '()              - Nome do item da ficha';
comment on column sotech.crl_fichaitens.esquerda        is '(nn)            - Espaçamento na esquerda';
comment on column sotech.crl_fichaitens.topo            is '(nn)            - Espaçamento no topo';
comment on column sotech.crl_fichaitens.tamanho         is '(nn)            - Tamanho do item';
comment on column sotech.crl_fichaitens.alinhamento     is '()              - Tipo de alinhamento';
comment on column sotech.crl_fichaitens.tipolinha       is '()              - Tipo da linha';
comment on column sotech.crl_fichaitens.orientacaolinha is '()              - Orientação da linha';
comment on column sotech.crl_fichaitens.altura          is '()              - Altura do item';
comment on column sotech.crl_fichaitens.somatorio       is '(nn)            - Somatório';

create or replace function sotech.crl_fichaitens_tratamento () returns trigger as
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
    if new.version != (select sotech.crl_fichaitens.version from sotech.crl_fichaitens where sotech.crl_fichaitens.pkfichaitem = new.pkfichaitem) then
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
    select into v_registros coalesce((select sotech.crl_fichaitens.pkfichaitem from sotech.crl_fichaitens where sotech.crl_fichaitens.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.crl_fichaitens.pkfichaitem <> new.pkfichaitem else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.crl_fichaitens » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkfichaitem::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.crl_fichaitens_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_crl_fichaitens';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkfichaitem else new.pkfichaitem end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',           case when tg_op = 'INSERT' then '' else old.version::text                                          end, case when tg_op = 'DELETE' then '' else new.version::text                                               end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',             case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end           end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',              case when tg_op = 'INSERT' then '' else old.uuid::text                                             end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                  end);
  -- fkficha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkficha',           case when tg_op = 'INSERT' then '' else old.fkficha::text                                          end, case when tg_op = 'DELETE' then '' else new.fkficha::text                                               end);
  -- fktipodado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipodado',        case when tg_op = 'INSERT' then '' else old.fktipodado::text                                       end, case when tg_op = 'DELETE' then '' else new.fktipodado::text                                            end);
  -- fkestilo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkestilo',          case when tg_op = 'INSERT' then '' else old.fkestilo::text                                         end, case when tg_op = 'DELETE' then '' else new.fkestilo::text                                              end);
  -- tipo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipo',              case when tg_op = 'INSERT' then '' else old.tipo                                                   end, case when tg_op = 'DELETE' then '' else new.tipo                                                        end);
  -- fichaitem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fichaitem',         case when tg_op = 'INSERT' then '' else old.fichaitem                                              end, case when tg_op = 'DELETE' then '' else new.fichaitem                                                   end);
  -- esquerda
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'esquerda',          case when tg_op = 'INSERT' then '' else old.esquerda::text                                         end, case when tg_op = 'DELETE' then '' else new.esquerda::text                                              end);
  -- topo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'topo',              case when tg_op = 'INSERT' then '' else old.topo::text                                             end, case when tg_op = 'DELETE' then '' else new.topo::text                                                  end);
  -- tamanho
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tamanho',           case when tg_op = 'INSERT' then '' else old.tamanho::text                                          end, case when tg_op = 'DELETE' then '' else new.tamanho::text                                               end);
  -- alinhamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'alinhamento',       case when tg_op = 'INSERT' then '' else old.alinhamento                                            end, case when tg_op = 'DELETE' then '' else new.alinhamento                                                 end);
  -- tipolinha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipolinha',         case when tg_op = 'INSERT' then '' else old.tipolinha                                              end, case when tg_op = 'DELETE' then '' else new.tipolinha                                                   end);
  -- orientacaolinha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'orientacaolinha',   case when tg_op = 'INSERT' then '' else old.orientacaolinha                                        end, case when tg_op = 'DELETE' then '' else new.orientacaolinha                                             end);
  -- altura
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'altura',            case when tg_op = 'INSERT' then '' else old.altura::text                                           end, case when tg_op = 'DELETE' then '' else new.altura::text                                                end);
  -- somatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'somatorio',         case when tg_op = 'INSERT' then '' else old.somatorio::text                                        end, case when tg_op = 'DELETE' then '' else new.somatorio::text                                             end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.ate_movimentacao_leito
drop trigger if exists ate_movimentacao_leito_auditoria on sotech.ate_movimentacao_leito;
drop function if exists sotech.ate_movimentacao_leito_auditoria();

select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'fkuser',  'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'version', 'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'ativo',   'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'uuid',    'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'ate_movimentacao_leito',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_movimentacao_leito',  'fkuser',  'sotech_ate_movimentacao_leito_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'ate_movimentacao_leito',  'ativo',   'sotech_ate_movimentacao_leito_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'ate_movimentacao_leito',  'uuid',    'sotech_ate_movimentacao_leito_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'ate_movimentacao_leito');
select sotech.sys_create_triggers   ('sotech',  'ate_movimentacao_leito',  'pkmovimentacaoleito',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_movimentacao_leito',  'pkmovimentacaoleito',  'tratamento');

comment on column sotech.ate_movimentacao_leito.pkmovimentacaoleito is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_movimentacao_leito.fkuser              is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.ate_movimentacao_leito.fkatendimento       is '(fk | idx | nn) - Referência com a tabela sotech.ate_atendimento';
comment on column sotech.ate_movimentacao_leito.fkpostoorigem       is '(fk | idx | nn) - Referência com a tabela sotech.cdg_posto';
comment on column sotech.ate_movimentacao_leito.fkleitoorigem       is '(fk | idx)      - Referência com a tabela sotech.cdg_leito';
comment on column sotech.ate_movimentacao_leito.fkpostodestino      is '(fk | idx)      - Referência com a tabela sotech.cdg_posto';
comment on column sotech.ate_movimentacao_leito.fkleitodestino      is '(fk | idx)      - Referência com a tabela sotech.cdg_leito';
comment on column sotech.ate_movimentacao_leito.tipo                is '(idx)           - Tipo da movimentação';
comment on column sotech.ate_movimentacao_leito.dataabertura        is '(idx | nn)      - Data de abertura';
comment on column sotech.ate_movimentacao_leito.datafechamento      is '(idx)           - Data de fechamento';
comment on column sotech.ate_movimentacao_leito.estado              is '(idx)           - Estado da movimentação - "A"- Aberta; "C" - Cancelada; "F" - Fechada';
comment on column sotech.ate_movimentacao_leito.uuid                is '(unq | nn)      - UUID do registro';
comment on column sotech.ate_movimentacao_leito.version             is '(nn)            - Versionamento do registro';

update sotech.ate_movimentacao_leito set fkuser = 0 where sotech.ate_movimentacao_leito.fkuser  is null;

alter table sotech.ate_movimentacao_leito alter column fkuser set default 0;
alter table sotech.ate_movimentacao_leito alter column fkuser set not null;

create or replace function sotech.ate_movimentacao_leito_tratamento () returns trigger as
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
    if new.version != (select sotech.ate_movimentacao_leito.version from sotech.ate_movimentacao_leito where sotech.ate_movimentacao_leito.pkmovimentacaoleito = new.pkmovimentacaoleito) then
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
    select into v_registros coalesce((select sotech.ate_movimentacao_leito.pkmovimentacaoleito from sotech.ate_movimentacao_leito where sotech.ate_movimentacao_leito.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_movimentacao_leito.pkmovimentacaoleito <> new.pkmovimentacaoleito else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.ate_movimentacao_leito » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkmovimentacaoleito::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_movimentacao_leito_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_movimentacao_leito';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkmovimentacaoleito else new.pkmovimentacaoleito end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatendimento',         case when tg_op = 'INSERT' then '' else old.fkatendimento::text                                        end, case when tg_op = 'DELETE' then '' else new.fkatendimento::text                                             end);
  -- fkpostoorigem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpostoorigem',         case when tg_op = 'INSERT' then '' else old.fkpostoorigem::text                                        end, case when tg_op = 'DELETE' then '' else new.fkpostoorigem::text                                             end);
  -- fkleitoorigem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkleitoorigem',         case when tg_op = 'INSERT' then '' else old.fkleitoorigem::text                                        end, case when tg_op = 'DELETE' then '' else new.fkleitoorigem::text                                             end);
  -- fkpostodestino
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpostodestino',        case when tg_op = 'INSERT' then '' else old.fkpostodestino::text                                       end, case when tg_op = 'DELETE' then '' else new.fkpostodestino::text                                            end);
  -- fkleitodestino
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkleitodestino',        case when tg_op = 'INSERT' then '' else old.fkleitodestino::text                                       end, case when tg_op = 'DELETE' then '' else new.fkleitodestino::text                                            end);
  -- tipo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipo',                  case when tg_op = 'INSERT' then '' else old.tipo                                                       end, case when tg_op = 'DELETE' then '' else new.tipo                                                            end);
  -- dataabertura
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'dataabertura',          case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.dataabertura::text)               end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.dataabertura::text)                    end);
  -- datafechamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datafechamento',        case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datafechamento::text)             end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datafechamento::text)                  end);
  -- estado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'estado',                case when tg_op = 'INSERT' then '' else old.estado                                                     end, case when tg_op = 'DELETE' then '' else new.estado                                                          end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.tbn_procedimentocbo
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocbo',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocbo',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocbo',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocbo',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentocbo',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocbo',  'fkuser',   'sotech_tbn_procedimentocbo_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocbo',  'ativo',    'sotech_tbn_procedimentocbo_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentocbo',  'uuid',     'sotech_tbn_procedimentocbo_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentocbo');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocbo',  'pkprocedimentocbo',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocbo',  'pkprocedimentocbo',  'tratamento');

comment on column sotech.tbn_procedimentocbo.pkprocedimentocbo is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentocbo.fkprocedimento    is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocbo.fkcbo             is '(fk | idx | nn) - Referência com a tabela sotech.tbn_cbo';
comment on column sotech.tbn_procedimentocbo.competenciaini    is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentocbo.competenciafim    is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentocbo_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentocbo.version from sotech.tbn_procedimentocbo where sotech.tbn_procedimentocbo.pkprocedimentocbo = new.pkprocedimentocbo) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentocbo.pkprocedimentocbo from sotech.tbn_procedimentocbo where sotech.tbn_procedimentocbo.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocbo.pkprocedimentocbo <> new.pkprocedimentocbo else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.tbn_procedimentocbo » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentocbo::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentocbo_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentocbo';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentocbo else new.pkprocedimentocbo end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',        case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                            end);
  -- fkcbo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkcbo',                 case when tg_op = 'INSERT' then '' else old.fkcbo::text                                                end, case when tg_op = 'DELETE' then '' else new.fkcbo::text                                                     end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',        case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',        case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.est_estoque
select sotech.sys_create_field      ('sotech',  'est_estoque',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'est_estoque',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'est_estoque',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'est_estoque',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'est_estoque',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('sotech',  'est_estoque',  'fkuser',   'sotech_est_estoque_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'est_estoque',  'ativo',    'sotech_est_estoque_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'est_estoque',  'uuid',     'sotech_est_estoque_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'est_estoque');
select sotech.sys_create_triggers   ('sotech',  'est_estoque',  'pkestoque',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'est_estoque',  'pkestoque',  'tratamento');

comment on column sotech.est_estoque.pkestoque      is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.est_estoque.fkunidadesaude is '(fk | idx | nn) - Referência com a tabela sotech.cdg_unidadesaude';
comment on column sotech.est_estoque.fkdeposito     is '(fk | idx | nn) - Referência com a tabela sotech.est_deposito';
comment on column sotech.est_estoque.fkcontrole     is '(fk | idx | nn) - Referência com a tabela sotech.est_pedidoitem';
comment on column sotech.est_estoque.quantidade     is '(idx | nn)      - Quantidade no estoque';

create or replace function sotech.est_estoque_tratamento () returns trigger as
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
    if new.version != (select sotech.est_estoque.version from sotech.est_estoque where sotech.est_estoque.pkestoque = new.pkestoque) then
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
    select into v_registros coalesce((select sotech.est_estoque.pkestoque from sotech.est_estoque where sotech.est_estoque.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.est_estoque.pkestoque <> new.pkestoque else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.est_estoque » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkestoque::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.est_estoque_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_est_estoque';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkestoque else new.pkestoque end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkunidadesaude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkunidadesaude',        case when tg_op = 'INSERT' then '' else old.fkunidadesaude::text                                       end, case when tg_op = 'DELETE' then '' else new.fkunidadesaude::text                                            end);
  -- fkdeposito
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkdeposito',            case when tg_op = 'INSERT' then '' else old.fkdeposito::text                                           end, case when tg_op = 'DELETE' then '' else new.fkdeposito::text                                                end);
  -- fkcontrole
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkcontrole',            case when tg_op = 'INSERT' then '' else old.fkcontrole::text                                           end, case when tg_op = 'DELETE' then '' else new.fkcontrole::text                                                end);
  -- quantidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'quantidade',            case when tg_op = 'INSERT' then '' else sotech.formatar_valor(old.quantidade, 4)                       end, case when tg_op = 'DELETE' then '' else sotech.formatar_valor(new.quantidade, 4)                            end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.ate_chamada
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

-- sotech.tbn_procedimentocompatibilidade
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'sotech_tbn_procedimentocompatibilidade_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocompatibilidade',  'ativo',    'sotech_tbn_procedimentocompatibilidade_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentocompatibilidade',  'uuid',     'sotech_tbn_procedimentocompatibilidade_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentocompatibilidade');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocompatibilidade',  'pkprocedimentocompativel',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocompatibilidade',  'pkprocedimentocompativel',  'tratamento');

comment on column sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentocompatibilidade.fkprocedimentoprincipal  is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocompatibilidade.fkregistroprincipal      is '(fk | idx | nn) - Referência com a tabela sotech.tbn_registro';
comment on column sotech.tbn_procedimentocompatibilidade.fkprocedimentosecundario is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocompatibilidade.fkregistrosecundario     is '(fk | idx | nn) - Referência com a tabela sotech.tbn_registro';
comment on column sotech.tbn_procedimentocompatibilidade.tipocompatibilidade      is '(idx | nn)      - Tipo da compatibilidade';
comment on column sotech.tbn_procedimentocompatibilidade.quantidade               is '(nn)            - Quantidade de procedimentos';
comment on column sotech.tbn_procedimentocompatibilidade.competenciaini           is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentocompatibilidade.competenciafim           is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentocompatibilidade_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentocompatibilidade.version from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel = new.pkprocedimentocompativel) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel <> new.pkprocedimentocompativel else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimentoprincipal is not null and new.fkregistroprincipal is not null and new.fkprocedimentosecundario is not null and new.fkregistrosecundario is not null and new.tipocompatibilidade is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.fkprocedimentoprincipal = new.fkprocedimentoprincipal and sotech.tbn_procedimentocompatibilidade.fkregistroprincipal = new.fkregistroprincipal and sotech.tbn_procedimentocompatibilidade.fkprocedimentosecundario = new.fkprocedimentosecundario and sotech.tbn_procedimentocompatibilidade.fkregistrosecundario = new.fkregistrosecundario and sotech.tbn_procedimentocompatibilidade.tipocompatibilidade = new.tipocompatibilidade and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel <> new.pkprocedimentocompativel else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Procedimento Principal: ' || new.fkprocedimentoprincipal::text || ' Registro Principal: ' || new.fkregistroprincipal::text || ' Procedimento Secundário: ' || new.fkprocedimentosecundario::text || ' Registro Secundário: ' || new.fkregistrosecundario::text || ' Tipo Compatibilidade: ' || new.tipocompatibilidade::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentocompatibilidade » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentocompativel::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentocompatibilidade_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentocompatibilidade';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentocompativel else new.pkprocedimentocompativel end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimentoprincipal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimentoprincipal',      case when tg_op = 'INSERT' then '' else old.fkprocedimentoprincipal::text                              end, case when tg_op = 'DELETE' then '' else new.fkprocedimentoprincipal::text                                   end);
  -- fkregistroprincipal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkregistroprincipal',          case when tg_op = 'INSERT' then '' else old.fkregistroprincipal::text                                  end, case when tg_op = 'DELETE' then '' else new.fkregistroprincipal::text                                       end);
  -- fkprocedimentosecundario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimentosecundario',     case when tg_op = 'INSERT' then '' else old.fkprocedimentosecundario::text                             end, case when tg_op = 'DELETE' then '' else new.fkprocedimentosecundario::text                                  end);
  -- fkregistrosecundario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkregistrosecundario',         case when tg_op = 'INSERT' then '' else old.fkregistrosecundario::text                                 end, case when tg_op = 'DELETE' then '' else new.fkregistrosecundario::text                                      end);
  -- tipocompatibilidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipocompatibilidade',          case when tg_op = 'INSERT' then '' else old.tipocompatibilidade::text                                  end, case when tg_op = 'DELETE' then '' else new.tipocompatibilidade::text                                       end);
  -- quantidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'quantidade',                   case when tg_op = 'INSERT' then '' else old.quantidade::text                                           end, case when tg_op = 'DELETE' then '' else new.quantidade::text                                                end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.tbn_procedimentomodalidade
select sotech.sys_create_field      ('sotech',  'tbn_procedimentomodalidade',  'fkuser',  'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentomodalidade',  'version', 'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentomodalidade',  'ativo',   'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentomodalidade',  'uuid',    'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentomodalidade',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentomodalidade',  'fkuser',  'sotech_tbn_procedimentomodalidade_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentomodalidade',  'ativo',   'sotech_tbn_procedimentomodalidade_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentomodalidade',  'uuid',    'sotech_tbn_procedimentomodalidade_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentomodalidade');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentomodalidade',  'pkprocedimentomodalidade',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentomodalidade',  'pkprocedimentomodalidade',  'tratamento');

comment on column sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentomodalidade.fkprocedimento           is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentomodalidade.fkmodalidade             is '(fk | idx | nn) - Referência com a tabela sotech.tbn_modalidade';
comment on column sotech.tbn_procedimentomodalidade.competenciaini           is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentomodalidade.competenciafim           is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentomodalidade_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentomodalidade.version from sotech.tbn_procedimentomodalidade where sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade = new.pkprocedimentomodalidade) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade from sotech.tbn_procedimentomodalidade where sotech.tbn_procedimentomodalidade.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade <> new.pkprocedimentomodalidade else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimento is not null and new.fkmodalidade is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade from sotech.tbn_procedimentomodalidade where sotech.tbn_procedimentomodalidade.fkprocedimento = new.fkprocedimento and sotech.tbn_procedimentomodalidade.fkmodalidade = new.fkmodalidade and case when tg_op = 'UPDATE' then sotech.tbn_procedimentomodalidade.pkprocedimentomodalidade <> new.pkprocedimentomodalidade else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Procedimento: ' || new.fkprocedimento::text || ' Modalidade: ' || new.fkmodalidade::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentomodalidade » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentomodalidade::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentomodalidade_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentomodalidade';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentomodalidade else new.pkprocedimentomodalidade end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',               case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                            end);
  -- fkmodalidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkmodalidade',                 case when tg_op = 'INSERT' then '' else old.fkmodalidade::text                                         end, case when tg_op = 'DELETE' then '' else new.fkmodalidade::text                                              end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.tbl_municipio
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

-- sotech.tbn_procedimentodetalhe
select sotech.sys_create_field      ('sotech',  'tbn_procedimentodetalhe',  'fkuser',  'integer',  null,           '0',                   true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentodetalhe',  'version', 'integer',  null,           '0',                   true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentodetalhe',  'ativo',   'boolean',  null,           'true',                true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentodetalhe',  'uuid',    'uuid',     null,           'uuid_generate_v4()',  true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentodetalhe',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',           false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentodetalhe',  'fkuser',  'sotech_tbn_procedimentodetalhe_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentodetalhe',  'ativo',   'sotech_tbn_procedimentodetalhe_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentodetalhe',  'uuid',    'sotech_tbn_procedimentodetalhe_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentodetalhe');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentodetalhe',  'pkprocedimentodetalhe',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentodetalhe',  'pkprocedimentodetalhe',  'tratamento');

comment on column sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentodetalhe.fkprocedimento        is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentodetalhe.fkdetalhe             is '(fk | idx | nn) - Referência com a tabela sotech.tbn_detalhe';
comment on column sotech.tbn_procedimentodetalhe.competenciaini        is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentodetalhe.competenciafim        is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentodetalhe_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentodetalhe.version from sotech.tbn_procedimentodetalhe where sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe = new.pkprocedimentodetalhe) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe from sotech.tbn_procedimentodetalhe where sotech.tbn_procedimentodetalhe.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe <> new.pkprocedimentodetalhe else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimento is not null and new.fkdetalhe is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe from sotech.tbn_procedimentodetalhe where sotech.tbn_procedimentodetalhe.fkprocedimento = new.fkprocedimento and sotech.tbn_procedimentodetalhe.fkdetalhe = new.fkdetalhe and case when tg_op = 'UPDATE' then sotech.tbn_procedimentodetalhe.pkprocedimentodetalhe <> new.pkprocedimentodetalhe else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Procedimento: ' || new.fkprocedimento::text || ' Detalhe: ' || new.fkdetalhe>>text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentodetalhe » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentodetalhe::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentodetalhe_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentodetalhe';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentodetalhe else new.pkprocedimentodetalhe end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',               case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                            end);
  -- fkdetalhe
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkdetalhe',                    case when tg_op = 'INSERT' then '' else old.fkdetalhe::text                                            end, case when tg_op = 'DELETE' then '' else new.fkdetalhe::text                                                 end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- sotech.tbn_procedimentoregistro
select sotech.sys_create_field      ('sotech',  'tbn_procedimentoregistro',  'fkuser',  'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentoregistro',  'version', 'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentoregistro',  'ativo',   'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentoregistro',  'uuid',    'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentoregistro',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentoregistro',  'fkuser',  'sotech_tbn_procedimentoregistro_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentoregistro',  'ativo',   'sotech_tbn_procedimentoregistro_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentoregistro',  'uuid',    'sotech_tbn_procedimentoregistro_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentoregistro');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentoregistro',  'pkprocedimentoregistro',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentoregistro',  'pkprocedimentoregistro',  'tratamento');

comment on column sotech.tbn_procedimentoregistro.pkprocedimentoregistro is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentoregistro.fkprocedimento         is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentoregistro.fkregistro             is '(fk | idx | nn) - Referência com a tabela sotech.tbn_registro';
comment on column sotech.tbn_procedimentoregistro.competenciaini         is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentoregistro.competenciafim         is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentoregistro_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentoregistro.version from sotech.tbn_procedimentoregistro where sotech.tbn_procedimentoregistro.pkprocedimentoregistro = new.pkprocedimentoregistro) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentoregistro.pkprocedimentoregistro from sotech.tbn_procedimentoregistro where sotech.tbn_procedimentoregistro.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentoregistro.pkprocedimentoregistro <> new.pkprocedimentoregistro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimento is not null and new.fkregistro is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentoregistro.pkprocedimentoregistro from sotech.tbn_procedimentoregistro where sotech.tbn_procedimentoregistro.fkprocedimento = new.fkprocedimento and sotech.tbn_procedimentoregistro.fkregistro = new.fkregistro and case when tg_op = 'UPDATE' then sotech.tbn_procedimentoregistro.pkprocedimentoregistro <> new.pkprocedimentoregistro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registre já cadastrado! Procedimento: ' || new.fkprocedimento::text || ' Registro: ' || new.fkregistro::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentoregistro » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentoregistro::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentoregistro_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentoregistro';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentoregistro else new.pkprocedimentoregistro end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimento',               case when tg_op = 'INSERT' then '' else old.fkprocedimento::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprocedimento::text                                            end);
  -- fkregistro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkregistro',                   case when tg_op = 'INSERT' then '' else old.fkregistro::text                                           end, case when tg_op = 'DELETE' then '' else new.fkregistro::text                                                end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.71');