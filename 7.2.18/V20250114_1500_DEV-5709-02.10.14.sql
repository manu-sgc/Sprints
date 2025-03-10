---------------------------
-- task_id:    DEV-5709
-- version_db: 02.10.14.sql
---------------------------
-- Criação de tabela auxiliar para obrigatoriedade de campos na prescrição - pep.ate_prescricao_obrigatoriedade

select sotech.sys_create_table      ('pep',  'ate_prescricao_obrigatoriedade',  'pkprescricaoobrigatoriedade',  'integer');
select sotech.sys_create_field      ('pep',  'ate_prescricao_obrigatoriedade',  'fkpadraoprescricao',           'integer',  null,   null,   false,  '(fk | idx)      - Referência com a tabela pep.ate_padrao_prescricao');
select sotech.sys_create_field      ('pep',  'ate_prescricao_obrigatoriedade',  'fktipopadraoprescricao',       'integer',  null,   null,   false,  '(fk | idx)      - Referência com a tabela pep.ate_tipo_padrao_prescricao');
select sotech.sys_create_field      ('pep',  'ate_prescricao_obrigatoriedade',  'obrigatorio',                  'boolean',  null,   null,   true,   '(idx | nn)      - Flag que indica se a prescrição é obrigatória');
select sotech.sys_create_field      ('pep',  'ate_prescricao_obrigatoriedade',  'campo',                        'text',     null,   null,   true,   '(nn)            - Campo obrigatoriedade da prescrição');
select sotech.sys_create_fk         ('pep',  'ate_prescricao_obrigatoriedade',  'fkpadraoprescricao',           'pep',      'ate_padrao_prescricao',        'pkpadraoprescricao',       false,  true);
select sotech.sys_create_fk         ('pep',  'ate_prescricao_obrigatoriedade',  'fktipopadraoprescricao',       'pep',      'ate_tipo_padrao_prescricao',   'pktipopadraoprescricao',   false,  true);
select sotech.sys_create_idx        ('pep',  'ate_prescricao_obrigatoriedade',  'fkpadraoprescricao',           'pep_ate_prescricao_obrigatoriedade_idx_fkpadraoprescricao');
select sotech.sys_create_idx        ('pep',  'ate_prescricao_obrigatoriedade',  'fktipopadraoprescricao',       'pep_ate_prescricao_obrigatoriedade_idx_fktipopadraoprescricao');
select sotech.sys_create_idx        ('pep',  'ate_prescricao_obrigatoriedade',  'obrigatorio',                  'pep_ate_prescricao_obrigatoriedade_idx_obrigatorio');
select sotech.sys_create_audit_table('pep',  'ate_prescricao_obrigatoriedade');
select sotech.sys_create_triggers   ('pep',  'ate_prescricao_obrigatoriedade',  'pkprescricaoobrigatoriedade',  'auditoria');
select sotech.sys_create_triggers   ('pep',  'ate_prescricao_obrigatoriedade',  'pkprescricaoobrigatoriedade',  'tratamento');

create or replace function pep.ate_prescricao_obrigatoriedade_tratamento () returns trigger as
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
    if new.version != (select pep.ate_prescricao_obrigatoriedade.version from pep.ate_prescricao_obrigatoriedade where pep.ate_prescricao_obrigatoriedade.pkprescricaoobrigatoriedade = new.pkprescricaoobrigatoriedade) then
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
    select into v_registros coalesce((select pep.ate_prescricao_obrigatoriedade.pkprescricaoobrigatoriedade from pep.ate_prescricao_obrigatoriedade where pep.ate_prescricao_obrigatoriedade.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then pep.ate_prescricao_obrigatoriedade.pkprescricaoobrigatoriedade <> new.pkprescricaoobrigatoriedade else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« pep.ate_prescricao_obrigatoriedade » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprescricaoobrigatoriedade::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function pep.ate_prescricao_obrigatoriedade_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'pep_ate_prescricao_obrigatoriedade';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprescricaoobrigatoriedade else new.pkprescricaoobrigatoriedade end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                   case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                     case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                      case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkpadraoprescricao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpadraoprescricao',        case when tg_op = 'INSERT' then '' else old.fkpadraoprescricao::text                                   end, case when tg_op = 'DELETE' then '' else new.fkpadraoprescricao::text                                        end);
  -- fktipopadraoprescricao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipopadraoprescricao',    case when tg_op = 'INSERT' then '' else old.fktipopadraoprescricao::text                               end, case when tg_op = 'DELETE' then '' else new.fktipopadraoprescricao::text                                    end);
  -- obrigatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'obrigatorio',               case when tg_op = 'INSERT' then '' else case when old.obrigatorio = true then 'S' else 'N' end         end, case when tg_op = 'DELETE' then '' else case when new.obrigatorio = true then 'S' else 'N' end              end);
  -- campo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'campo',                     case when tg_op = 'INSERT' then '' else old.campo                                                      end, case when tg_op = 'DELETE' then '' else new.campo                                                           end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.14');
