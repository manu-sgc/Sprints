---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.tbn_cid

select sotech.sys_create_field('sotech',  'tbn_cid',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'tbn_cid',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'tbn_cid',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'tbn_cid',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'tbn_cid',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'tbn_cid',  'fkuser',   'sotech_tbn_cid_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'tbn_cid',  'ativo',    'sotech_tbn_cid_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'tbn_cid',  'uuid',     'sotech_tbn_cid_unq_uuid');

comment on column sotech.tbn_cid.pkcid          is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_cid.agravo         is '(idx | nn)      - Agravo';
comment on column sotech.tbn_cid.competenciaini is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_cid.competenciafim is '(idx | nn)      - Competência final';
comment on column sotech.tbn_cid.sexo           is '(idx | nn)      - Sexo';
comment on column sotech.tbn_cid.codcid         is '(idx | nn)      - Código do cid';
comment on column sotech.tbn_cid.cid            is '(idx | nn)      - Nome do cid';
comment on column sotech.tbn_cid.fkuser         is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.tbn_cid.version        is '(nn)            - Versionamento do registro';
comment on column sotech.tbn_cid.ativo          is '(idx | nn)      - Flag para desabilitar visualização do registro';
comment on column sotech.tbn_cid.uuid           is '(unq | nn)      - UUID do registro';

create or replace function sotech.tbn_cid_tratamento() returns trigger as
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
    if new.version != (select sotech.tbn_cid.version from sotech.tbn_cid where sotech.tbn_cid.pkcid = new.pkcid) then
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
    select into v_registros coalesce((select sotech.tbn_cid.pkcid from sotech.tbn_cid where sotech.tbn_cid.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_cid.pkcid <> new.pkcid else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo);
    end if;
  end if;
  -- agravo
  if length(trim(coalesce(new.agravo, ''))) = 0 then
    v_erro := sotech.sys_set_erro(v_erro, 'Agravo não informado!');
  else
    if new.agravo not in ('0', '1', '2') then
      v_erro := sotech.sys_set_erro(v_erro, 'Agravo inválido!');
    end if;
  end if;
  -- sexo
  if length(trim(coalesce(new.sexo, ''))) = 0 then
    v_erro := sotech.sys_set_erro(v_erro, 'Sexo não informado!');
  else
    if new.sexo not in ('F', 'I', 'M') then
      v_erro := sotech.sys_set_erro(v_erro, 'Sexo inválido!');
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_cid » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkcid::text else '' end || chr(13) || v_erro;
    raise excidtion '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_cid_auditoria() returns trigger as 
$$
declare
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_cid';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech'));
  v_chave   := case when tg_op = 'DELETE' then old.pkcid else new.pkcid end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                                                 case when tg_op = 'INSERT' then '' else old.version::text                                                             end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                                                   case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                              end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                                                    case when tg_op = 'INSERT' then '' else old.uuid::text                                                                end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- agravo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'agravo',                                                  case when tg_op = 'INSERT' then '' else old.agravo                                                                    end, case when tg_op = 'DELETE' then '' else new.agravo                                                                   end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',                                          case when tg_op = 'INSERT' then '' else old.competenciaini                                                            end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                           end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',                                          case when tg_op = 'INSERT' then '' else old.competenciafim                                                            end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                           end);
  -- sexo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'sexo',                                                    case when tg_op = 'INSERT' then '' else old.sexo                                                                      end, case when tg_op = 'DELETE' then '' else new.sexo                                                                     end);
  -- codcid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codcid',                                                  case when tg_op = 'INSERT' then '' else old.codcid                                                                    end, case when tg_op = 'DELETE' then '' else new.codcid                                                                   end);
  -- cid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'cid',                                                     case when tg_op = 'INSERT' then '' else old.cid                                                                       end, case when tg_op = 'DELETE' then '' else new.cid                                                                      end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');