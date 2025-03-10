-- Alterar datainclusao para datainiciocolete na tabela sotech.ate_hemocentro
alter table sotech.ate_hemocentro rename column datainclusao to datainiciocoleta;

-- Inculir os campos volumecoletado, datafinalcoleta, status, observacao e fkprofissionalcoleta na tabela sotech.ate_hemocentro
select sotech.sys_create_field('sotech',  'ate_hemocentro',  'volumecoletado',        'text',       null,  null,  false,   '()              - Volume de sangue coletado');
select sotech.sys_create_field('sotech',  'ate_hemocentro',  'datafinalcoleta',       'timestamp',  null,  null,  false,   '(idx)           - Data final da coleta');
select sotech.sys_create_field('sotech',  'ate_hemocentro',  'status',                'text',       null,  null,  false,   '()              - Status da coleta');
select sotech.sys_create_field('sotech',  'ate_hemocentro',  'observacao',            'text',       null,  null,  false,   '()              - Observação sobre a coleta');
select sotech.sys_create_field('sotech',  'ate_hemocentro',  'fkprofissionalcoleta',  'integer',    null,  null,  false,   '(fk | idx)      - Referência com a tabela sotech.cdg_interveniente');

select sotech.sys_create_fk   ('sotech',  'ate_hemocentro',  'fkprofissionalcoleta',  'sotech',  'cdg_interveniente',  'pkinterveniente',  false,  true);
select sotech.sys_create_idx  ('sotech',  'ate_hemocentro',  'fkprofissionalcoleta',  'sotech_ate_hemocentro_idx_fkprofissionalcoleta');
select sotech.sys_create_idx  ('sotech',  'ate_hemocentro',  'datafinalcoleta',       'sotech_ate_hemocentro_idx_datafinalcoleta');

create or replace function sotech.ate_hemocentro_auditoria() returns trigger as
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
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                           case when tg_op = 'INSERT' then '' else old.version::text                                                  end, case when tg_op = 'DELETE' then '' else new.version::text                                                 end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                             case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                   end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                  end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                              case when tg_op = 'INSERT' then '' else old.uuid::text                                                     end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                    end);
  -- fkatendimento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkatendimento',                     case when tg_op = 'INSERT' then '' else old.fkatendimento::text                                            end, case when tg_op = 'DELETE' then '' else new.fkatendimento::text                                           end);
  -- bolsa
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'bolsa',                             case when tg_op = 'INSERT' then '' else old.bolsa                                                          end, case when tg_op = 'DELETE' then '' else new.bolsa                                                         end);
  -- numeroconector
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'numeroconector',                    case when tg_op = 'INSERT' then '' else old.numeroconector                                                 end, case when tg_op = 'DELETE' then '' else new.numeroconector                                                end);
  -- tipodoacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'tipodoacao',                        case when tg_op = 'INSERT' then '' else old.tipodoacao                                                     end, case when tg_op = 'DELETE' then '' else new.tipodoacao                                                    end);
  -- datainiciocoleta
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datainiciocoleta',                  case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datainiciocoleta::text)               end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datainiciocoleta::text)              end);
  -- volumecoletado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'volumecoletado',                    case when tg_op = 'INSERT' then '' else old.volumecoletado                                                 end, case when tg_op = 'DELETE' then '' else new.volumecoletado                                               end);
  -- datafinalcoleta
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datafinalcoleta',                   case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datafinalcoleta::text)                end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datafinalcoleta::text)               end);
  -- status
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'status',                            case when tg_op = 'INSERT' then '' else old.status                                                         end, case when tg_op = 'DELETE' then '' else new.status                                                        end);
  -- observacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'observacao',                        case when tg_op = 'INSERT' then '' else old.observacao                                                     end, case when tg_op = 'DELETE' then '' else new.observacao                                                    end);
  -- fkprofissionalcoleta
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprofissionalcoleta',              case when tg_op = 'INSERT' then '' else old.fkprofissionalcoleta::text                                     end, case when tg_op = 'DELETE' then '' else new.fkprofissionalcoleta::text                                    end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;