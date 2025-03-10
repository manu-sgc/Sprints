---------------------------
-- task_id:    DEV-5650
-- version_db: 02.10.00.sql
---------------------------
-- Incluir na tabela sotech.tbl_tipoatendimento o tipo de atendimento HEMOCENTRO / Incluir na tabela sotech.ate_estado o estado SALA DE COLETA (HEMOCENTRO) / Incluir na tabela ish.sys_perfil o perfil ATE_HEMOCENTRO_ACESSAR / Normatização sotech.ate_estado
insert into sotech.tbl_tipoatendimento(tipoatendimento, tipo) values ('HEMOCENTRO', 0);

--Incluir na tabela sotech.ate_estado o estado SALA DE COLETA (HEMOCENTRO)
insert into sotech.ate_estado(estado, ordem) values ('SALA DE COLETA (HEMOCENTRO)', (select max(sotech.ate_estado.ordem) + 1 from sotech.ate_estado));

-- Incluir na tabela ish.sys_perfil o perfil ATE_HEMOCENTRO_ACESSAR
insert into ish.sys_perfil(fkuser, fksistema, perfil) values (0, (select ish.sys_sistema.pksistema from ish.sys_sistema where lower(trim(unaccent(ish.sys_sistema.sistema))) = lower(trim(unaccent('IS')))), 'ATE_HEMOCENTRO_ACESSAR');


-- Normatização sotech.ate_estado

select sotech.sys_create_field      ('sotech',  'ate_estado',  'fkuser',             'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'ate_estado',  'version',            'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'ate_estado',  'ativo',              'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'ate_estado',  'uuid',               'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'ate_estado',  'fkuser',             'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_estado',  'fkuser',             'sotech_ate_estado_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'ate_estado',  'ativo',              'sotech_ate_estado_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'ate_estado',  'uuid',               'sotech_ate_estado_unq_uuid');

select sotech.sys_create_audit_table('sotech',  'ate_estado');
select sotech.sys_create_triggers   ('sotech',  'ate_estado',  'pkestado',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_estado',  'pkestado',  'tratamento');

comment on column sotech.ate_estado.pkestado  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_estado.estado    is '(unq | nn)      - Estado da consulta';
comment on column sotech.ate_estado.ordem     is '(nn)            - Ordem dos estados';

create or replace function sotech.ate_estado_tratamento () returns trigger as
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
    if new.version != (select sotech.ate_estado.version from sotech.ate_estado where sotech.ate_estado.pkestado = new.pkestado) then
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
    select into v_registros coalesce((select sotech.ate_estado.pkestado from sotech.ate_estado where sotech.ate_estado.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_estado.pkestado <> new.pkestado else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if length(trim(coalesce(new.estado, ''))) > 0 then
    select into v_registros coalesce((select sotech.ate_estado.pkestado from sotech.ate_estado where lower(trim(unaccent(sotech.ate_estado.estado))) = lower(trim(unaccent(new.estado))) and case when tg_op = 'UPDATE' then sotech.ate_estado.pkestado <> new.pkestado else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Estado: ' || new.estado || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.ate_estado » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkestado::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_estado_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_estado';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkestado else new.pkestado end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',              case when tg_op = 'INSERT' then '' else old.version::text                                                 end, case when tg_op = 'DELETE' then '' else new.version::text                                                     end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                  end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                      end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                 case when tg_op = 'INSERT' then '' else old.uuid::text                                                    end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                        end);
  -- estado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'estado',               case when tg_op = 'INSERT' then '' else old.estado                                                        end, case when tg_op = 'DELETE' then '' else new.estado                                                            end);
 -- ordem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ordem',                case when tg_op = 'INSERT' then '' else old.ordem::text                                                   end, case when tg_op = 'DELETE' then '' else new.ordem::text                                                       end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.00');