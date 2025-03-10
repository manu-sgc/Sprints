---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.tbn_detalhe

select sotech.sys_create_field('sotech',  'tbn_detalhe',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'tbn_detalhe',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'tbn_detalhe',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'tbn_detalhe',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'tbn_detalhe',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'tbn_detalhe',  'fkuser',   'sotech_tbn_detalhe_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'tbn_detalhe',  'ativo',    'sotech_tbn_detalhe_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'tbn_detalhe',  'uuid',     'sotech_tbn_detalhe_unq_uuid');

select sotech.sys_create_audit_table('sotech',  'tbn_detalhe');
select sotech.sys_create_triggers   ('sotech',  'tbn_detalhe',  'pkdetalhe',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_detalhe',  'pkdetalhe',  'tratamento');

comment on column sotech.tbn_detalhe.pkdetalhe  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_detalhe.coddetalhe is '(idx)           - Código do detalhe';
comment on column sotech.tbn_detalhe.detalhe    is '(unq | nn)      - Nome do detalhe';

create or replace function sotech.tbn_detalhe_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_detalhe.version from sotech.tbn_detalhe where sotech.tbn_detalhe.pkdetalhe = new.pkdetalhe) then
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
    select into v_registros coalesce((select sotech.tbn_detalhe.pkdetalhe from sotech.tbn_detalhe where sotech.tbn_detalhe.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_detalhe.pkdetalhe <> new.pkdetalhe else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_detalhe » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkdetalhe::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_detalhe_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_detalhe';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkdetalhe else new.pkdetalhe end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- coddetalhe
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'coddetalhe',            case when tg_op = 'INSERT' then '' else old.coddetalhe                                                 end, case when tg_op = 'DELETE' then '' else new.coddetalhe                                                      end);
  -- detalhe
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'detalhe',               case when tg_op = 'INSERT' then '' else old.detalhe                                                    end, case when tg_op = 'DELETE' then '' else new.detalhe                                                         end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');