-- Script para criar as tabelas para os dados trimestrais

-- Verifica se a tabela operadoras existe antes de prosseguir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'operadoras') THEN
        RAISE EXCEPTION 'A tabela operadoras não existe. Execute primeiro o script create_tables_cadop.sql e import_data_cadop.sql antes de prosseguir.';
    END IF;
END
$$;

-- Dropa a tabela se ela existir
DROP TABLE IF EXISTS dados_contabeis_trimestral;

-- Cria a tabela para os dados contábeis trimestrais
CREATE TABLE dados_contabeis_trimestral (
    id SERIAL PRIMARY KEY,
    data_referencia DATE NOT NULL,
    registro_ans VARCHAR(10) NOT NULL,
    codigo_conta_contabil VARCHAR(20) NOT NULL,
    descricao_conta VARCHAR(255) NOT NULL,
    valor_saldo_inicial NUMERIC(15, 2) NOT NULL,
    valor_saldo_final NUMERIC(15, 2) NOT NULL,
    trimestre VARCHAR(10) NOT NULL,
    ano INTEGER NOT NULL,
    -- Referencia a tabela operadoras
    CONSTRAINT fk_operadora FOREIGN KEY (registro_ans) 
        REFERENCES operadoras (registro_ans) ON DELETE CASCADE
);

-- Cria índices para melhorar o desempenho das consultas
CREATE INDEX idx_dados_contabeis_registro_ans ON dados_contabeis_trimestral(registro_ans);
CREATE INDEX idx_dados_contabeis_data ON dados_contabeis_trimestral(data_referencia);
CREATE INDEX idx_dados_contabeis_conta ON dados_contabeis_trimestral(codigo_conta_contabil);
CREATE INDEX idx_dados_contabeis_trimestre_ano ON dados_contabeis_trimestral(trimestre, ano);

-- Cria a tabela para os códigos de conta (Plano de Contas)
CREATE TABLE plano_contas (
    codigo_conta_contabil VARCHAR(20) PRIMARY KEY,
    descricao_conta VARCHAR(255) NOT NULL,
    conta_pai VARCHAR(20),
    nivel INTEGER NOT NULL,
    tipo_conta VARCHAR(50), -- Ativo, Passivo, Patrimônio Líquido, Receita, Despesa
    CONSTRAINT fk_conta_pai FOREIGN KEY (conta_pai) 
        REFERENCES plano_contas (codigo_conta_contabil) ON DELETE CASCADE
);

-- Cria índices para melhorar o desempenho das consultas
CREATE INDEX idx_plano_contas_pai ON plano_contas(conta_pai);

-- Cria uma view para analisar a posição financeira por operador
CREATE OR REPLACE VIEW posicao_financeira_operadoras AS
SELECT 
    o.registro_ans,
    o.razao_social,
    o.modalidade,
    d.trimestre,
    d.ano,
    SUM(CASE WHEN LEFT(d.codigo_conta_contabil, 1) = '1' THEN d.valor_saldo_final ELSE 0 END) as total_ativos,
    SUM(CASE WHEN LEFT(d.codigo_conta_contabil, 1) = '2' THEN d.valor_saldo_final ELSE 0 END) as total_passivos,
    SUM(CASE WHEN LEFT(d.codigo_conta_contabil, 1) = '3' THEN d.valor_saldo_final ELSE 0 END) as patrimonio_liquido,
    SUM(CASE WHEN LEFT(d.codigo_conta_contabil, 1) = '3' THEN d.valor_saldo_final ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN LEFT(d.codigo_conta_contabil, 1) = '2' THEN d.valor_saldo_final ELSE 0 END), 0) as indice_solvencia
FROM 
    dados_contabeis_trimestral d
JOIN 
    operadoras o ON d.registro_ans = o.registro_ans
GROUP BY 
    o.registro_ans, o.razao_social, o.modalidade, d.trimestre, d.ano;

-- Comentários para melhor documentação
COMMENT ON TABLE dados_contabeis_trimestral IS 'Armazena dados contábeis trimestrais das operadoras de saúde';
COMMENT ON COLUMN dados_contabeis_trimestral.registro_ans IS 'Número de registro na ANS - chave estrangeira para a tabela operadoras';
COMMENT ON COLUMN dados_contabeis_trimestral.codigo_conta_contabil IS 'Código do plano de contas';
COMMENT ON COLUMN dados_contabeis_trimestral.valor_saldo_inicial IS 'Valor do saldo inicial';
COMMENT ON COLUMN dados_contabeis_trimestral.valor_saldo_final IS 'Valor do saldo final';
COMMENT ON COLUMN dados_contabeis_trimestral.trimestre IS 'Referência do trimestre (1T, 2T, 3T, 4T)';
COMMENT ON COLUMN dados_contabeis_trimestral.ano IS 'Referência do ano';

COMMENT ON TABLE plano_contas IS 'Estrutura do plano de contas';
COMMENT ON COLUMN plano_contas.codigo_conta_contabil IS 'Código da conta - chave primária';
COMMENT ON COLUMN plano_contas.conta_pai IS 'Código da conta pai - referência a si mesma para criar a hierarquia';
COMMENT ON COLUMN plano_contas.nivel IS 'Nível da hierarquia da conta'; 