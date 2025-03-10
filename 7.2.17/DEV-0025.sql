---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.crl_filtro

select sotech.sys_create_field      ('sotech',  'crl_filtro',  'fkuser',      'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'crl_filtro',  'version',     'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'crl_filtro',  'ativo',       'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'crl_filtro',  'uuid',        'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'crl_filtro',  'fkuser',      'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'crl_filtro',  'fkuser',      'sotech_crl_filtro_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'crl_filtro',  'ativo',       'sotech_crl_filtro_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'crl_filtro',  'uuid',        'sotech_crl_filtro_unq_uuid');
select sotech.sys_create_fk         ('sotech',  'crl_filtro',  'fkficha',     'sotech',   'crl_ficha',    'pkficha',              false,  true);
select sotech.sys_create_fk         ('sotech',  'crl_filtro',  'fketiqueta',  'sotech',   'crl_etiqueta', 'pketiqueta',           false,  true);
select sotech.sys_create_audit_table('sotech',  'crl_filtro');
select sotech.sys_create_triggers   ('sotech',  'crl_filtro',  'pkfiltro',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'crl_filtro',  'pkfiltro',  'tratamento');

comment on column sotech.crl_filtro.pkfiltro    is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.crl_filtro.fkrelatorio is '(fk | idx)      - Referência com a tabela sotech.crl_relatorio';
comment on column sotech.crl_filtro.fktipodado  is '(fk | idx | nn) - Referência com a tabela sotech.crl_tipodado';
comment on column sotech.crl_filtro.filtro      is '(idx | nn)      - Filtro aplicado';
comment on column sotech.crl_filtro.sql         is '(nn)            - SQL utilizado';
comment on column sotech.crl_filtro.tipo        is '(idx | nn)      - Tipo do filtro';
comment on column sotech.crl_filtro.tabela      is '()              - Nome da tabela';
comment on column sotech.crl_filtro.obrigatorio is '()              - Flag se é um filtro obrigatório';
comment on column sotech.crl_filtro.variavel    is '()              - Variável';
comment on column sotech.crl_filtro.fkficha     is '(fk | idx)      - Referência com a tabela sotech.crl_ficha';
comment on column sotech.crl_filtro.parametro   is '()              - Parâmetro';
comment on column sotech.crl_filtro.fketiqueta  is '(fk | idx)      - Referência com a tabela sotech.crl_etiqueta';

create or replace function sotech.crl_filtro_tratamento () returns trigger as
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
    if new.version != (select sotech.crl_filtro.version from sotech.crl_filtro where sotech.crl_filtro.pkfiltro = new.pkfiltro) then
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
    select into v_registros coalesce((select sotech.crl_filtro.pkfiltro from sotech.crl_filtro where sotech.crl_filtro.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.crl_filtro.pkfiltro <> new.pkfiltro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fkrelatorio is not null and new.fkficha is not null and new.fketiqueta is not null and length(trim(coalesce(new.filtro, ''))) > 0 then
    select into v_registros coalesce((select sotech.crl_filtro.pkfiltro from sotech.crl_filtro where sotech.crl_filtro.fkrelatorio = new.fkrelatorio and sotech.crl_filtro.fkficha = new.fkficha and sotech.crl_filtro.fketiqueta = new.fketiqueta and lower(trim(unaccent(sotech.crl_filtro.filtro))) = lower(trim(unaccent(new.filtro))) and case when tg_op = 'UPDATE' sotech.crl_filtro.pkfiltro <> new.pkfiltro else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Relatório: ' || new.fkrelatorio::text || ' Ficha: ' || new.fkficha::text || ' Etiqueta: ' || new.fketiqueta::text || ' Filtro: ' || new.filtro ||  ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.crl_filtro » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkfiltro::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.crl_filtro_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_crl_filtro';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkfiltro else new.pkfiltro end;
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
  -- filtro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'filtro',                case when tg_op = 'INSERT' then '' else old.filtro                                                     end, case when tg_op = 'DELETE' then '' else new.filtro                                                          end);
  -- sql
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'sql',                  	case when tg_op = 'INSERT' then '' else old.sql                                                        end, case when tg_op = 'DELETE' then '' else new.sql                                                             end);
  -- tipo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipo',                  case when tg_op = 'INSERT' then '' else old.tipo                                                       end, case when tg_op = 'DELETE' then '' else new.tipo                                                            end);
  -- tabela
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tabela',                case when tg_op = 'INSERT' then '' else old.tabela                                                     end, case when tg_op = 'DELETE' then '' else new.tabela                                                          end);
  -- obrigatorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'obrigatorio',           case when tg_op = 'INSERT' then '' else case when old.obrigatorio = true then 'S' else 'N' end         end, case when tg_op = 'DELETE' then '' else case when new.obrigatorio = true then 'S' else 'N' end              end);
  -- variavel
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'variavel',              case when tg_op = 'INSERT' then '' else old.variavel                                                   end, case when tg_op = 'DELETE' then '' else new.variavel                                                        end);
  -- fkficha
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkficha',               case when tg_op = 'INSERT' then '' else old.fkficha::text                                              end, case when tg_op = 'DELETE' then '' else new.fkficha::text                                                   end);
  -- parametro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'parametro',             case when tg_op = 'INSERT' then '' else old.parametro                                                  end, case when tg_op = 'DELETE' then '' else new.parametro                                                       end);
  -- fketiqueta
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fketiqueta',            case when tg_op = 'INSERT' then '' else old.fketiqueta::text                                           end, case when tg_op = 'DELETE' then '' else new.fketiqueta::text                                                end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');