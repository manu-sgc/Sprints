---------------------------
-- task_id:    DEV-6286
-- version_db: 02.10.54.sql
---------------------------
-- Incluir parâmetro na tabela: ish.sys_parametro

insert into ish.sys_parametro(fkuser, parametro, descricao, padrao) values(0, 'ate_exibe_documentos anexados', '( S / N ) permite exibir documentos anexados, no atendimento.', 'N');

-- Save version config
insert into sotech.sys_config(config, valor) values ('versaodb', '02.10.54');
