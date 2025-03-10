---------------------------
-- task_id:    DEV-
-- version_db: 02.10.05.sql
---------------------------
-- Normatização tabela sotech.rel_tabela_produto

select sotech.sys_create_field('sotech',  'rel_tabela_produto',  'fkuser',  'integer',  null,           '0',                    true,   '(fk | idx | nn) - Referência com a tabela ish.sys_usuario');
select sotech.sys_create_field('sotech',  'rel_tabela_produto',  'version', 'integer',  null,           '0',                    true,   '(nn)            - Versionamento do registro');
select sotech.sys_create_field('sotech',  'rel_tabela_produto',  'ativo',   'boolean',  null,           'true',                 true,   '(idx | nn)      - Flag para desabilitar visualização do registro');
select sotech.sys_create_field('sotech',  'rel_tabela_produto',  'uuid',    'uuid',     null,           'uuid_generate_v4()',   true,   '(unq | nn)      - UUID do registro');
select sotech.sys_create_fk   ('sotech',  'rel_tabela_produto',  'fkuser',  'ish',      'sys_usuario',  'pkusuario',            false,  true);
select sotech.sys_create_idx  ('sotech',  'rel_tabela_produto',  'fkuser',  'sotech_rel_tabela_produto_idx_fkuser');
select sotech.sys_create_idx  ('sotech',  'rel_tabela_produto',  'ativo',   'sotech_rel_tabela_produto_idx_ativo');
select sotech.sys_create_unq  ('sotech',  'rel_tabela_produto',  'uuid',    'sotech_rel_tabela_produto_unq_uuid');
select sotech.sys_create_unq  ('sotech',  'rel_tabela_produto',  'codigo',  'sotech_rel_tabela_produto_unq_codigo');

comment on column sotech.rel_tabela_produto.pktabelaproduto is '(pk | nn)       - Chave primária da tabela';
comment on column sotech.rel_tabela_produto.fkuser          is '(fk | idx | nn) - Referência com a tabela ish.sys_usuario';
comment on column sotech.rel_tabela_produto.version         is '(nn)            - Versionamento do registro';
comment on column sotech.rel_tabela_produto.fktabela        is '(fk | idx | nn) - Referência com a tabela sotech.est_tabela';
comment on column sotech.rel_tabela_produto.fkproduto       is '(fk | idx | nn) - Referência com a tabela sotech.est_produto';
comment on column sotech.rel_tabela_produto.codigo          is '(unq | nn)      - Código';

update sotech.rel_tabela_produto set fkuser = 0  where sotech.rel_tabela_produto.fkuser  is null;
update sotech.rel_tabela_produto set version = 0 where sotech.rel_tabela_produto.version is null;

alter table sotech.rel_tabela_produto alter column fkuser  set default 0;
alter table sotech.rel_tabela_produto alter column fkuser  set not null;
alter table sotech.rel_tabela_produto alter column version set default 0;
alter table sotech.rel_tabela_produto alter column version set not null;

create or replace function sotech.rel_tabela_produto_tratamento () returns trigger as
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
    if new.version != (select sotech.rel_tabela_produto.version from sotech.rel_tabela_produto where sotech.rel_tabela_produto.pktabelaproduto = new.pktabelaproduto) then
      v_erro := sotech.sys_set_erro(v_erro, 'Alteração não permitida! «versão»');
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
    select into v_registros coalesce((select sotech.rel_tabela_produto.pktabelaproduto from sotech.rel_tabela_produto where sotech.rel_tabela_produto.uuid::text = new.uuid::text and case when tg_op = 'UPDATE' then sotech.rel_tabela_produto.pktabelaproduto <> new.pktabelaproduto else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'UUID já cadastrado! UUID:' || new.uuid::text || ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- unique
  if new.fktabela is not null and new.fkproduto is not null and length(trim(coalesce(new.codigo, ''))) > 0 then
    select into v_registros coalesce((select sotech.rel_tabela_produto.pktabelaproduto from sotech.rel_tabela_produto where sotech.rel_tabela_produto.fktabela = new.fktabela and sotech.rel_tabela_produto.fkproduto = new.fkproduto and lower(trim(unaccent(sotech.rel_tabela_produto.codigo))) = lower(trim(unaccent(new.codigo))) and case when tg_op = 'UPDATE' sotech.rel_tabela_produto.pktabelaproduto <> new.pktabelaproduto else 1 = 1 end order by 1 limit 1), -1) as codigo;
    if v_registros.codigo <> -1 then
      v_erro := sotech.sys_set_erro(v_erro, 'Registro já cadastrado! Tabela: ' || new.fktabela::text || ' Produto: ' || new.fkproduto::text || ' Código: ' || new.codigo ||  ' -> Cód:' || v_registros.codigo::text);
    end if;
  end if;
  -- final
  if length(trim(v_erro)) = 0 then
    new.version := new.version + 1;
    return case when TG_OP = 'DELETE' then old else new end;
  else
    v_erro := chr(13) || '« sotech.rel_tabela_produto » Usuário: (' || new.fkuser::text || ')' || case when tg_op = 'UPDATE' then ' ID:' || new.pktabelaproduto::text else '' end || chr(13) || v_erro;
    raise exception '%', v_erro;
    return null;
  end if;
end;
$$ language 'plpgsql' stable;

create or replace function sotech.rel_tabela_produto_auditoria () returns trigger as
$$
declare 
  v_retorno text;
  v_tabela  text;
  v_usuario integer;
  v_chave   bigint;
begin
  v_tabela  := 'sotech_rel_tabela_produto';
  v_usuario := case when TG_OP = 'DELETE' then old.fkuser else new.fkuser end;
  v_usuario := coalesce(v_usuario, (select ish.sys_usuario.pkusuario from ish.sys_usuario where ish.sys_usuario.login = 'sotech'));
  v_chave   := case when tg_op = 'DELETE' then old.pktabelaproduto else new.pktabelaproduto end;
  -- version
  v_retorno := sotech.sys_auditar(TG_OP, v_usuario, v_tabela, v_chave, 'version',                                                case when TG_OP = 'INSERT' then '' else old.version::text                                                            end, case when TG_OP = 'DELETE' then '' else new.version::text                                                            end);
  -- fktabela
  v_retorno := sotech.sys_auditar(TG_OP, v_usuario, v_tabela, v_chave, 'fktabela',                                               case when TG_OP = 'INSERT' then '' else old.fktabela::text                                                           end, case when TG_OP = 'DELETE' then '' else new.fktabela::text                                                           end);
  -- fkproduto
  v_retorno := sotech.sys_auditar(TG_OP, v_usuario, v_tabela, v_chave, 'fkproduto',                                              case when TG_OP = 'INSERT' then '' else old.fkproduto::text                                                          end, case when TG_OP = 'DELETE' then '' else new.fkproduto::text                                                          end);
  -- codigo
  v_retorno := sotech.sys_auditar(TG_OP, v_usuario, v_tabela, v_chave, 'codigo',                                                 case when TG_OP = 'INSERT' then '' else old.codigo::text                                                             end, case when TG_OP = 'DELETE' then '' else new.codigo::text                                                             end);
  v_retorno := null;
  v_tabela  := null;
  v_usuario := null;
  v_chave   := null;
  return null;
end;
$$ language 'plpgsql' stable;

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.05');