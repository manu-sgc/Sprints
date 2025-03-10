---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.crl_fichaitens

select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'fkuser',  'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'version', 'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'ativo',   'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'crl_fichaitens',  'uuid',    'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'crl_fichaitens',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'crl_fichaitens',  'fkuser',  'sotech_crl_fichaitens_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'crl_fichaitens',  'ativo',   'sotech_crl_fichaitens_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'crl_fichaitens',  'uuid',    'sotech_crl_fichaitens_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'crl_fichaitens');
select sotech.sys_create_triggers   ('sotech',  'crl_fichaitens',  'pkfichaitem',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'crl_fichaitens',  'pkfichaitem',  'tratamento');

comment on column sotech.crl_fichaitens.pkfichaitem  	  is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.crl_fichaitens.fkficha         is '(fk | idx | nn) - Referência com a tabela sotech.crl_ficha';
comment on column sotech.crl_fichaitens.fktipodado      is '(fk | idx)      - Referência com a tabela sotech.crl_tipodado';
comment on column sotech.crl_fichaitens.fkestilo        is '(fk | idx)      - Referência com a tabela sotech.crl_estilo';
comment on column sotech.crl_fichaitens.tipo            is '(idx | nn)      - Tipo da ficha';
comment on column sotech.crl_fichaitens.fichaitem       is '()              - Nome do item da ficha';
comment on column sotech.crl_fichaitens.esquerda        is '(nn)            - Espaçamento na esquerda';
comment on column sotech.crl_fichaitens.topo            is '(nn)            - Espaçamento no topo';
comment on column sotech.crl_fichaitens.tamanho         is '(nn)            - Tamanho do item';
comment on column sotech.crl_fichaitens.alinhamento     is '()              - Tipo de alinhamento';
comment on column sotech.crl_fichaitens.tipolinha       is '()              - Tipo da linha';
comment on column sotech.crl_fichaitens.orientacaolinha is '()              - Orientação da linha';
comment on column sotech.crl_fichaitens.altura          is '()              - Altura do item';
comment on column sotech.crl_fichaitens.somatorio       is '(nn)            - Somatório';

create or replace function sotech.crl_fichaitens_tratamento () returns trigger as
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
    if new.version != (select sotech.crl_fichaitens.version from sotech.crl_fichaitens where sotech.crl_fichaitens.pkfichaitem = new.pkfichaitem) then
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
    select into v_registros coalesce((select sotech.crl_fichaitens.pkfichaitem from sotech.crl_fichaitens where sotech.crl_fichaitens.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.crl_fichaitens.pkfichaitem <> new.pkfichaitem else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.crl_fichaitens » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkfichaitem::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.crl_fichaitens_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_crl_fichaitens';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkfichaitem else new.pkfichaitem end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',           case when tg_op = 'INSERT' then '' else old.version::text                                          end, case when tg_op = 'DELETE' then '' else new.version::text                                               end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',             case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end           end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',              case when tg_op = 'INSERT' then '' else old.uuid::text                                             end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                  end);
  -- fkficha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkficha',           case when tg_op = 'INSERT' then '' else old.fkficha::text                                          end, case when tg_op = 'DELETE' then '' else new.fkficha::text                                               end);
  -- fktipodado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipodado',        case when tg_op = 'INSERT' then '' else old.fktipodado::text                                       end, case when tg_op = 'DELETE' then '' else new.fktipodado::text                                            end);
  -- fkestilo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkestilo',          case when tg_op = 'INSERT' then '' else old.fkestilo::text                                         end, case when tg_op = 'DELETE' then '' else new.fkestilo::text                                              end);
  -- tipo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipo',              case when tg_op = 'INSERT' then '' else old.tipo                                                   end, case when tg_op = 'DELETE' then '' else new.tipo                                                        end);
  -- fichaitem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fichaitem',         case when tg_op = 'INSERT' then '' else old.fichaitem                                              end, case when tg_op = 'DELETE' then '' else new.fichaitem                                                   end);
  -- esquerda
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'esquerda',          case when tg_op = 'INSERT' then '' else old.esquerda::text                                         end, case when tg_op = 'DELETE' then '' else new.esquerda::text                                              end);
  -- topo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'topo',              case when tg_op = 'INSERT' then '' else old.topo::text                                             end, case when tg_op = 'DELETE' then '' else new.topo::text                                                  end);
  -- tamanho
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tamanho',           case when tg_op = 'INSERT' then '' else old.tamanho::text                                          end, case when tg_op = 'DELETE' then '' else new.tamanho::text                                               end);
  -- alinhamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'alinhamento',       case when tg_op = 'INSERT' then '' else old.alinhamento                                            end, case when tg_op = 'DELETE' then '' else new.alinhamento                                                 end);
  -- tipolinha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipolinha',         case when tg_op = 'INSERT' then '' else old.tipolinha                                              end, case when tg_op = 'DELETE' then '' else new.tipolinha                                                   end);
  -- orientacaolinha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'orientacaolinha',   case when tg_op = 'INSERT' then '' else old.orientacaolinha                                        end, case when tg_op = 'DELETE' then '' else new.orientacaolinha                                             end);
  -- altura
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'altura',            case when tg_op = 'INSERT' then '' else old.altura::text                                           end, case when tg_op = 'DELETE' then '' else new.altura::text                                                end);
  -- somatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'somatorio',         case when tg_op = 'INSERT' then '' else old.somatorio::text                                        end, case when tg_op = 'DELETE' then '' else new.somatorio::text                                             end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');