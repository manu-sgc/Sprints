---------------------------
-- task_id:    DEV-6519
-- version_db: 02.10.69.sql
---------------------------
-- Normatização tabela sotech.esus_familia_paciente

select sotech.sys_create_field('sotech',  'esus_familia_paciente',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'esus_familia_paciente',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'esus_familia_paciente',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'esus_familia_paciente',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'esus_familia_paciente',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx  ('sotech',  'esus_familia_paciente',  'fkuser',   'sotech_esus_familia_paciente_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'esus_familia_paciente',  'ativo',    'sotech_esus_familia_paciente_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'esus_familia_paciente',  'uuid',     'sotech_esus_familia_paciente_unq_uuid');

comment on column sotech.esus_familia_paciente.pkfamiliapaciente      is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.esus_familia_paciente.fkuser                 is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.esus_familia_paciente.version                is '(idx | nn)      - Versionamento do registro';
comment on column sotech.esus_familia_paciente.fkfamilia              is '(fk | idx | nn) - Referência com a tabela sotech.esus_familia';
comment on column sotech.esus_familia_paciente.fkpaciente             is '(fk | idx | nn) - Referência com a tabela sotech.cdg_paciente';
comment on column sotech.esus_familia_paciente.fkparentesco           is '(fk | idx)      - Referência com a tabela sotech.tbl_parentesco';
comment on column sotech.esus_familia_paciente.responsavel            is '(idx | nn)      - Flag se o familiar é responsável';
comment on column sotech.esus_familia_paciente.foradearea             is '(idx | nn)      - Flag se é fora de área';

update sotech.esus_familia_paciente set fkuser      = 0     where sotech.esus_familia_paciente.fkuser       is null;
update sotech.esus_familia_paciente set version     = 0     where sotech.esus_familia_paciente.version      is null;
update sotech.esus_familia_paciente set responsavel = false where sotech.esus_familia_paciente.responsavel  is null;
update sotech.esus_familia_paciente set foradearea  = false where sotech.esus_familia_paciente.foradearea   is null;

alter table sotech.esus_familia_paciente alter column fkuser       set default 0;
alter table sotech.esus_familia_paciente alter column fkuser       set not null;
alter table sotech.esus_familia_paciente alter column version      set default 0;
alter table sotech.esus_familia_paciente alter column version      set not null;
alter table sotech.esus_familia_paciente alter column fkfamilia    set not null;
alter table sotech.esus_familia_paciente alter column fkpaciente   set not null;
alter table sotech.esus_familia_paciente alter column responsavel  set default false;
alter table sotech.esus_familia_paciente alter column responsavel  set not null;
alter table sotech.esus_familia_paciente alter column foradearea   set default false;
alter table sotech.esus_familia_paciente alter column foradearea   set not null;

create or replace function sotech.esus_familia_paciente_tratamento () returns trigger as
$$
declare 
  v_erro      text;
  v_registros record;
begin
  v_erro := '';
  -- fkuser
  if new.fkuser is null then
    v_erro := sotech.sys_set_erro(v_erro, 'usuário não informado!');
  else
    if (select count(*) from ish.sys_usuario where ish.sys_usuario.pkusuario = new.fkuser) = 0 then
      v_erro := sotech.sys_set_erro(v_erro, 'usuário sem referência! (' || new.fkuser::text || ')');
    end if;
  end if;
  -- version
  if new.version is null then
    new.version := 0;
  else
    if new.version != (select sotech.esus_familia_paciente.version from sotech.esus_familia_paciente where sotech.esus_familia_paciente.pkfamiliapaciente = new.pkfamiliapaciente) then
      v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «versão»');
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
    select into v_registros coalesce((select sotech.esus_familia_paciente.pkfamiliapaciente from sotech.esus_familia_paciente where sotech.esus_familia_paciente.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.esus_familia_paciente.pkfamiliapaciente <> new.pkfamiliapaciente else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkfamilia is not null and new.fkpaciente is not null then
    select into v_registros coalesce((select sotech.esus_familia_paciente.pkfamiliapaciente from sotech.esus_familia_paciente where sotech.esus_familia_paciente.fkfamilia = new.fkfamilia and sotech.esus_familia_paciente.fkpaciente = new.fkpaciente and case when tg_op = 'UPDATE' then sotech.esus_familia_paciente.pkfamiliapaciente <> new.pkfamiliapaciente else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Familia: ' || new.fkfamilia::text || ' Paciente: ' || new.fkpaciente::text ||  ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.esus_familia_paciente » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkfamiliapaciente::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.esus_familia_paciente_auditoria() returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
  v_sql     text;
begin
  v_tabela := 'esus_familia_paciente';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave := case when tg_op = 'DELETE' then old.pkfamiliapaciente else new.pkfamiliapaciente end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                     end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                      end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                        end);
  -- fkfamilia
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkfamilia',                   case when tg_op = 'INSERT' then '' else old.fkfamilia::text                                                     end, case when tg_op = 'DELETE' then '' else new.fkfamilia::text                                                   end);
  -- fkpaciente
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpaciente',                  case when tg_op = 'INSERT' then '' else old.fkpaciente::text                                                    end, case when tg_op = 'DELETE' then '' else new.fkpaciente::text                                                  end);
  -- fkparentesco
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkparentesco',                case when tg_op = 'INSERT' then '' else old.fkparentesco::text                                                  end, case when tg_op = 'DELETE' then '' else new.fkparentesco::text                                                end);
  -- responsavel
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'responsavel',                 case when tg_op = 'INSERT' then '' else case when old.responsavel = true then 'S' else 'N' end                  end, case when tg_op = 'DELETE' then '' else case when new.responsavel = true then 'S' else 'N' end                end);
  -- foradearea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'foradearea',                  case when tg_op = 'INSERT' then '' else case when old.foradearea = true then 'S' else 'N' end                   end, case when tg_op = 'DELETE' then '' else case when new.foradearea = true then 'S' else 'N' end                 end);
  if tg_op = 'insert' then
    -- excluindo referência do paciente em outra família
    v_sql := '';
    v_sql := v_sql || 'delete from sotech.esus_familia_paciente'                                  || chr(13);
    v_sql := v_sql || 'where'                                                                     || chr(13);
    v_sql := v_sql || '      1 = 1'                                                               || chr(13);
    v_sql := v_sql || '  and sotech.esus_familia_paciente.fkfamilia <> ' || new.fkfamilia::text   || chr(13);
    v_sql := v_sql || '  and sotech.esus_familia_paciente.fkpaciente = ' || new.fkpaciente::text  || ';';
    v_sql := sotech.sys_executar_sql(v_sql);
    -- atualizando endereço de indivíduos vinculados às famílias do domicílio:
    v_sql := '';
    v_sql := v_sql || 'update sotech.cdg_paciente set'                                                                                                      || chr(13);
    v_sql := v_sql || '  fkuser = ' || v_usuario::text || ','                                                                                               || chr(13);
    v_sql := v_sql || '  tratar = false,'                                                                                                                   || chr(13);
    v_sql := v_sql || '  fklogradouro = dados.fklogradouro,'                                                                                                || chr(13);
    v_sql := v_sql || '  endereco = dados.logradouro,'                                                                                                      || chr(13);
    v_sql := v_sql || '  numero = dados.numero,'                                                                                                            || chr(13);
    v_sql := v_sql || '  complemento = dados.complemento,'                                                                                                  || chr(13);
    v_sql := v_sql || '  fkuf = dados.fkuf,'                                                                                                                || chr(13);
    v_sql := v_sql || '  fkcidade = dados.fkcidade,'                                                                                                        || chr(13);
    v_sql := v_sql || '  fkbairro = dados.fkbairro'                                                                                                         || chr(13);
    v_sql := v_sql || 'from'                                                                                                                                || chr(13);
    v_sql := v_sql || '  ('                                                                                                                                 || chr(13);
    v_sql := v_sql || '    select'                                                                                                                          || chr(13);
    v_sql := v_sql || '      sotech.esus_familia_paciente.fkpaciente,'                                                                                      || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.fklogradouro,'                                                                                           || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.logradouro,'                                                                                             || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.numero,'                                                                                                 || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.complemento,'                                                                                            || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.fkuf,'                                                                                                   || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.fkcidade,'                                                                                               || chr(13);
    v_sql := v_sql || '      sotech.esus_domicilio.fkbairro'                                                                                                || chr(13);
    v_sql := v_sql || '    from'                                                                                                                            || chr(13);
    v_sql := v_sql || '                  sotech.esus_domicilio'                                                                                             || chr(13);
    v_sql := v_sql || '      inner join    sotech.esus_familia              on      sotech.esus_familia.fkdomicilio = sotech.esus_domicilio.pkdomicilio'    || chr(13);
    v_sql := v_sql || '      inner join      sotech.esus_familia_paciente   on      sotech.esus_familia_paciente.fkfamilia = sotech.esus_familia.pkfamilia' || chr(13);
    v_sql := v_sql || '    where'                                                                                                                           || chr(13);
    v_sql := v_sql || '      sotech.esus_familia_paciente.pkfamiliapaciente = ' || v_chave::text                                                            || chr(13);
    v_sql := v_sql || '  ) as dados'                                                                                                                        || chr(13);
    v_sql := v_sql || 'where'                                                                                                                               || chr(13);
    v_sql := v_sql || '  sotech.cdg_paciente.pkpaciente = dados.fkpaciente'                                                                                 || ';';
    v_sql := sotech.sys_executar_sql(v_sql);
  end if;
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.69');