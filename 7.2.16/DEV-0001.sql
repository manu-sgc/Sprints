-- Normatização pep.ate_subjetivo_imagem

select sotech.sys_create_field      ('pep',  'ate_subjetivo_imagem',  'fkuser',             'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('pep',  'ate_subjetivo_imagem',  'version',            'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('pep',  'ate_subjetivo_imagem',  'ativo',              'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('pep',  'ate_subjetivo_imagem',  'uuid',               'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('pep',  'ate_subjetivo_imagem',  'fkuser',             'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('pep',  'ate_subjetivo_imagem',  'fkuser',             'pep_ate_subjetivo_imagem_idx_fkuser');
select sotech.sys_create_idx        ('pep',  'ate_subjetivo_imagem',  'ativo',              'pep_ate_subjetivo_imagem_idx_ativo');
select sotech.sys_create_unq        ('pep',  'ate_subjetivo_imagem',  'uuid',               'pep_ate_subjetivo_imagem_unq_uuid');
select sotech.sys_create_fk         ('pep',  'ate_subjetivo_imagem',  'fksubjetivoimagem',  'pep',  'ate_subjetivo_imagem',  'pksubjetivoimagem',  false,  true);
select sotech.sys_create_idx        ('pep',  'ate_subjetivo_imagem',  'fksubjetivoimagem',  'pep_ate_subjetivo_imagem_idx_fksubjetivoimagem');

select sotech.sys_create_audit_table('pep',  'ate_subjetivo_imagem');
select sotech.sys_create_triggers   ('pep',  'ate_subjetivo_imagem',  'pksubjetivoimagem',  'auditoria');
select sotech.sys_create_triggers   ('pep',  'ate_subjetivo_imagem',  'pksubjetivoimagem',  'tratamento');

comment on column pep.ate_subjetivo_imagem.pksubjetivoimagem is '(pk | nn)       - Chave primária da tabela';
comment on column pep.ate_subjetivo_imagem.fkuser            is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column pep.ate_subjetivo_imagem.version           is '(nn)            - Versionamento do registro';
comment on column pep.ate_subjetivo_imagem.titulo            is '()              - Nome do arquivo da imagem';
comment on column pep.ate_subjetivo_imagem.link              is '(nn)            - Link da imagem';
comment on column pep.ate_subjetivo_imagem.fksubjetivo       is '(fk | idx | nn) - Referência com a tabela pep.ate_subjetivo';
comment on column pep.ate_subjetivo_imagem.descricao         is '()              - Descrição da imagem';

update pep.ate_subjetivo_imagem set version = 0 where pep.ate_subjetivo_imagem.version is null;

alter table pep.ate_subjetivo_imagem alter column fkuser  set default 0;
alter table pep.ate_subjetivo_imagem alter column version set default 0;
alter table pep.ate_subjetivo_imagem alter column version set not null;

create or replace function pep.ate_subjetivo_imagem_tratamento () returns trigger as
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
    if new.version != (select pep.ate_subjetivo_imagem.version from pep.ate_subjetivo_imagem where pep.ate_subjetivo_imagem.pksubjetivoimagem = new.pksubjetivoimagem) then
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
    select into v_registros coalesce((select pep.ate_subjetivo_imagem.pksubjetivoimagem from pep.ate_subjetivo_imagem where pep.ate_subjetivo_imagem.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then pep.ate_subjetivo_imagem.pksubjetivoimagem <> new.pksubjetivoimagem else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« pep.ate_subjetivo_imagem » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pksubjetivoimagem::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function pep.ate_subjetivo_imagem_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'pep_ate_subjetivo_imagem';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pksubjetivoimagem else new.pksubjetivoimagem end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- titulo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'titulo',                      case when tg_op = 'INSERT' then '' else old.titulo                                                              end, case when tg_op = 'DELETE' then '' else new.titulo                                                                   end);
  -- link
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'link',                        case when tg_op = 'INSERT' then '' else old.link                                                                end, case when tg_op = 'DELETE' then '' else new.link                                                                     end);
  -- descricao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'descricao',                   case when tg_op = 'INSERT' then '' else old.descricao                                                           end, case when tg_op = 'DELETE' then '' else new.descricao                                                                end);
 -- fksubjetivo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fksubjetivo',                 case when tg_op = 'INSERT' then '' else old.fksubjetivo::text                                                   end, case when tg_op = 'DELETE' then '' else new.fksubjetivo::text                                                        end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;