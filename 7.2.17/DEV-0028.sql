---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.crl_coluna

select sotech.sys_create_field('sotech',  'crl_coluna',  'fkuser',  'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'crl_coluna',  'version', 'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'crl_coluna',  'ativo',   'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'crl_coluna',  'uuid',    'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'crl_coluna',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'crl_coluna',  'fkuser',  'sotech_crl_coluna_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'crl_coluna',  'ativo',   'sotech_crl_coluna_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'crl_coluna',  'uuid',    'sotech_crl_coluna_unq_uuid');

select sotech.sys_create_audit_table('sotech',  'crl_coluna');
select sotech.sys_create_triggers   ('sotech',  'crl_coluna',  'pkcoluna',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'crl_coluna',  'pkcoluna',  'tratamento');

comment on column sotech.crl_coluna.pkcoluna    is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.crl_coluna.fkrelatorio is '(fk | idx | nn) - Referência com a tabela sotech.crl_relatorio';
comment on column sotech.crl_coluna.fktipodado  is '(fk | idx | nn) - Referência com a tabela sotech.crl_tipodado';
comment on column sotech.crl_coluna.indice      is '(idx | nn)      - Índice da coluna';
comment on column sotech.crl_coluna.ordem       is '(idx | nn)      - Ordem da coluna';
comment on column sotech.crl_coluna.coluna      is '(idx | nn)      - Nome da coluna';
comment on column sotech.crl_coluna.alinhamento is '(nn)            - Tipo do alinhamento';
comment on column sotech.crl_coluna.somatorio   is '(nn)            - Somatório';
comment on column sotech.crl_coluna.contador    is '(nn)            - Flag do contador';

create or replace function sotech.crl_coluna_tratamento () returns trigger as
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
    if new.version != (select sotech.crl_coluna.version from sotech.crl_coluna where sotech.crl_coluna.pkcoluna = new.pkcoluna) then
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
    select into v_registros coalesce((select sotech.crl_coluna.pkcoluna from sotech.crl_coluna where sotech.crl_coluna.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.crl_coluna.pkcoluna <> new.pkcoluna else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.crl_coluna » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkcoluna::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.crl_coluna_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_crl_coluna';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkcoluna else new.pkcoluna end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkrelatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkrelatorio',           case when tg_op = 'INSERT' then '' else old.fkrelatorio::text                                          end, case when tg_op = 'DELETE' then '' else new.fkrelatorio::text                                               end);
  -- fktipodado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipodado',            case when tg_op = 'INSERT' then '' else old.fktipodado::text                                           end, case when tg_op = 'DELETE' then '' else new.fktipodado::text                                                end);
  -- indice
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'indice',                case when tg_op = 'INSERT' then '' else old.indice::text                                               end, case when tg_op = 'DELETE' then '' else new.indice::text                                                    end);
  -- ordem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ordem',                 case when tg_op = 'INSERT' then '' else old.ordem::text                                                end, case when tg_op = 'DELETE' then '' else new.ordem::text                                                     end);
  -- coluna
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'coluna',                case when tg_op = 'INSERT' then '' else old.coluna                                                     end, case when tg_op = 'DELETE' then '' else new.coluna                                                          end);
  -- alinhamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'alinhamento',           case when tg_op = 'INSERT' then '' else old.alinhamento                                                end, case when tg_op = 'DELETE' then '' else new.alinhamento                                                     end);
  -- somatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'somatorio',             case when tg_op = 'INSERT' then '' else old.somatorio                                                  end, case when tg_op = 'DELETE' then '' else new.somatorio                                                       end);
  -- contador
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'contador',              case when tg_op = 'INSERT' then '' else case when old.contador = true then 'S' else 'N' end            end, case when tg_op = 'DELETE' then '' else case when new.contador = true then 'S' else 'N' end                 end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');