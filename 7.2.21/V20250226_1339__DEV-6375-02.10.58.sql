---------------------------
-- task_id:    DEV-6375
-- version_db: 02.10.58.sql
---------------------------
-- Normatização tabela sotech.ate_checkin

select sotech.sys_create_field      ('sotech',  'ate_checkin',  'fkuser',   'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field      ('sotech',  'ate_checkin',  'version',  'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field      ('sotech',  'ate_checkin',  'ativo',    'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field      ('sotech',  'ate_checkin',  'uuid',     'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk         ('sotech',  'ate_checkin',  'fkuser',   'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx        ('sotech',  'ate_checkin',  'fkuser',   'sotech_ate_checkin_idx_fkuser');
select sotech.sys_create_idx        ('sotech',  'ate_checkin',  'ativo',    'sotech_ate_checkin_idx_ativo');
select sotech.sys_create_unq        ('sotech',  'ate_checkin',  'uuid',     'sotech_ate_checkin_unq_uuid');
select sotech.sys_create_audit_table('sotech',  'ate_checkin');
select sotech.sys_create_triggers   ('sotech',  'ate_checkin',  'pkchekin',  'auditoria');
select sotech.sys_create_triggers   ('sotech',  'ate_checkin',  'pkchekin',  'tratamento');

alter table sotech.ate_checkin drop constraint ate_checkin_fk restrict;
alter table sotech.ate_checkin add constraint ate_checkin_fk foreign key (fkuser) references ish.sys_usuario(pkusuario) on delete restrict on update cascade not deferrable;

comment on column sotech.ate_checkin.pkchekin             is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.ate_checkin.fkunidadesaude       is '(fk | idx | nn) - Referência com a tabela sotech.cdg_unidadesaude';
comment on column sotech.ate_checkin.fkespecialidade      is '(fk | idx)      - Referência com a tabela sotech.tbn_especialidade';
comment on column sotech.ate_checkin.fkprofissional       is '(fk | idx | nn) - Referência com a tabela sotech.cdg_interveniente';
comment on column sotech.ate_checkin.fkconsultorio        is '(fk | idx | nn) - Referência com a tabela sotech.ate_consultorio';
comment on column sotech.ate_checkin.datachekin           is '(idx | nn)      - Data do Check-in do atendimento';
comment on column sotech.ate_checkin.fkturno              is '(fk | idx)      - Referência com a tabela sotech.ate_turnos';
comment on column sotech.ate_checkin.datachekout          is '(idx)           - Data do Check-out do atendimento';
comment on column sotech.ate_checkin.fkclassificacaorisco is '(fk | idx)      - Referência com a tabela sotech.ate_classificacaorisco';
comment on column sotech.ate_checkin.fkuser               is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.ate_checkin.todos                is '(nn)            - Flag que indica todos';

update sotech.ate_checkin set fkuser = 0 where sotech.ate_checkin.fkuser is null;

alter table sotech.ate_checkin alter column fkuser set default 0;
alter table sotech.ate_checkin alter column fkuser set not null;

create or replace function sotech.ate_checkin_tratamento () returns trigger as
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
    if new.version != (select sotech.ate_checkin.version from sotech.ate_checkin where sotech.ate_checkin.pkchekin = new.pkchekin) then
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
    select into v_registros coalesce((select sotech.ate_checkin.pkchekin from sotech.ate_checkin where sotech.ate_checkin.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.ate_checkin.pkchekin <> new.pkchekin else 1 = 1 end order by 1 limit 1), -1) as codigo;
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
    v_erro := chr(13) || '« sotech.ate_checkin » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pkchekin::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.ate_checkin_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_ate_checkin';
  v_usuario := case when tg_op = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where lower(ish.sys_usuario.login) = 'sotech' order by 1 limit 1));
  v_chave   := case when tg_op = 'DELETE' then old.pkchekin else new.pkchekin end;
  -- version
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'version',                     case when tg_op = 'INSERT' then '' else old.version::text                                              end, case when tg_op = 'DELETE' then '' else new.version::text                                                   end);
  -- ativo
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'ativo',                       case when tg_op = 'INSERT' then '' else case when old.ativo = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.ativo = true then 'S' else 'N' end                   	end);
  -- uuid
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'uuid',                        case when tg_op = 'INSERT' then '' else old.uuid::text                                                 end, case when tg_op = 'DELETE' then '' else new.uuid::text                                                      end);
  -- fkunidadesaude
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkunidadesaude',              case when tg_op = 'INSERT' then '' else old.fkunidadesaude::text                                       end, case when tg_op = 'DELETE' then '' else new.fkunidadesaude::text                                            end);
  -- fkespecialidade
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkespecialidade',             case when tg_op = 'INSERT' then '' else old.fkespecialidade::text                                      end, case when tg_op = 'DELETE' then '' else new.fkespecialidade::text                                           end);
  -- fkprofissional
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkprofissional',              case when tg_op = 'INSERT' then '' else old.fkprofissional::text                                       end, case when tg_op = 'DELETE' then '' else new.fkprofissional::text                                            end);
  -- fkconsultorio
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkconsultorio',               case when tg_op = 'INSERT' then '' else old.fkconsultorio::text                                        end, case when tg_op = 'DELETE' then '' else new.fkconsultorio::text                                             end);
  -- datachekin
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datachekin',                  case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datachekin::text)                 end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datachekin::text)                      end);
  -- fkturno
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkturno',                     case when tg_op = 'INSERT' then '' else old.fkturno::text                                              end, case when tg_op = 'DELETE' then '' else new.fkturno::text                                                   end);
  -- datachekout
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'datachekout',                 case when tg_op = 'INSERT' then '' else sotech.formatar_datahora(old.datachekout::text)                end, case when tg_op = 'DELETE' then '' else sotech.formatar_datahora(new.datachekout::text)                     end);
  -- fkclassificacaorisco
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'fkclassificacaorisco',        case when tg_op = 'INSERT' then '' else old.fkclassificacaorisco::text                                 end, case when tg_op = 'DELETE' then '' else new.fkclassificacaorisco::text                                      end);
  -- todos
  v_retorno := sotech.sys_auditar(tg_op, v_usuario, v_tabela, v_chave, 'todos',                       case when tg_op = 'INSERT' then '' else case when old.todos = true then 'S' else 'N' end               end, case when tg_op = 'DELETE' then '' else case when new.todos = true then 'S' else 'N' end                    end);
v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;


-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.58');