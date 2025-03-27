-- Script para importar dados de arquivos CSV trimestrais para o PostgreSQL

-- Verifica se a tabela operadoras existe antes de prosseguir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'operadoras') THEN
        RAISE EXCEPTION 'A tabela operadoras não existe. Execute primeiro o script create_tables_cadop.sql e import_data_cadop.sql antes de prosseguir.';
    END IF;
END
$$;

-- Verifica se a tabela dados_contabeis_trimestral existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'dados_contabeis_trimestral') THEN
        RAISE EXCEPTION 'A tabela dados_contabeis_trimestral não existe. Execute primeiro o script create_tables_trimestral.sql antes de prosseguir.';
    END IF;
END
$$;

-- Cria uma tabela temporária para armazenar dados brutos do CSV
CREATE TEMPORARY TABLE temp_dados_contabeis (
    data VARCHAR(20),
    registro_ans VARCHAR(10),
    codigo_conta_contabil VARCHAR(20),
    descricao_conta VARCHAR(255),
    valor_saldo_inicial VARCHAR(50),
    valor_saldo_final VARCHAR(50)
);

-- Função para importar um arquivo CSV específico
CREATE OR REPLACE FUNCTION importar_dados_trimestrais(caminho_arquivo TEXT, trimestre TEXT, ano INTEGER)
RETURNS INTEGER AS $$
DECLARE
    contagem_linhas INTEGER := 0;
    contagem_inseridos INTEGER := 0;
BEGIN
    -- Limpa a tabela temporária
    TRUNCATE TABLE temp_dados_contabeis;
    
    -- Importa dados do arquivo CSV para a tabela temporária
    EXECUTE format('COPY temp_dados_contabeis FROM %L WITH (FORMAT csv, DELIMITER '';'', HEADER true, QUOTE ''"'', ENCODING ''UTF8'')', caminho_arquivo);
    
    -- Obtém o número de linhas da tabela temporária
    SELECT COUNT(*) INTO contagem_linhas FROM temp_dados_contabeis;
    
    -- Processa plano_contas primeiro (códigos de conta únicos)
    INSERT INTO plano_contas (codigo_conta_contabil, descricao_conta, nivel, tipo_conta)
    SELECT DISTINCT 
        codigo_conta_contabil,
        descricao_conta,
        -- Calcula o nível com base no comprimento do código ou segmentos
        CASE 
            WHEN LENGTH(TRIM(codigo_conta_contabil)) <= 2 THEN 1
            WHEN LENGTH(TRIM(codigo_conta_contabil)) <= 4 THEN 2
            WHEN LENGTH(TRIM(codigo_conta_contabil)) <= 6 THEN 3
            WHEN LENGTH(TRIM(codigo_conta_contabil)) <= 8 THEN 4
            ELSE 5
        END as nivel,
        -- Determina o tipo de conta com base no primeiro dígito
        CASE 
            WHEN LEFT(codigo_conta_contabil, 1) = '1' THEN 'Ativo'
            WHEN LEFT(codigo_conta_contabil, 1) = '2' THEN 'Passivo'
            WHEN LEFT(codigo_conta_contabil, 1) = '3' THEN 'Patrimônio Líquido'
            WHEN LEFT(codigo_conta_contabil, 1) = '4' THEN 'Receita'
            WHEN LEFT(codigo_conta_contabil, 1) = '5' THEN 'Despesa'
            ELSE 'Outro'
        END as tipo_conta
    FROM 
        temp_dados_contabeis
    ON CONFLICT (codigo_conta_contabil) DO NOTHING;
    
    -- Atualiza as relações pai-filho na plano_contas
    WITH hierarquia_contas AS (
        SELECT 
            p1.codigo_conta_contabil,
            (SELECT p2.codigo_conta_contabil 
             FROM plano_contas p2 
             WHERE p2.codigo_conta_contabil = LEFT(p1.codigo_conta_contabil, GREATEST(LENGTH(p1.codigo_conta_contabil) - 2, 1))
             AND p2.codigo_conta_contabil != p1.codigo_conta_contabil
             LIMIT 1) as codigo_pai
        FROM 
            plano_contas p1
        WHERE 
            p1.conta_pai IS NULL AND LENGTH(p1.codigo_conta_contabil) > 1
    )
    UPDATE plano_contas pc
    SET conta_pai = hc.codigo_pai
    FROM hierarquia_contas hc
    WHERE pc.codigo_conta_contabil = hc.codigo_conta_contabil
    AND hc.codigo_pai IS NOT NULL;
    
    -- Insere dados na tabela principal para operadoras que existem na tabela operadoras
    INSERT INTO dados_contabeis_trimestral (
        data_referencia,
        registro_ans,
        codigo_conta_contabil,
        descricao_conta,
        valor_saldo_inicial,
        valor_saldo_final,
        trimestre,
        ano
    )
    SELECT 
        -- Tenta converter a data usando diferentes formatos
        CASE
            WHEN TRIM(BOTH '"' FROM data) ~ '^\d{4}-\d{2}-\d{2}$' THEN
                TO_DATE(TRIM(BOTH '"' FROM data), 'YYYY-MM-DD')
            WHEN TRIM(BOTH '"' FROM data) ~ '^\d{2}/\d{2}/\d{4}$' THEN
                TO_DATE(TRIM(BOTH '"' FROM data), 'DD/MM/YYYY')
            ELSE
                NULL -- Se não conseguir converter, usa NULL
        END,
        TRIM(BOTH '"' FROM registro_ans),
        TRIM(BOTH '"' FROM codigo_conta_contabil),
        TRIM(BOTH '"' FROM descricao_conta),
        -- Convert comma to period for decimal numbers
        CAST(REPLACE(TRIM(BOTH '"' FROM valor_saldo_inicial), ',', '.') AS NUMERIC(15, 2)),
        CAST(REPLACE(TRIM(BOTH '"' FROM valor_saldo_final), ',', '.') AS NUMERIC(15, 2)),
        trimestre,
        ano
    FROM 
        temp_dados_contabeis
    WHERE
        -- Apenas insere dados para operadoras que existem na tabela operadoras
        EXISTS (SELECT 1 FROM operadoras o WHERE o.registro_ans = TRIM(BOTH '"' FROM temp_dados_contabeis.registro_ans));
    
    -- Obtém o número de linhas inseridas
    GET DIAGNOSTICS contagem_inseridos = ROW_COUNT;
    
    RAISE NOTICE 'Arquivo %, Linhas lidas: %, Linhas inseridas: %', caminho_arquivo, contagem_linhas, contagem_inseridos;
    
    RETURN contagem_inseridos;
END;
$$ LANGUAGE plpgsql;

-- Execute a função de importação para cada arquivo CSV trimestral
-- Nota: Os caminhos dos arquivos precisam ser ajustados com base na configuração do servidor
-- Exemplos de uso:

SELECT importar_dados_trimestrais('C:\teste3\teste3\1T2023.csv', '1T', 2023);
SELECT importar_dados_trimestrais('C:\teste3\teste3\2t2023.csv', '2T', 2023);
SELECT importar_dados_trimestrais('C:\teste3\teste3\3T2023.csv', '3T', 2023);
SELECT importar_dados_trimestrais('C:\teste3\teste3\4T2023.csv', '4T', 2023);
SELECT importar_dados_trimestrais('C:\teste3\teste3\1T2024.csv', '1T', 2024);
SELECT importar_dados_trimestrais('C:\teste3\teste3\2T2024.csv', '2T', 2024);
SELECT importar_dados_trimestrais('C:\teste3\teste3\3T2024.csv', '3T', 2024);
SELECT importar_dados_trimestrais('C:\teste3\teste3\4T2024.csv', '4T', 2024);

-- Após importar todos os dados, analise as tabelas para otimizar o desempenho das consultas
ANALYZE dados_contabeis_trimestral;
ANALYZE plano_contas; 