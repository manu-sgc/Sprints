---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------

-- Normatização tabela sotech.tbn_procedimento

select sotech.sys_create_field('sotech',  'tbn_procedimento',  'fkuser',   'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'tbn_procedimento',  'version',  'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'tbn_procedimento',  'ativo',    'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'tbn_procedimento',  'uuid',     'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'tbn_procedimento',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx  ('sotech',  'tbn_procedimento',  'fkuser',   'sotech_tbn_procedimento_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'tbn_procedimento',  'ativo',    'sotech_tbn_procedimento_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'tbn_procedimento',  'uuid',     'sotech_tbn_procedimento_unq_uuid');

comment on column sotech.tbn_procedimento.pkprocedimento     is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.tbn_procedimento.codprocedimento    is '(idx | nn)      - Código do procedimento';
comment on column sotech.tbn_procedimento.procedimento       is '(idx | nn)      - Nome do procedimento';
comment on column sotech.tbn_procedimento.fkformaorganizacao is '(fk | idx)      - Referência com a tabela sotech.tbn_formaorganizacao';
comment on column sotech.tbn_procedimento.complexidade       is '(nn)            - Complexidade dp procedimento';
comment on column sotech.tbn_procedimento.sexo               is '(nn)            - Sexo do paciente';
comment on column sotech.tbn_procedimento.quantidademax      is '(nn)            - Quantidade máxima do procedimento';
comment on column sotech.tbn_procedimento.diaspermanencia    is '(nn)            - Dias de permanênica';
comment on column sotech.tbn_procedimento.pontos             is '(nn)            - Pontos';
comment on column sotech.tbn_procedimento.idademin           is '(nn)            - Idade mínima';
comment on column sotech.tbn_procedimento.idademax           is '(nn)            - Idade máxima';
comment on column sotech.tbn_procedimento.valorsh            is '(nn)            - Valor sh';
comment on column sotech.tbn_procedimento.valorsa            is '(nn)            - Valor sa';
comment on column sotech.tbn_procedimento.valorsp            is '(idx | nn)      - Valor sp';
comment on column sotech.tbn_procedimento.fkfinanciamento    is '(fk | idx)      - Referência com a tabela sotech.tbn_financiamento';
comment on column sotech.tbn_procedimento.fkrubrica          is '(fk | idx)      - Referência com a tabela sotech.tbn_rubrica';
comment on column sotech.tbn_procedimento.competenciaini     is '(idx | nn)      - Competência inicial';
comment on column sotech.tbn_procedimento.competenciafim     is '(idx | nn)      - Competência final';
comment on column sotech.tbn_procedimento.tabela             is '()              - Tabela';
comment on column sotech.tbn_procedimento.operacional        is '()              - Operaciomal';
comment on column sotech.tbn_procedimento.fkatofaturamento   is '(fk | idx)      - Referência com a tabela sotech.tbl_atofaturamento';
comment on column sotech.tbn_procedimento.fkuser             is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.tbn_procedimento.version            is '(nn)            - Versionamento do registro';
comment on column sotech.tbn_procedimento.ativo              is '(idx | nn)      - Flag para desabilitar visualização do registro';
comment on column sotech.tbn_procedimento.uuid               is '(unq | nn)      - UUID do registro';

create or replace function sotech.tbn_procedimento_tratamento() returns trigger as
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
    if tg_op = 'UPDATE' then
      if new.version != (select sotech.tbn_procedimento.version from sotech.tbn_procedimento where sotech.tbn_procedimento.pkprocedimento = new.pkprocedimento) then
        v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «Versão»');
      end if;
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
    select into v_registros coalesce((select sotech.tbn_procedimento.pkprocedimento from sotech.tbn_procedimento where sotech.tbn_procedimento.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.tbn_procedimento.pkprocedimento <> new.pkprocedimento else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo);
    end if;
  end if;
  -- codprocedimento
  if new.codprocedimento is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Cód. do procedimento não informado!');
  else
    if sotech.verificarinteiro(new.codprocedimento) = false then
      v_erro := sotech.sys_set_erro(v_erro, 'Cód. do procedimento inválido (caractere)!');
    else
      if length(trim(new.codprocedimento)) != 10 then
        v_erro := sotech.sys_set_erro(v_erro, 'Cód. do procedimento inválido (dígitos)!');
      end if;
    end if;
  end if;
  -- procedimento
  if new.procedimento is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Procedimento obrigatório!');
  else
    new.procedimento := sotech.maiusculo(new.procedimento);
  end if;
  -- sexo
  if new.sexo is null then
    v_erro := sotech.sys_set_erro(v_erro, 'Sexo obrigatório!');
  else
    new.sexo := sotech.maiusculo(new.sexo);
    if new.sexo not in ('F', 'I', 'M', 'N') then
      v_erro := sotech.sys_set_erro(v_erro, 'Sexo inválido (caractere)!');
    end if;
  end if;
  -- final
  v_registros := null;
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.tbn_procedimento » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkprocedimento::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.tbn_procedimento_auditoria() returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_tbn_procedimento';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech'));
  v_chave   := case when tg_op = 'DELETE' then old.pkprocedimento else new.pkprocedimento end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                                                 case when tg_op = 'INSERT' then '' else old.version::text                                                             end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                                                   case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                              end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                                                    case when tg_op = 'INSERT' then '' else old.uuid::text                                                                end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- codprocedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codprocedimento',                                         case when tg_op = 'INSERT' then '' else old.codprocedimento                                                           end, case when tg_op = 'DELETE' then '' else new.codprocedimento                                                          end);
  -- procedimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'procedimento',                                            case when tg_op = 'INSERT' then '' else old.procedimento                                                              end, case when tg_op = 'DELETE' then '' else new.procedimento                                                             end);
  -- fkformaorganizacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkformaorganizacao',                                      case when tg_op = 'INSERT' then '' else old.fkformaorganizacao::text                                                  end, case when tg_op = 'DELETE' then '' else new.fkformaorganizacao::text                                                 end);
  -- fkfinanciamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkfinanciamento',                                         case when tg_op = 'INSERT' then '' else old.fkfinanciamento::text                                                     end, case when tg_op = 'DELETE' then '' else new.fkfinanciamento::text                                                    end);
  -- fkrubrica
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkrubrica',                                               case when tg_op = 'INSERT' then '' else old.fkrubrica::text                                                           end, case when tg_op = 'DELETE' then '' else new.fkrubrica::text                                                          end);
  -- fkatofaturamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatofaturamento',                                        case when tg_op = 'INSERT' then '' else old.fkatofaturamento::text                                                    end, case when tg_op = 'DELETE' then '' else new.fkatofaturamento::text                                                   end);
  -- complexidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'complexidade',                                            case when tg_op = 'INSERT' then '' else old.complexidade                                                              end, case when tg_op = 'DELETE' then '' else new.complexidade                                                             end);
  -- sexo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'sexo',                                                    case when tg_op = 'INSERT' then '' else old.sexo                                                                      end, case when tg_op = 'DELETE' then '' else new.sexo                                                                     end);
  -- quantidademax
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'quantidademax',                                           case when tg_op = 'INSERT' then '' else old.quantidademax::text                                                       end, case when tg_op = 'DELETE' then '' else new.quantidademax::text                                                      end);
  -- diaspermanencia
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'diaspermanencia',                                         case when tg_op = 'INSERT' then '' else old.diaspermanencia::text                                                     end, case when tg_op = 'DELETE' then '' else new.diaspermanencia::text                                                    end);
  -- pontos
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'pontos',                                                  case when tg_op = 'INSERT' then '' else old.pontos::text                                                              end, case when tg_op = 'DELETE' then '' else new.pontos::text                                                             end);
  -- idademin
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'idademin',                                                case when tg_op = 'INSERT' then '' else old.idademin::text                                                            end, case when tg_op = 'DELETE' then '' else new.idademin::text                                                           end);
  -- idademax
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'idademax',                                                case when tg_op = 'INSERT' then '' else old.idademax::text                                                            end, case when tg_op = 'DELETE' then '' else new.idademax::text                                                           end);
  -- valorsh
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'valorsh',                                                 case when tg_op = 'INSERT' then '' else sotech.formatar_valor(old.valorsh, 2)                                         end, case when tg_op = 'DELETE' then '' else sotech.formatar_valor(new.valorsh, 2)                                        end);
  -- valorsa
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'valorsa',                                                 case when tg_op = 'INSERT' then '' else sotech.formatar_valor(old.valorsa, 2)                                         end, case when tg_op = 'DELETE' then '' else sotech.formatar_valor(new.valorsa, 2)                                        end);
  -- valorsp
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'valorsp',                                                 case when tg_op = 'INSERT' then '' else sotech.formatar_valor(old.valorsp, 2)                                         end, case when tg_op = 'DELETE' then '' else sotech.formatar_valor(new.valorsp, 2)                                        end);
  -- competenciaini
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciaini',                                          case when tg_op = 'INSERT' then '' else old.competenciaini                                                            end, case when tg_op = 'DELETE' then '' else new.competenciaini                                                           end);
  -- competenciafim
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'competenciafim',                                          case when tg_op = 'INSERT' then '' else old.competenciafim                                                            end, case when tg_op = 'DELETE' then '' else new.competenciafim                                                           end);
  -- tabela
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tabela',                                                  case when tg_op = 'INSERT' then '' else old.tabela                                                                    end, case when tg_op = 'DELETE' then '' else new.tabela                                                                   end);
  -- operacional
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'operacional',                                             case when tg_op = 'INSERT' then '' else old.operacional::text                                                         end, case when tg_op = 'DELETE' then '' else new.operacional::text                                                        end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');