---------------------------
-- task_id:    DEV-5682
-- version_db: 02.10.04.sql
---------------------------
-- Incluir na tabela ish.sys_perfil o perfil ATE_HIPERDIA_PONTUACAO

insert into ish.sys_perfil(fkuser, fksistema, perfil) values (0, (select ish.sys_sistema.pksistema from ish.sys_sistema where lower(trim(unaccent(ish.sys_sistema.sistema))) = lower(trim(unaccent('IS')))), 'ATE_HIPERDIA_PONTUACAO');

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.04');