---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.tbn_servico

select sotech.sys_create_field('sotech',  'tbn_servico',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'tbn_servico',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'tbn_servico',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'tbn_servico',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'tbn_servico',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'tbn_servico',  'fkuser',   'sotech_tbn_servico_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'tbn_servico',  'ativo',    'sotech_tbn_servico_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'tbn_servico',  'uuid',     'sotech_tbn_servico_unq_uuid');

comment on column sotech.tbn_servico.pkservico      is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_servico.codservico     is '(idx | nn)      - Código do servico';
comment on column sotech.tbn_servico.servico        is '(idx | nn)      - Nome do servico';
comment on column sotech.tbn_servico.competenciaini is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_servico.competenciafim is '(idx | nn)      - Competência final';
comment on column sotech.tbn_servico.fkuser         is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.tbn_servico.version        is '(nn)            - Versionamento do registro';
comment on column sotech.tbn_servico.ativo          is '(idx | nn)      - Flag para desabilitar visualização do registro';
comment on column sotech.tbn_servico.uuid           is '(unq | nn)      - UUID do registro';

create or replace function sotech.tbn_servico_tratamento() returns trigger as
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
    if tg_op = 'UPDATE' then
      if new.version != (select sotech.tbn_servico.version from sotech.tbn_servico where sotech.tbn_servico.pkservico = new.pkservico) then
        v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «Versão»');
      end if;
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
    select into v_registros coalesce((select sotech.tbn_servico.pkservico from sotech.tbn_servico where sotech.tbn_servico.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_servico.pkservico <> new.pkservico else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo);
    end if;
  end if;
  -- unique
  if length(trim(coalesce(new.codservico, ''))) > 0 and length(trim(coalesce(new.competenciaini, ''))) > 0 and length(trim(coalesce(new.competenciafim, ''))) > 0 then
    select into v_registros coalesce((select sotech.tbn_servico.pkservico from sotech.tbn_servico where lower(trim(unaccent(sotech.tbn_servico.codservico))) = lower(trim(unaccent(new.codservico))) and lower(trim(unaccent(sotech.tbn_servico.competenciaini))) = lower(trim(unaccent(new.competenciaini))) and lower(trim(unaccent(sotech.tbn_servico.competenciafim))) = lower(trim(unaccent(new.competenciafim))) and case when tg_op = 'UPDATE' then sotech.tbn_servico.pkservico <> new.pkservico else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Códido de serviço: ' || new.codservico || ' Competência inicial: ' || new.competenciaini || ' Competência final: ' || new.competenciafim || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_servico » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkservico::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_servico_auditoria() returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_servico';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech'));
  v_chave   := case when tg_op = 'DELETE' then old.pkservico else new.pkservico end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                                                 case when tg_op = 'INSERT' then '' else old.version::text                                                             end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                                                   case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                              end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                                                    case when tg_op = 'INSERT' then '' else old.uuid::text                                                                end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- codservico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codservico',                                              case when tg_op = 'INSERT' then '' else old.codservico                                                                end, case when tg_op = 'DELETE' then '' else new.codservico                                                               end);
  -- servico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'servico',                                                 case when tg_op = 'INSERT' then '' else old.servico                                                                   end, case when tg_op = 'DELETE' then '' else new.servico                                                                  end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',                                          case when tg_op = 'INSERT' then '' else old.competenciaini                                                            end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                           end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',                                          case when tg_op = 'INSERT' then '' else old.competenciafim                                                            end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                           end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');