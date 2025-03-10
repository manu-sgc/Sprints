---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.ate_movimentacao_leito

drop trigger ate_movimentacao_leito_auditoria on sotech.ate_movimentacao_leito;
drop function sotech.ate_movimentacao_leito_auditoria();

select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'fkuser',  'integer',  null,           '0',                       true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'version', 'integer',  null,           '0',                       true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'ativo',   'boolean',  null,           'true',                    true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'ate_movimentacao_leito',  'uuid',    'uuid',     null,           'uuid_generate_v4()',      true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'ate_movimentacao_leito',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',               false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_movimentacao_leito',  'fkuser',  'sotech_ate_movimentacao_leito_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'ate_movimentacao_leito',  'ativo',   'sotech_ate_movimentacao_leito_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'ate_movimentacao_leito',  'uuid',    'sotech_ate_movimentacao_leito_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'ate_movimentacao_leito');
select sotech.sys_create_triggers   ('sotech',  'ate_movimentacao_leito',  'pkmovimentacaoleito',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_movimentacao_leito',  'pkmovimentacaoleito',  'tratamento');

comment on column sotech.ate_movimentacao_leito.pkmovimentacaoleito is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_movimentacao_leito.fkuser              is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.ate_movimentacao_leito.fkatendimento       is '(fk | idx | nn) - Referência com a tabela sotech.ate_atendimento';
comment on column sotech.ate_movimentacao_leito.fkpostoorigem       is '(fk | idx | nn) - Referência com a tabela sotech.cdg_posto';
comment on column sotech.ate_movimentacao_leito.fkleitoorigem       is '(fk | idx)      - Referência com a tabela sotech.cdg_leito';
comment on column sotech.ate_movimentacao_leito.fkpostodestino      is '(fk | idx)      - Referência com a tabela sotech.cdg_posto';
comment on column sotech.ate_movimentacao_leito.fkleitodestino      is '(fk | idx)      - Referência com a tabela sotech.cdg_leito';
comment on column sotech.ate_movimentacao_leito.tipo                is '(idx)           - Tipo da movimentação';
comment on column sotech.ate_movimentacao_leito.dataabertura        is '(idx | nn)      - Data de abertura';
comment on column sotech.ate_movimentacao_leito.datafechamento      is '(idx)           - Data de fechamento';
comment on column sotech.ate_movimentacao_leito.estado              is '(idx)           - Estado da movimentação - "A"- Aberta; "C" - Cancelada; "F" - Fechada';
comment on column sotech.ate_movimentacao_leito.uuid                is '(unq | nn)      - UUID do registro';
comment on column sotech.ate_movimentacao_leito.version             is '(nn)            - Versionamento do registro';

update sotech.ate_movimentacao_leito set fkuser = 0 where sotech.ate_movimentacao_leito.fkuser  is null;

alter table sotech.ate_movimentacao_leito alter column fkuser set default 0;
alter table sotech.ate_movimentacao_leito alter column fkuser set not null;

create or replace function sotech.ate_movimentacao_leito_tratamento () returns trigger as
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
    if new.version != (select sotech.ate_movimentacao_leito.version from sotech.ate_movimentacao_leito where sotech.ate_movimentacao_leito.pkmovimentacaoleito = new.pkmovimentacaoleito) then
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
    select into v_registros coalesce((select sotech.ate_movimentacao_leito.pkmovimentacaoleito from sotech.ate_movimentacao_leito where sotech.ate_movimentacao_leito.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_movimentacao_leito.pkmovimentacaoleito <> new.pkmovimentacaoleito else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.ate_movimentacao_leito » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkmovimentacaoleito::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_movimentacao_leito_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_movimentacao_leito';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkmovimentacaoleito else new.pkmovimentacaoleito end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',               case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                 case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                  case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatendimento',         case when tg_op = 'INSERT' then '' else old.fkatendimento::text                                        end, case when tg_op = 'DELETE' then '' else new.fkatendimento::text                                             end);
  -- fkpostoorigem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpostoorigem',         case when tg_op = 'INSERT' then '' else old.fkpostoorigem::text                                        end, case when tg_op = 'DELETE' then '' else new.fkpostoorigem::text                                             end);
  -- fkleitoorigem
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkleitoorigem',         case when tg_op = 'INSERT' then '' else old.fkleitoorigem::text                                        end, case when tg_op = 'DELETE' then '' else new.fkleitoorigem::text                                             end);
  -- fkpostodestino
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpostodestino',        case when tg_op = 'INSERT' then '' else old.fkpostodestino::text                                       end, case when tg_op = 'DELETE' then '' else new.fkpostodestino::text                                            end);
  -- fkleitodestino
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkleitodestino',        case when tg_op = 'INSERT' then '' else old.fkleitodestino::text                                       end, case when tg_op = 'DELETE' then '' else new.fkleitodestino::text                                            end);
  -- tipo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipo',                  case when tg_op = 'INSERT' then '' else old.tipo                                                       end, case when tg_op = 'DELETE' then '' else new.tipo                                                            end);
  -- dataabertura
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'dataabertura',          case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.dataabertura::text)               end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.dataabertura::text)                    end);
  -- datafechamento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datafechamento',        case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datafechamento::text)             end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datafechamento::text)                  end);
  -- estado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'estado',                case when tg_op = 'INSERT' then '' else old.estado                                                     end, case when tg_op = 'DELETE' then '' else new.estado                                                          end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');