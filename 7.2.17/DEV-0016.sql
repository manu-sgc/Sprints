---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.tbn_procedimentocompatibilidade

select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'tbn_procedimentocompatibilidade',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocompatibilidade',  'fkuser',   'sotech_tbn_procedimentocompatibilidade_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'tbn_procedimentocompatibilidade',  'ativo',    'sotech_tbn_procedimentocompatibilidade_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'tbn_procedimentocompatibilidade',  'uuid',     'sotech_tbn_procedimentocompatibilidade_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'tbn_procedimentocompatibilidade');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocompatibilidade',  'pkprocedimentocompativel',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'tbn_procedimentocompatibilidade',  'pkprocedimentocompativel',  'tratamento');

comment on column sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimentocompatibilidade.fkprocedimentoprincipal  is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocompatibilidade.fkregistroprincipal      is '(fk | idx | nn) - Referência com a tabela sotech.tbn_registro';
comment on column sotech.tbn_procedimentocompatibilidade.fkprocedimentosecundario is '(fk | idx | nn) - Referência com a tabela sotech.tbn_procedimento';
comment on column sotech.tbn_procedimentocompatibilidade.fkregistrosecundario     is '(fk | idx | nn) - Referência com a tabela sotech.tbn_registro';
comment on column sotech.tbn_procedimentocompatibilidade.tipocompatibilidade      is '(idx | nn)      - Tipo da compatibilidade';
comment on column sotech.tbn_procedimentocompatibilidade.quantidade               is '(nn)            - Quantidade de procedimentos';
comment on column sotech.tbn_procedimentocompatibilidade.competenciaini           is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimentocompatibilidade.competenciafim           is '(idx | nn)      - Competência final';

create or replace function sotech.tbn_procedimentocompatibilidade_tratamento () returns trigger as
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
    if new.version != (select sotech.tbn_procedimentocompatibilidade.version from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel = new.pkprocedimentocompativel) then
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
    select into v_registros coalesce((select sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel <> new.pkprocedimentocompativel else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkprocedimentoprincipal is not null and new.fkregistroprincipal is not null and new.fkprocedimentosecundario is not null and new.fkregistrosecundario is not null and new.tipocompatibilidade is not null then
    select into v_registros coalesce((select sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel from sotech.tbn_procedimentocompatibilidade where sotech.tbn_procedimentocompatibilidade.fkprocedimentoprincipal = new.fkprocedimentoprincipal and sotech.tbn_procedimentocompatibilidade.fkregistroprincipal = new.fkregistroprincipal and sotech.tbn_procedimentocompatibilidade.fkprocedimentosecundario = new.fkprocedimentosecundario and sotech.tbn_procedimentocompatibilidade.fkregistrosecundario = new.fkregistrosecundario and sotech.tbn_procedimentocompatibilidade.tipocompatibilidade = new.tipocompatibilidade and case when tg_op = 'UPDATE' then sotech.tbn_procedimentocompatibilidade.pkprocedimentocompativel <> new.pkprocedimentocompativel else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Procedimento Principal: ' || new.fkprocedimentoprincipal::text || ' Registro Principal: ' || new.fkregistroprincipal::text || ' Procedimento Secundário: ' || new.fkprocedimentosecundario::text || ' Registro Secundário: ' || new.fkregistrosecundario::text || ' Tipo Compatibilidade: ' || new.tipocompatibilidade::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimentocompatibilidade » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimentocompativel::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimentocompatibilidade_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimentocompatibilidade';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimentocompativel else new.pkprocedimentocompativel end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                      case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                        case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                    end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                         case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkprocedimentoprincipal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimentoprincipal',      case when tg_op = 'INSERT' then '' else old.fkprocedimentoprincipal::text                              end, case when tg_op = 'DELETE' then '' else new.fkprocedimentoprincipal::text                                   end);
  -- fkregistroprincipal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkregistroprincipal',          case when tg_op = 'INSERT' then '' else old.fkregistroprincipal::text                                  end, case when tg_op = 'DELETE' then '' else new.fkregistroprincipal::text                                       end);
  -- fkprocedimentosecundario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprocedimentosecundario',     case when tg_op = 'INSERT' then '' else old.fkprocedimentosecundario::text                             end, case when tg_op = 'DELETE' then '' else new.fkprocedimentosecundario::text                                  end);
  -- fkregistrosecundario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkregistrosecundario',         case when tg_op = 'INSERT' then '' else old.fkregistrosecundario::text                                 end, case when tg_op = 'DELETE' then '' else new.fkregistrosecundario::text                                      end);
  -- tipocompatibilidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipocompatibilidade',          case when tg_op = 'INSERT' then '' else old.tipocompatibilidade::text                                  end, case when tg_op = 'DELETE' then '' else new.tipocompatibilidade::text                                       end);
  -- quantidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'quantidade',                   case when tg_op = 'INSERT' then '' else old.quantidade::text                                           end, case when tg_op = 'DELETE' then '' else new.quantidade::text                                                end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',               case when tg_op = 'INSERT' then '' else old.competenciaini                                             end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                  end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',               case when tg_op = 'INSERT' then '' else old.competenciafim                                             end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                  end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');