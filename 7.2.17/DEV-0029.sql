---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.est_rename

select sotech.sys_create_field      ('sotech',  'est_rename',  'fkuser',  'integer',  null,             '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'est_rename',  'version', 'integer',  null,             '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'est_rename',  'ativo',   'boolean',  null,             'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'est_rename',  'uuid',    'uuid',     null,             'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'est_rename',  'fkuser',  'ish',      'sys_usuario',    'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'est_rename',  'fkuser',  'sotech_est_rename_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'est_rename',  'ativo',   'sotech_est_rename_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'est_rename',  'uuid',    'sotech_est_rename_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'est_rename');
select sotech.sys_create_triggers   ('sotech',  'est_rename',  'pkrename',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'est_rename',  'pkrename',  'tratamento');

comment on column sotech.est_rename.pkrename                is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.est_rename.fkuser                  is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.est_rename.fkatc                   is '(fk | idx)      - Referência com a tabela sotech.est_atc';
comment on column sotech.est_rename.codhorus                is '()              - Código horus';
comment on column sotech.est_rename.denominacaogenerica     is '()              - Denominação genérica';
comment on column sotech.est_rename.concentracao_composicao is '()              - Concentração da composição';
comment on column sotech.est_rename.formateraupetica        is '()              - Forma terapeutica';
comment on column sotech.est_rename.componente              is '()              - Tipo do componente';
comment on column sotech.est_rename.basico                  is '()              - Flag se é básico';
comment on column sotech.est_rename.estrategico             is '()              - Flag se é estratégico';
comment on column sotech.est_rename.especializado           is '()              - Flag se é especializado';
comment on column sotech.est_rename.insumobasico            is '()              - Flag se é um insumo básico';
comment on column sotech.est_rename.insumoestrategico       is '()              - Flag se é um insumo estratégico';
comment on column sotech.est_rename.insumoespecializado     is '()              - Flag se é um insumo especializado';
comment on column sotech.est_rename.hospitalar              is '()              - Flag se é hospitalar';
comment on column sotech.est_rename.altorisco               is '()              - Flag se é de alto risco';

update sotech.est_rename set fkuser = 0 where sotech.est_rename.fkuser  is null;

alter table sotech.est_rename alter column fkuser set default 0;
alter table sotech.est_rename alter column fkuser set not null;

create or replace function sotech.est_rename_tratamento () returns trigger as
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
    if new.version != (select sotech.est_rename.version from sotech.est_rename where sotech.est_rename.pkrename = new.pkrename) then
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
    select into v_registros coalesce((select sotech.est_rename.pkrename from sotech.est_rename where sotech.est_rename.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.est_rename.pkrename <> new.pkrename else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.est_rename » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkrename::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.est_rename_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_est_rename';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkrename else new.pkrename end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                           case when tg_op = 'INSERT' then '' else old.version::text                                                     end, case when tg_op = 'DELETE' then '' else new.version::text                                                        end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                             case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                      end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                              case when tg_op = 'INSERT' then '' else old.uuid::text                                                        end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                           end);
  -- fkatc
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatc',                             case when tg_op = 'INSERT' then '' else old.fkatc::text                                                       end, case when tg_op = 'DELETE' then '' else new.fkatc::text                                                          end);
  -- codhorus
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codhorus',                  	      case when tg_op = 'INSERT' then '' else old.codhorus                                                          end, case when tg_op = 'DELETE' then '' else new.codhorus                                                             end);
  -- denominacaogenerica
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'denominacaogenerica',               case when tg_op = 'INSERT' then '' else old.denominacaogenerica                                               end, case when tg_op = 'DELETE' then '' else new.denominacaogenerica                                                  end);
  -- concentracao_composicao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'concentracao_composicao',           case when tg_op = 'INSERT' then '' else old.concentracao_composicao                                           end, case when tg_op = 'DELETE' then '' else new.concentracao_composicao                                              end);
  -- formaterapeutica
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'formaterapeutica',                  case when tg_op = 'INSERT' then '' else old.formaterapeutica                                                  end, case when tg_op = 'DELETE' then '' else new.formaterapeutica                                                     end);
  -- componente
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'componente',                        case when tg_op = 'INSERT' then '' else old.componente                                                        end, case when tg_op = 'DELETE' then '' else new.componente                                                           end);
  -- basico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'basico',                            case when tg_op = 'INSERT' then '' else case when old.basico = true then 'S' else 'N' end                     end, case when tg_op = 'DELETE' then '' else case when new.basico = true then 'S' else 'N' end                   	    end);
  -- estrategico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'estrategico',                       case when tg_op = 'INSERT' then '' else case when old.estrategico = true then 'S' else 'N' end                end, case when tg_op = 'DELETE' then '' else case when new.estrategico = true then 'S' else 'N' end                   end);
  -- especializado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'especializado',                     case when tg_op = 'INSERT' then '' else case when old.especializado = true then 'S' else 'N' end              end, case when tg_op = 'DELETE' then '' else case when new.especializado = true then 'S' else 'N' end                 end);
  -- insumobasico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'insumobasico',                      case when tg_op = 'INSERT' then '' else case when old.insumobasico = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.insumobasico = true then 'S' else 'N' end                  end);
  -- insumoestrategico
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'insumoestrategico',                 case when tg_op = 'INSERT' then '' else case when old.insumoestrategico = true then 'S' else 'N' end          end, case when tg_op = 'DELETE' then '' else case when new.insumoestrategico = true then 'S' else 'N' end             end);
  -- insumoespecializado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'insumoespecializado',               case when tg_op = 'INSERT' then '' else case when old.insumoespecializado = true then 'S' else 'N' end        end, case when tg_op = 'DELETE' then '' else case when new.insumoespecializado = true then 'S' else 'N' end           end);
  -- hospitalar
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'hospitalar',                        case when tg_op = 'INSERT' then '' else case when old.hospitalar = true then 'S' else 'N' end                 end, case when tg_op = 'DELETE' then '' else case when new.hospitalar = true then 'S' else 'N' end                   	end);
  -- altorisco
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'altorisco',                         case when tg_op = 'INSERT' then '' else case when old.altorisco = true then 'S' else 'N' end                  end, case when tg_op = 'DELETE' then '' else case when new.altorisco = true then 'S' else 'N' end                   	end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');