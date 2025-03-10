---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.esus_domicilio

select sotech.sys_create_field('sotech',  'esus_domicilio',  'fkuser',   		          'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'esus_domicilio',  'version',  		          'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'esus_domicilio',  'ativo',    		          'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'esus_domicilio',  'uuid',     		          'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'esus_domicilio',  'fkuser',   		          'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx  ('sotech',  'esus_domicilio',  'fkuser',   		          'sotech_esus_domicilio_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'esus_domicilio',  'ativo',    		          'sotech_esus_domicilio_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'esus_domicilio',  'uuid',     		          'sotech_esus_domicilio_unq_uuid');
select sotech.sys_create_fk   ('sotech',  'esus_domicilio',  'fkmicroarea',   		    'sotech',   'esus_microarea', 'pkmicroarea',        false,  true);
select sotech.sys_create_idx  ('sotech',  'esus_domicilio',  'fkescoamentosanitario', 'sotech_esus_domicilio_idx_fkescoamentosanitario');

comment on column sotech.esus_domicilio.pkdomicilio            is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.esus_domicilio.fkuser                 is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.esus_domicilio.version                is '(idx | nn)      - Versionamento do registro';
comment on column sotech.esus_domicilio.cep                    is '(idx | nn)      - Cep da residência';
comment on column sotech.esus_domicilio.fklogradouro           is '(fk | idx | nn) - Referência com a tabela sotech.tbn_logradouro';
comment on column sotech.esus_domicilio.logradouro             is '(idx | nn)      - Logradouro da residência';
comment on column sotech.esus_domicilio.numero                 is '(idx)           - Número da residência';
comment on column sotech.esus_domicilio.complemento            is '(idx)           - Complemento da residência';
comment on column sotech.esus_domicilio.pontoreferencia        is '()              - Ponto de referência da residência';
comment on column sotech.esus_domicilio.fkuf                   is '(fk | idx | nn) - Referência com a tabela sotech.tbn_uf';
comment on column sotech.esus_domicilio.fkcidade               is '(fk | idx | nn) - Referência com a tabela sotech.tbn_municipio';
comment on column sotech.esus_domicilio.fkbairro               is '(fk | idx | nn) - Referência com a tabela sotech.tbn_bairro';
comment on column sotech.esus_domicilio.fkmicroarea            is '(fk | idx)      - Referência com a tabela sotech.esus_microarea';
comment on column sotech.esus_domicilio.datacadastro           is '(idx)           - Data de cadastro';
comment on column sotech.esus_domicilio.fktipoimovel           is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fksituacaomoradia      is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fklocalizacao          is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fktipodomicilio        is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fkpossedaterra         is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fktipoacessodomicilio  is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.numerocomodos          is '()              - Número de comodos da residência';
comment on column sotech.esus_domicilio.disponibilidadeenergia is '(idx)           - Flag se há disponibilidade de energia';
comment on column sotech.esus_domicilio.disponibilidadeagua    is '(idx)           - Flag se há disponibilidade de água';
comment on column sotech.esus_domicilio.fkaguaabastecida       is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fkaguaconsumida        is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fkmaterialconstrucao   is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fkescoamentosanitario  is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.fkdestinolixo          is '(fk | idx | nn) - Referência com a tabela sotech.esus_tabela';
comment on column sotech.esus_domicilio.latitude               is '()              - Latitude da residência';
comment on column sotech.esus_domicilio.longitude              is '()              - Longitude da residência';
comment on column sotech.esus_domicilio.fkprofissional         is '(fk | idx | nn) - Referência com a tabela sotech.cdg_interveniente';
comment on column sotech.esus_domicilio.termorecusa            is '(idx)           - Flag que indica o termo de recusa';
comment on column sotech.esus_domicilio.uuid                   is '(unq | nn)      - UUID do registro';
comment on column sotech.esus_domicilio.alterado               is '(idx)           - Flag que indica alteração';
comment on column sotech.esus_domicilio.uuidoriginal           is '(idx)           - UUID original do registro';
comment on column sotech.esus_domicilio.dataalteracao          is '()              - Data de alteração';
comment on column sotech.esus_domicilio.idtablet               is '(idx)           - Identificação do tablet';
comment on column sotech.esus_domicilio.foradearea             is '(idx)           - Flag que indica se é fora de área';
comment on column sotech.esus_domicilio.esusenviado            is '()              - Flag para o esus enviado';
comment on column sotech.esus_domicilio.codmicroarea           is '(idx)           - Código microarea';
comment on column sotech.esus_domicilio.uuid_esus              is '(idx)           - UUID esus do registro';
comment on column sotech.esus_domicilio.ine                    is '(idx)           - INE';

update sotech.esus_domicilio set fkuser                 = 0                  where sotech.esus_domicilio.fkuser                 is null;
update sotech.esus_domicilio set version                = 0                  where sotech.esus_domicilio.version                is null;
update sotech.esus_domicilio set numero                 = 'SN'               where sotech.esus_domicilio.numero                 is null;
update sotech.esus_domicilio set disponibilidadeenergia = false              where sotech.esus_domicilio.disponibilidadeenergia is null;
update sotech.esus_domicilio set disponibilidadeagua    = false              where sotech.esus_domicilio.disponibilidadeagua    is null;
update sotech.esus_domicilio set termorecusa            = false              where sotech.esus_domicilio.termorecusa            is null;
update sotech.esus_domicilio set uuid                   = uuid_generate_v4() where sotech.esus_domicilio.uuid                   is null;
update sotech.esus_domicilio set alterado               = false              where sotech.esus_domicilio.alterado               is null;
update sotech.esus_domicilio set dataalteracao          = now()              where sotech.esus_domicilio.dataalteracao          is null;
update sotech.esus_domicilio set foradearea             = false              where sotech.esus_domicilio.foradearea             is null;
update sotech.esus_domicilio set esusenviado            = false              where sotech.esus_domicilio.esusenviado            is null;

alter table sotech.esus_domicilio alter column fkuser                 set default 0;
alter table sotech.esus_domicilio alter column fkuser                 set not null;
alter table sotech.esus_domicilio alter column version                set default 0;
alter table sotech.esus_domicilio alter column version                set not null;
alter table sotech.esus_domicilio alter column cep                    set not null;
alter table sotech.esus_domicilio alter column fklogradouro           set not null;
alter table sotech.esus_domicilio alter column logradouro             set not null;
alter table sotech.esus_domicilio alter column numero                 set default 'SN';
alter table sotech.esus_domicilio alter column fkuf                   set not null;
alter table sotech.esus_domicilio alter column fkcidade               set not null;
alter table sotech.esus_domicilio alter column fkbairro               set not null;
alter table sotech.esus_domicilio alter column fktipoimovel           set not null;
alter table sotech.esus_domicilio alter column fksituacaomoradia      set not null;
alter table sotech.esus_domicilio alter column fklocalizacao          set not null;
alter table sotech.esus_domicilio alter column fktipodomicilio        set not null;
alter table sotech.esus_domicilio alter column fkpossedaterra         set not null;
alter table sotech.esus_domicilio alter column fktipoacessodomicilio  set not null;
alter table sotech.esus_domicilio alter column disponibilidadeenergia set default false;
alter table sotech.esus_domicilio alter column disponibilidadeagua    set default false;
alter table sotech.esus_domicilio alter column fkaguaabastecida       set not null;
alter table sotech.esus_domicilio alter column fkaguaconsumida        set not null;
alter table sotech.esus_domicilio alter column fkmaterialconstrucao   set not null;
alter table sotech.esus_domicilio alter column fkescoamentosanitario  set not null;
alter table sotech.esus_domicilio alter column fkdestinolixo          set not null;
alter table sotech.esus_domicilio alter column fkprofissional         set not null;
alter table sotech.esus_domicilio alter column termorecusa            set default false;
alter table sotech.esus_domicilio alter column uuid                   set default uuid_generate_v4();
alter table sotech.esus_domicilio alter column uuid                   set not null;
alter table sotech.esus_domicilio alter column alterado               set default false;
alter table sotech.esus_domicilio alter column dataalteracao          set default now();
alter table sotech.esus_domicilio alter column foradearea             set default false;
alter table sotech.esus_domicilio alter column esusenviado            set default false;

create or replace function sotech.esus_domicilio_tratamento () returns trigger as
$$
declare
  v_registros record;
  v_erro      text;
  v_alterado  boolean;
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
    if new.version != (select sotech.esus_domicilio.version from sotech.esus_domicilio where sotech.esus_domicilio.pkdomicilio = new.pkdomicilio) then
      v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «Versão»');
    end if;
  end if;
  -- ativo
  if new.ativo is null then
    new.ativo := true;
  end if;
  -- uuidoriginal / uuid
  if new.uuid is null or new.uuidoriginal is null then
    new.uuidoriginal := uuid_generate_v4()::text;
    new.uuid := new.uuidoriginal;
  end if;
  if new.uuid is not null then
    select into v_registros coalesce((select sotech.esus_domicilio.pkdomicilio from sotech.esus_domicilio where sotech.esus_domicilio.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.esus_domicilio.pkdomicilio <> new.pkdomicilio else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;  
  -- codmicroarea
  if length(trim(coalesce(new.codmicroarea, ''))) > 0 then
    --if new.fkprofissional is not null then
    --  new.codmicroarea := (select sotech.esus_microarea.codmicroarea from sotech.esus_microarea where sotech.esus_microarea.fkagente = new.fkprofissional order by 1 desc limit 1);
    --end if;
  --else
    if sotech.verificarinteiro(new.codmicroarea) = false then
      v_erro := sotech.sys_set_erro(v_erro, 'Cód da micro-área inválida! (' || new.codmicroarea || ')');
    else
      if length(trim(coalesce(new.codmicroarea, ''))) > 2 then
        v_erro := sotech.sys_set_erro(v_erro, 'Cód da micro-área excede limite padrão! (' || new.codmicroarea || ')');
      else
        new.codmicroarea := lpad(new.codmicroarea, 2, '0');
      end if;
    end if;
  end if;
  v_alterado := sotech.sys_atualiza(TG_OP, v_alterado, case when TG_OP = 'INSERT' then true else coalesce(new.codmicroarea, '') <> coalesce(old.codmicroarea, '') end);
  -- final
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when tg_op = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.esus_domicilio » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkdomicilio::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.esus_domicilio_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'esus_domicilio';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech'));
  v_chave   := case when tg_op = 'DELETE' then old.pkdomicilio else new.pkdomicilio end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                                                 case when tg_op = 'INSERT' then '' else old.version::text                                                             end, case when tg_op = 'DELETE' then '' else new.version::text                                                            end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                                                   case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end                              end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                             end);
  -- alterado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'alterado',                                                case when tg_op = 'INSERT' then '' else case when old.alterado = true then 'S' else 'N' end                           end, case when tg_op = 'DELETE' then '' else case when new.alterado = true then 'S' else 'N' end                          end);
  -- termorecusa
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'termorecusa',                                             case when tg_op = 'INSERT' then '' else case when old.termorecusa = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.termorecusa = true then 'S' else 'N' end                       end);
  -- foradearea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'foradearea',                                              case when tg_op = 'INSERT' then '' else case when old.foradearea = true then 'S' else 'N' end                         end, case when tg_op = 'DELETE' then '' else case when new.foradearea = true then 'S' else 'N' end                        end);
  -- uuidoriginal
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuidoriginal',                                            case when tg_op = 'INSERT' then '' else old.uuidoriginal::text                                                        end, case when tg_op = 'DELETE' then '' else new.uuidoriginal::text                                                       end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                                                    case when tg_op = 'INSERT' then '' else old.uuid::text                                                                end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                               end);
  -- uuidesus
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuidesus',                                                case when tg_op = 'INSERT' then '' else old.uuidesus::text                                                            end, case when tg_op = 'DELETE' then '' else new.uuidesus::text                                                           end);
  -- ine
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ine',                                                     case when tg_op = 'INSERT' then '' else old.ine::text                                                                 end, case when tg_op = 'DELETE' then '' else new.ine::text                                                                end);
  -- idtablet
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'idtablet',                                                case when tg_op = 'INSERT' then '' else old.idtablet                                                                  end, case when tg_op = 'DELETE' then '' else new.idtablet                                                                 end);
  -- cep
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'cep',                                                     case when tg_op = 'INSERT' then '' else old.cep                                                                       end, case when tg_op = 'DELETE' then '' else new.cep                                                                      end);
  -- fklogradouro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fklogradouro',                                            case when tg_op = 'INSERT' then '' else old.fklogradouro::text                                                        end, case when tg_op = 'DELETE' then '' else new.fklogradouro::text                                                       end);
  -- logradouro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'logradouro',                                              case when tg_op = 'INSERT' then '' else old.logradouro                                                                end, case when tg_op = 'DELETE' then '' else new.logradouro                                                               end);
  -- numero
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'numero',                                                  case when tg_op = 'INSERT' then '' else old.numero                                                                    end, case when tg_op = 'DELETE' then '' else new.numero                                                                   end);
  -- complemento
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'complemento',                                             case when tg_op = 'INSERT' then '' else old.complemento                                                               end, case when tg_op = 'DELETE' then '' else new.complemento                                                              end);
  -- pontoreferencia
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'pontoreferencia',                                         case when tg_op = 'INSERT' then '' else old.pontoreferencia                                                           end, case when tg_op = 'DELETE' then '' else new.pontoreferencia                                                          end);
  -- fkuf
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkuf',                                                    case when tg_op = 'INSERT' then '' else old.fkuf::text                                                                end, case when tg_op = 'DELETE' then '' else new.fkuf::text                                                               end);
  -- fkcidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkcidade',                                                case when tg_op = 'INSERT' then '' else old.fkcidade::text                                                            end, case when tg_op = 'DELETE' then '' else new.fkcidade::text                                                           end);
  -- fkbairro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkbairro',                                                case when tg_op = 'INSERT' then '' else old.fkbairro::text                                                            end, case when tg_op = 'DELETE' then '' else new.fkbairro::text                                                           end);
  -- fkmicroarea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkmicroarea',                                             case when tg_op = 'INSERT' then '' else old.fkmicroarea::text                                                         end, case when tg_op = 'DELETE' then '' else new.fkmicroarea::text                                                        end);
  -- datacadastro
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datacadastro',                                            case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datacadastro::text)                              end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datacadastro::text)                             end);
  -- dataalteracao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'dataalteracao',                                           case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.dataalteracao::text)                             end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.dataalteracao::text)                            end);
  -- fktipoimovel
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipoimovel',                                            case when tg_op = 'INSERT' then '' else old.fktipoimovel::text                                                        end, case when tg_op = 'DELETE' then '' else new.fktipoimovel::text                                                       end);
  -- fksituacaomoradia
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fksituacaomoradia',                                       case when tg_op = 'INSERT' then '' else old.fksituacaomoradia::text                                                   end, case when tg_op = 'DELETE' then '' else new.fksituacaomoradia::text                                                  end);
  -- fklocalizacao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fklocalizacao',                                           case when tg_op = 'INSERT' then '' else old.fklocalizacao::text                                                       end, case when tg_op = 'DELETE' then '' else new.fklocalizacao::text                                                      end);
  -- fktipodomicilio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipodomicilio',                                         case when tg_op = 'INSERT' then '' else old.fktipodomicilio::text                                                     end, case when tg_op = 'DELETE' then '' else new.fktipodomicilio::text                                                    end);
  -- fkpossedaterra
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkpossedaterra',                                          case when tg_op = 'INSERT' then '' else old.fkpossedaterra::text                                                      end, case when tg_op = 'DELETE' then '' else new.fkpossedaterra::text                                                     end);
  -- fktipoacessodomicilio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fktipoacessodomicilio',                                   case when tg_op = 'INSERT' then '' else old.fktipoacessodomicilio::text                                               end, case when tg_op = 'DELETE' then '' else new.fktipoacessodomicilio::text                                              end);
  -- numerocomodos
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'numerocomodos',                                           case when tg_op = 'INSERT' then '' else old.numerocomodos::text                                                       end, case when tg_op = 'DELETE' then '' else new.numerocomodos::text                                                      end);
  -- disponibilidadeenergia
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'disponibilidadeenergia',                                  case when tg_op = 'INSERT' then '' else case when old.disponibilidadeenergia = true then 'S' else 'N' end             end, case when tg_op = 'DELETE' then '' else case when new.disponibilidadeenergia = true then 'S' else 'N' end            end);
  -- disponibilidadeagua
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'disponibilidadeagua',                                     case when tg_op = 'INSERT' then '' else case when old.disponibilidadeagua = true then 'S' else 'N' end                end, case when tg_op = 'DELETE' then '' else case when new.disponibilidadeagua = true then 'S' else 'N' end               end);
  -- fkaguaabastecida
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkaguaabastecida',                                        case when tg_op = 'INSERT' then '' else old.fkaguaabastecida::text                                                    end, case when tg_op = 'DELETE' then '' else new.fkaguaabastecida::text                                                   end);
  -- fkaguaconsumida
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkaguaconsumida',                                         case when tg_op = 'INSERT' then '' else old.fkaguaconsumida::text                                                     end, case when tg_op = 'DELETE' then '' else new.fkaguaconsumida::text                                                    end);
  -- fkmaterialconstrucao
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkmaterialconstrucao',                                    case when tg_op = 'INSERT' then '' else old.fkmaterialconstrucao::text                                                end, case when tg_op = 'DELETE' then '' else new.fkmaterialconstrucao::text                                               end);
  -- fkescoamentosanitario
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkescoamentosanitario',                                   case when tg_op = 'INSERT' then '' else old.fkescoamentosanitario::text                                               end, case when tg_op = 'DELETE' then '' else new.fkescoamentosanitario::text                                              end);
  -- fkdestinolixo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkdestinolixo',                                           case when tg_op = 'INSERT' then '' else old.fkdestinolixo::text                                                       end, case when tg_op = 'DELETE' then '' else new.fkdestinolixo::text                                                      end);
  -- latitude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'latitude',                                                case when tg_op = 'INSERT' then '' else old.latitude                                                                  end, case when tg_op = 'DELETE' then '' else new.latitude                                                                 end);
  -- longitude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'longitude',                                               case when tg_op = 'INSERT' then '' else old.longitude                                                                 end, case when tg_op = 'DELETE' then '' else new.longitude                                                                end);
  -- fkprofissional
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprofissional',                                          case when tg_op = 'INSERT' then '' else old.fkprofissional::text                                                      end, case when tg_op = 'DELETE' then '' else new.fkprofissional::text                                                     end);
  -- esusenviado
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'esusenviado',                                             case when tg_op = 'INSERT' then '' else case when old.esusenviado = true then 'S' else 'N' end                        end, case when tg_op = 'DELETE' then '' else case when new.esusenviado = true then 'S' else 'N' end                       end);
  -- erro
  --v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'erro',                                                    case when tg_op = 'INSERT' then '' else old.erro                                                                      end, case when tg_op = 'DELETE' then '' else new.erro                                                                     end);
  -- codmicroarea
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'codmicroarea',                                            case when tg_op = 'INSERT' then '' else old.codmicroarea                                                              end, case when tg_op = 'DELETE' then '' else new.codmicroarea                                                             end);
  -- Atualizando endereço de indivíduos vinculados às famílias do domicílio:
  if tg_op = 'UPDATE' then
    if      coalesce(old.cep,           '') <> coalesce(new.cep,            '')
        or  coalesce(old.fklogradouro,   0) <> coalesce(new.fklogradouro,    0)
        or  coalesce(old.logradouro,    '') <> coalesce(new.logradouro,     '')
        or  coalesce(old.numero,        '') <> coalesce(new.numero,         '')
        or  coalesce(old.complemento,   '') <> coalesce(new.complemento,    '')
        or  coalesce(old.fkuf,           0) <> coalesce(new.fkuf,            0)
        or  coalesce(old.fkcidade,       0) <> coalesce(new.fkcidade,        0)
        or  coalesce(old.fkbairro,       0) <> coalesce(new.fkbairro,        0) then
      v_sql := '';
      v_sql := v_sql || 'update sotech.cdg_paciente set'                                                                                                      || chr(13);
      v_sql := v_sql || '  fkuser = ' || v_usuario::text || ','                                                                                               || chr(13);
      v_sql := v_sql || '  tratar = false,'                                                                                                                   || chr(13);
      v_sql := v_sql || '  fklogradouro = dados.fklogradouro,'                                                                                                || chr(13);
      v_sql := v_sql || '  endereco = dados.logradouro,'                                                                                                      || chr(13);
      v_sql := v_sql || '  numero = dados.numero,'                                                                                                            || chr(13);
      v_sql := v_sql || '  complemento = dados.complemento,'                                                                                                  || chr(13);
      v_sql := v_sql || '  fkuf = dados.fkuf,'                                                                                                                || chr(13);
      v_sql := v_sql || '  fkcidade = dados.fkcidade,'                                                                                                        || chr(13);
      v_sql := v_sql || '  fkbairro = dados.fkbairro'                                                                                                         || chr(13);
      v_sql := v_sql || 'from'                                                                                                                                || chr(13);
      v_sql := v_sql || '  ('                                                                                                                                 || chr(13);
      v_sql := v_sql || '    select'                                                                                                                          || chr(13);
      v_sql := v_sql || '      sotech.esus_familia_paciente.fkpaciente,'                                                                                      || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.fklogradouro,'                                                                                           || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.logradouro,'                                                                                             || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.numero,'                                                                                                 || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.complemento,'                                                                                            || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.fkuf,'                                                                                                   || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.fkcidade,'                                                                                               || chr(13);
      v_sql := v_sql || '      sotech.esus_domicilio.fkbairro'                                                                                                || chr(13);
      v_sql := v_sql || '    from'                                                                                                                            || chr(13);
      v_sql := v_sql || '                  sotech.esus_domicilio'                                                                                             || chr(13);
      v_sql := v_sql || '      inner join    sotech.esus_familia              on      sotech.esus_familia.fkdomicilio = sotech.esus_domicilio.pkdomicilio'    || chr(13);
      v_sql := v_sql || '      inner join      sotech.esus_familia_paciente   on      sotech.esus_familia_paciente.fkfamilia = sotech.esus_familia.pkfamilia' || chr(13);
      v_sql := v_sql || '    where'                                                                                                                           || chr(13);
      v_sql := v_sql || '      sotech.sotech.esus_domicilio.pkdomicilio = ' || v_chave::text                                                                  || chr(13);
      v_sql := v_sql || '  ) as dados'                                                                                                                        || chr(13);
      v_sql := v_sql || 'where'                                                                                                                               || chr(13);
      v_sql := v_sql || '  sotech.cdg_paciente.pkpaciente = dados.fkpaciente'                                                                                 || ';';
      v_sql := sotech.sys_executar_sql(v_sql);
    end if;
  end if;
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');