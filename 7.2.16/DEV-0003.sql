-- Normatização sotech.esus_microarea

select sotech.sys_create_field      ('sotech',  'esus_microarea',  'fkuser',             'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'esus_microarea',  'version',            'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'esus_microarea',  'ativo',              'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'esus_microarea',  'uuid',               'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'esus_microarea',  'fkuser',             'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('sotech',  'esus_microarea',  'fkuser',             'sotech_esus_microarea_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'esus_microarea',  'ativo',              'sotech_esus_microarea_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'esus_microarea',  'uuid',               'sotech_esus_microarea_unq_uuid');
select sotech.sys_create_fk         ('sotech',  'esus_microarea',  'fkarea',             'sotech',   'esus_area',    'pkarea',                  false,  true);

comment on column sotech.esus_microarea.pkmicroarea      is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.esus_microarea.fkuser           is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.esus_microarea.version          is '(nn)            - Versionamento do registro';
comment on column sotech.esus_microarea.fkarea           is '(fk | idx)      - Referência com a tabela sotech.esus_area';
comment on column sotech.esus_microarea.codmicroarea     is '(idx | nn)      - Código da microárea';
comment on column sotech.esus_microarea.microarea        is '(idx | nn)      - Descrição da microárea';
comment on column sotech.esus_microarea.fkequipe         is '(fk | idx | nn) - Referência com a tabela sotech.esus_equipe';
comment on column sotech.esus_microarea.fkagente         is '(fk | idx)      - Referência com a tabela sotech.cdg_interveniente';

update sotech.esus_microarea set fkuser = 0  where sotech.esus_microarea.fkuser  is null;
update sotech.esus_microarea set version = 0 where sotech.esus_microarea.version is null;

alter table sotech.esus_microarea alter column fkuser set default 0;
alter table sotech.esus_microarea alter column fkuser set not null;
alter table sotech.esus_microarea alter column version set default 0;
alter table sotech.esus_microarea alter column version set not null;
alter table sotech.esus_microarea alter column codmicroarea set not null;
alter table sotech.esus_microarea alter column microarea set not null;
alter table sotech.esus_microarea alter column fkequipe set not null;

create or replace function sotech.esus_microarea_tratamento () returns trigger as
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
    if new.version != (select sotech.esus_microarea.version from sotech.esus_microarea where sotech.esus_microarea.pkmicroarea = new.pkmicroarea) then
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
    select into v_registros coalesce((select sotech.esus_microarea.pkmicroarea from sotech.esus_microarea where sotech.esus_microarea.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.esus_microarea.pkmicroarea <> new.pkmicroarea else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.esus_microarea » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkmicroarea::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.esus_microarea_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_esus_microarea';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkmicroarea else new.pkmicroarea end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                     end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                      end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                        end);
  -- fkarea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkarea',                      case when tg_op = 'INSERT' then '' else old.fkarea::text                                                        end, case when tg_op = 'DELETE' then '' else new.fkarea::text                                                      end);
  -- codmicroarea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codmicroarea',                case when tg_op = 'INSERT' then '' else old.codmicroarea                                                        end, case when tg_op = 'DELETE' then '' else new.codmicroarea                                                      end);
  -- microarea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'microarea',                   case when tg_op = 'INSERT' then '' else old.microarea                                                           end, case when tg_op = 'DELETE' then '' else new.microarea                                                         end);
  -- fkequipe
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkequipe',                    case when tg_op = 'INSERT' then '' else old.fkequipe::text                                                      end, case when tg_op = 'DELETE' then '' else new.fkequipe::text                                                    end);
  -- fkagente
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkagente',                    case when tg_op = 'INSERT' then '' else old.fkagente::text                                                      end, case when tg_op = 'DELETE' then '' else new.fkagente::text                                                    end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;