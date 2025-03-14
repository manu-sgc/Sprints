---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.rel_formulario_funcionalidade

select sotech.sys_create_field      ('sotech',  'rel_formulario_funcionalidade',  'fkuser',       'integer',      null,       '0',                  true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'rel_formulario_funcionalidade',  'version',      'integer',      null,       '0',                  true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'rel_formulario_funcionalidade',  'ativo',        'boolean',      null,       'true',               true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'rel_formulario_funcionalidade',  'uuid',         'uuid',         null,       'uuid_generate_v4()', true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'rel_formulario_funcionalidade',  'fkuser',       'ish',      'sys_usuario',  'pkusuario',          false,  true);
select sotech.sys_create_idx        ('sotech',  'rel_formulario_funcionalidade',  'fkuser',       'sotech_rel_formulario_funcionalidade_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'rel_formulario_funcionalidade',  'ativo',        'sotech_rel_formulario_funcionalidade_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'rel_formulario_funcionalidade',  'uuid',         'sotech_rel_formulario_funcionalidade_unq_uuid');
select sotech.sys_create_fk         ('sotech',  'rel_formulario_funcionalidade',  'fkformulario', 'sotech',   '',  '',        false,  true);
select sotech.sys_create_audit_table('sotech',  'rel_formulario_funcionalidade');
select sotech.sys_create_triggers   ('sotech',  'rel_formulario_funcionalidade',  'pkformulariofuncionalidade',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'rel_formulario_funcionalidade',  'pkformulariofuncionalidade',  'tratamento');

comment on column sotech.rel_formulario_funcionalidade.pkformulariofuncionalidade            is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.rel_formulario_funcionalidade.fkformulario     is '(fk | idx | nn) - Referência com a tabela sotech.?';
comment on column sotech.rel_formulario_funcionalidade.fkfuncionalidade is '(fk | idx | nn) - Referência com a tabela sotech.tbl_funcionalidade';

create or replace function sotech.rel_formulario_funcionalidade_tratamento () returns trigger as
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
    if new.version != (select sotech.rel_formulario_funcionalidade.version from sotech.rel_formulario_funcionalidade where sotech.rel_formulario_funcionalidade.pkformulariofuncionalidade = new.pkformulariofuncionalidade) then
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
    select into v_registros coalesce((select sotech.rel_formulario_funcionalidade.pkformulariofuncionalidade from sotech.rel_formulario_funcionalidade where sotech.rel_formulario_funcionalidade.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.rel_formulario_funcionalidade.pkformulariofuncionalidade <> new.pkformulariofuncionalidade else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.rel_formulario_funcionalidade » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkformulariofuncionalidade::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.rel_formulario_funcionalidade_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_rel_formulario_funcionalidade';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkformulariofuncionalidade else new.pkformulariofuncionalidade end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkformulario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkformulario',          case when tg_op = 'INSERT' then '' else old.fkformulario::text                                         end, case when tg_op = 'DELETE' then '' else new.fkformulario::text                                              end);
  -- fkfuncionalidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkfuncionalidade',      case when tg_op = 'INSERT' then '' else old.fkfuncionalidade::text                                     end, case when tg_op = 'DELETE' then '' else new.fkfuncionalidade::text                                          end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');