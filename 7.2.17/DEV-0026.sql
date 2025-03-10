---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.tbl_funcionalidade_regra

select sotech.sys_create_field   ('sotech',  'tbl_funcionalidade_regra',  'fkuser',       'integer',  null,                  '0',                     true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field   ('sotech',  'tbl_funcionalidade_regra',  'version',      'integer',  null,                  '0',                     true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field   ('sotech',  'tbl_funcionalidade_regra',  'ativo',        'boolean',  null,                  'true',                  true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field   ('sotech',  'tbl_funcionalidade_regra',  'uuid',         'uuid',     null,                  'uuid_generate_v4()',    true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk      ('sotech',  'tbl_funcionalidade_regra',  'fkuser',       'ish',      'sys_usuario',         'pkusuario',             false,  true);
select sotech.sys_create_idx     ('sotech',  'tbl_funcionalidade_regra',  'fkuser',       'sotech_tbl_funcionalidade_regra_idx_fkuser');
select sotech.sys_create_idx     ('sotech',  'tbl_funcionalidade_regra',  'ativo',        'sotech_tbl_funcionalidade_regra_idx_ativo');
select sotech.sys_create_unq     ('sotech',  'tbl_funcionalidade_regra',  'uuid',         'sotech_tbl_funcionalidade_regra_unq_uuid');
select sotech.sys_create_fk      ('sotech',  'tbl_funcionalidade_regra',  'fkformulario', 'sotech',   '',  '',        false,  true);
select sotech.sys_create_triggers('sotech',  'tbl_funcionalidade_regra',  'pkfuncionalidaderegra',  'tratamento');

comment on column sotech.tbl_funcionalidade_regra.pkfuncionalidaderegra is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbl_funcionalidade_regra.fkformulario          is '(fk | idx | nn) - Referência com a tabela sotech.';
comment on column sotech.tbl_funcionalidade_regra.fkfuncionalidade      is '(fk | idx | nn) - Referência com a tabela sotech.tbl_funcionalidade';
comment on column sotech.tbl_funcionalidade_regra.fkunidadesaude        is '(fk | idx)      - Referência com a tabela sotech.cdg_unidadesaude';
comment on column sotech.tbl_funcionalidade_regra.fkgrupousuario        is '(fk | idx)      - Referência com a tabela ?.fr_grupo';
comment on column sotech.tbl_funcionalidade_regra.fkusuario             is '(fk | idx)      - Referência com a tabela ish.sys_usuario';
comment on column sotech.tbl_funcionalidade_regra.fkuser                is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';

update sotech.tbl_funcionalidade_regra set fkuser = 0 where sotech.tbl_funcionalidade_regra.fkuser  is null;

alter table sotech.tbl_funcionalidade_regra alter column fkuser set default 0;

create or replace function sotech.tbl_funcionalidade_regra_tratamento () returns trigger as
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
    if new.version != (select sotech.tbl_funcionalidade_regra.version from sotech.tbl_funcionalidade_regra where sotech.tbl_funcionalidade_regra.pkfuncionalidaderegra = new.pkfuncionalidaderegra) then
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
    select into v_registros coalesce((select sotech.tbl_funcionalidade_regra.pkfuncionalidaderegra from sotech.tbl_funcionalidade_regra where sotech.tbl_funcionalidade_regra.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbl_funcionalidade_regra.pkfuncionalidaderegra <> new.pkfuncionalidaderegra else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkformulario is not null and new.fkfuncionalidade is not null and new.fkunidadesaude is not null and new.fkgrupousuario is not null and new.fkusuario is not null then
    select into v_registros coalesce((select sotech.esus_familia_paciente.pkfamiliapaciente from sotech.esus_familia_paciente where sotech.esus_familia_paciente.fkformulario = new.fkformulario and sotech.esus_familia_paciente.fkfuncionalidade = new.fkfuncionalidade and case when tg_op = 'UPDATE' then sotech.esus_familia_paciente.pkfamiliapaciente <> new.pkfamiliapaciente else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Familia: ' || new.fkformulario::text || ' Paciente: ' || new.fkfuncionalidade::text ||  ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbl_funcionalidade_regra » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkfuncionalidaderegra::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbl_funcionalidade_regra_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbl_funcionalidade_regra';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkfuncionalidaderegra else new.pkfuncionalidaderegra end;
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
  -- fkunidadesaude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkunidadesaude',        case when tg_op = 'INSERT' then '' else old.fkunidadesaude::text                                       end, case when tg_op = 'DELETE' then '' else new.fkunidadesaude::text                                            end);
  -- fkgrupousuario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkgrupousuario',        case when tg_op = 'INSERT' then '' else old.fkgrupousuario::text                                       end, case when tg_op = 'DELETE' then '' else new.fkgrupousuario::text                                            end);
  -- fkusuario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkusuario',             case when tg_op = 'INSERT' then '' else old.fkusuario::text                                            end, case when tg_op = 'DELETE' then '' else new.fkusuario::text                                                 end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbl_funcionalidade_regra_auditoria () returns trigger as
$$
begin
   if (TG_OP = 'DELETE') then
      -- fkformulario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(old.fkuser, 1),
         'E',
         'tbl_funcionalidade_regra',
         'fkformulario',
         coalesce(cast(old.fkformulario as text), ''),
         '',
         old.pkfuncionalidaderegra;
      -- fkfuncionalidade:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(old.fkuser, 1),
         'E',
         'tbl_funcionalidade_regra',
         'fkfuncionalidade',
         coalesce(cast(old.fkfuncionalidade as text), ''),
         '',
         old.pkfuncionalidaderegra;
      -- fkunidadesaude:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(old.fkuser, 1),
         'E',
         'tbl_funcionalidade_regra',
         'fkunidadesaude',
         coalesce(cast(old.fkunidadesaude as text), ''),
         '',
         old.pkfuncionalidaderegra;
      -- fkgrupousuario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(old.fkuser, 1),
         'E',
         'tbl_funcionalidade_regra',
         'fkgrupousuario',
         coalesce(cast(old.fkgrupousuario as text), ''),
         '',
         old.pkfuncionalidaderegra;
      -- fkusuario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(old.fkuser, 1),
         'E',
         'tbl_funcionalidade_regra',
         'fkusuario',
         coalesce(cast(old.fkusuario as text), ''),
         '',
         old.pkfuncionalidaderegra;
      return old;
   elsif (TG_OP = 'UPDATE') then
      -- fkformulario:
      if (md5(coalesce(cast(old.fkformulario as text), '')) <> md5(coalesce(cast(new.fkformulario as text), ''))) then
         insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
         select
            coalesce(new.fkuser, 1),
            'A',
            'tbl_funcionalidade_regra',
            'fkformulario',
            coalesce(cast(old.fkformulario as text), ''),
            coalesce(cast(new.fkformulario as text), ''),
            new.pkfuncionalidaderegra;
      end if;
      -- fkfuncionalidade:
      if (md5(coalesce(cast(old.fkfuncionalidade as text), '')) <> md5(coalesce(cast(new.fkfuncionalidade as text), ''))) then
         insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
         select
            coalesce(new.fkuser, 1),
            'A',
            'tbl_funcionalidade_regra',
            'fkfuncionalidade',
            coalesce(cast(old.fkfuncionalidade as text), ''),
            coalesce(cast(new.fkfuncionalidade as text), ''),
            new.pkfuncionalidaderegra;
      end if;
      -- fkunidadesaude:
      if (md5(coalesce(cast(old.fkunidadesaude as text), '')) <> md5(coalesce(cast(new.fkunidadesaude as text), ''))) then
         insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
         select
            coalesce(new.fkuser, 1),
            'A',
            'tbl_funcionalidade_regra',
            'fkunidadesaude',
            coalesce(cast(old.fkunidadesaude as text), ''),
            coalesce(cast(new.fkunidadesaude as text), ''),
            new.pkfuncionalidaderegra;
      end if;
      -- fkgrupousuario:
      if (md5(coalesce(cast(old.fkgrupousuario as text), '')) <> md5(coalesce(cast(new.fkgrupousuario as text), ''))) then
         insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
         select
            coalesce(new.fkuser, 1),
            'A',
            'tbl_funcionalidade_regra',
            'fkgrupousuario',
            coalesce(cast(old.fkgrupousuario as text), ''),
            coalesce(cast(new.fkgrupousuario as text), ''),
            new.pkfuncionalidaderegra;
      end if;
      -- fkusuario:
      if (md5(coalesce(cast(old.fkusuario as text), '')) <> md5(coalesce(cast(new.fkusuario as text), ''))) then
         insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
         select
            coalesce(new.fkuser, 1),
            'A',
            'tbl_funcionalidade_regra',
            'fkusuario',
            coalesce(cast(old.fkusuario as text), ''),
            coalesce(cast(new.fkusuario as text), ''),
            new.pkfuncionalidaderegra;
      end if;
      return new;
   elsif (TG_OP = 'INSERT') then
      -- fkformulario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(new.fkuser, 1),
         'I',
         'tbl_funcionalidade_regra',
         'fkformulario',
         '',
         coalesce(cast(new.fkformulario as text), ''),
         new.pkfuncionalidaderegra;
      -- fkfuncionalidade:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(new.fkuser, 1),
         'I',
         'tbl_funcionalidade_regra',
         'fkfuncionalidade',
         '',
         coalesce(cast(new.fkfuncionalidade as text), ''),
         new.pkfuncionalidaderegra;
      -- fkunidadesaude:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(new.fkuser, 1),
         'I',
         'tbl_funcionalidade_regra',
         'fkunidadesaude',
         '',
         coalesce(cast(new.fkunidadesaude as text), ''),
         new.pkfuncionalidaderegra;
      -- fkgrupousuario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(new.fkuser, 1),
         'I',
         'tbl_funcionalidade_regra',
         'fkgrupousuario',
         '',
         coalesce(cast(new.fkgrupousuario as text), ''),
         new.pkfuncionalidaderegra;
      -- fkusuario:
      insert into sotech.sys_auditoria (fkusuario, operacao, tabela, campo, anterior, atual, chave)
      select
         coalesce(new.fkuser, 1),
         'I',
         'tbl_funcionalidade_regra',
         'fkusuario',
         '',
         coalesce(cast(new.fkusuario as text), ''),
         new.pkfuncionalidaderegra;
      return new;
   end if;
   return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');