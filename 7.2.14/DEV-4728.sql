-- Criação da tabela sotech.ate_hemocentro (imagem na conversa)

select sotech.sys_create_table      ('sotech',  'ate_hemocentro',  'pkhemocentro',   'integer');

select sotech.sys_create_field      ('sotech',  'ate_hemocentro',  'bolsa',             'text',         null,   null,                      false,  '()              - Descrição da bolsa');
select sotech.sys_create_field      ('sotech',  'ate_hemocentro',  'numeroconector',    'text',         null,   null,                      false,  '(idx)           - Número conector');
select sotech.sys_create_field      ('sotech',  'ate_hemocentro',  'datainclusao',      'timestamp',    null,   null,                      true,   '(nn)            - Data da inclusão');
select sotech.sys_create_field      ('sotech',  'ate_hemocentro',  'tipodoacao',        'text',         null,   null,                      false,  '()              - Tipo de doação');
select sotech.sys_create_field      ('sotech',  'ate_hemocentro',  'fkatendimento',     'integer',      null,   null,                      true,   '(fk | idx | nn) - Referência com a tabela sotech.ate_atendimento');
select sotech.sys_create_fk         ('sotech',  'ate_hemocentro',  'fkatendimento',     'sotech',   'ate_atendimento',  'pkatendimento',       false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_hemocentro',  'fkatendimento',     'sotech_ate_hemocentro_idx_fkatendimento');
select sotech.sys_create_idx        ('sotech',  'ate_hemocentro',  'numeroconector',    'sotech_ate_hemocentro_idx_numeroconector');

select sotech.sys_create_audit_table('sotech',  'ate_hemocentro');
select sotech.sys_create_triggers   ('sotech',  'ate_hemocentro',  'pkhemocentro',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_hemocentro',  'pkhemocentro',  'tratamento');

create or replace function sotech.ate_hemocentro_tratamento () returns trigger as
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
    if new.version != (select sotech.ate_hemocentro.version from sotech.ate_hemocentro where sotech.ate_hemocentro.pkhemocentro = new.pkhemocentro) then
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
    select into v_registros coalesce((select sotech.ate_hemocentro.pkhemocentro from sotech.ate_hemocentro where sotech.ate_hemocentro.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_hemocentro.pkhemocentro <> new.pkhemocentro else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.ate_hemocentro » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkhemocentro::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_hemocentro_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_hemocentro';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkhemocentro else new.pkhemocentro end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                                       end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                          end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- bolsa
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'bolsa',                       case when tg_op = 'INSERT' then '' else old.bolsa                                                               end, case when tg_op = 'DELETE' then '' else new.bolsa                                                                    end);
  -- numeroconector
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'numeroconector',              case when tg_op = 'INSERT' then '' else old.numeroconector                                                      end, case when tg_op = 'DELETE' then '' else new.numeroconector                                                           end);
  -- datainclusao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datainclusao',                case when tg_op = 'INSERT' then '' else old.datainclusao::text                                                  end, case when tg_op = 'DELETE' then '' else new.datainclusao::text                                                       end);
  -- tipodoacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipodoacao',                  case when tg_op = 'INSERT' then '' else old.tipodoacao                                                          end, case when tg_op = 'DELETE' then '' else new.tipodoacao                                                               end);
  -- fkatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatendimento',               case when tg_op = 'INSERT' then '' else old.fkatendimento::text                                                 end, case when tg_op = 'DELETE' then '' else new.fkatendimento::text                                                      end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;





























select sotech.sys_create_field      ('sotech',  'ate_hemocentro',   'escolaridaderesponsavel',  'text',   null,   null,   false,   '()              - Descrição da escolaridade do responsável');

alter table sotech.ate_hemocentro alter column escolaridaderesponsavel set not null;

select sotech.sys_create_field      ('sotech',  'ate_hemocentro',   'fkescolaridade',  'integer',   null,   null,   false,   '(fk | idx)      - Relação com a tabela sotech.tbl_escolaridade');

select sotech.sys_create_fk         ('sotech',  'ate_hemocentro',  'fkescolaridade',   'sotech',   'tbl_escolaridade',  'pkescolaridade',   false,  true);

select sotech.sys_create_idx        ('sotech',  'ate_hemocentro',   'fkescolaridade',  'sotech_ate_hemocentro_idx_fkescolaridade');

























