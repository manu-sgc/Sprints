---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.tbn_bairro

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

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');