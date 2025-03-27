-- Script para importar dados do Relatorio_cadop.csv para o PostgreSQL

-- Primeiro, preenche a tabela UF com os estados brasileiros
INSERT INTO uf (sigla, nome) VALUES
('AC', 'Acre'),
('AL', 'Alagoas'),
('AM', 'Amazonas'),
('AP', 'Amapá'),
('BA', 'Bahia'),
('CE', 'Ceará'),
('DF', 'Distrito Federal'),
('ES', 'Espírito Santo'),
('GO', 'Goiás'),
('MA', 'Maranhão'),
('MG', 'Minas Gerais'),
('MS', 'Mato Grosso do Sul'),
('MT', 'Mato Grosso'),
('PA', 'Pará'),
('PB', 'Paraíba'),
('PE', 'Pernambuco'),
('PI', 'Piauí'),
('PR', 'Paraná'),
('RJ', 'Rio de Janeiro'),
('RN', 'Rio Grande do Norte'),
('RO', 'Rondônia'),
('RR', 'Roraima'),
('RS', 'Rio Grande do Sul'),
('SC', 'Santa Catarina'),
('SE', 'Sergipe'),
('SP', 'São Paulo'),
('TO', 'Tocantins');

-- Popula a tabela regioes_comercializacao
-- Nota: Em um cenário real, você inseriria descrições reais para cada código de região
INSERT INTO regioes_comercializacao (codigo, descricao) VALUES
('1', 'Região 1'),
('2', 'Região 2'),
('3', 'Região 3'),
('4', 'Região 4'),
('5', 'Região 5'),
('6', 'Região 6');

-- Importa dados do arquivo CSV para a tabela temporária
-- Primeiro, cria uma tabela temporária que corresponde à estrutura do CSV
CREATE TEMPORARY TABLE temp_operadoras (
    registro_ans VARCHAR(10),
    cnpj VARCHAR(14),
    razao_social VARCHAR(255),
    nome_fantasia VARCHAR(255),
    modalidade VARCHAR(100),
    logradouro VARCHAR(255),
    numero VARCHAR(20),
    complemento VARCHAR(255),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    uf CHAR(2),
    cep VARCHAR(8),
    ddd VARCHAR(4),
    telefone VARCHAR(20),
    fax VARCHAR(20),
    endereco_eletronico VARCHAR(255),
    representante VARCHAR(255),
    cargo_representante VARCHAR(100),
    regiao_comercializacao VARCHAR(10),
    data_registro_ans VARCHAR(10)
);

-- Importa dados do CSV para a tabela temporária
-- Nota: O caminho para o arquivo CSV pode precisar ser atualizado com base na configuração do servidor
COPY temp_operadoras FROM 'C:\teste3\teste3\Relatorio_cadop.csv' 
WITH (FORMAT csv, DELIMITER ';', HEADER true, QUOTE '"', ENCODING 'UTF8');

-- Limpa os dados e insere na tabela principal operadoras
INSERT INTO operadoras (
    registro_ans, cnpj, razao_social, nome_fantasia, modalidade,
    logradouro, numero, complemento, bairro, cidade, uf, cep,
    ddd, telefone, fax, endereco_eletronico, representante,
    cargo_representante, regiao_comercializacao, data_registro_ans
)
SELECT 
    TRIM(BOTH '"' FROM registro_ans),
    TRIM(BOTH '"' FROM REPLACE(cnpj, '-', '')), -- Remove aspas e hífens do CNPJ
    TRIM(BOTH '"' FROM razao_social),
    CASE WHEN nome_fantasia = '""' THEN NULL ELSE TRIM(BOTH '"' FROM nome_fantasia) END,
    TRIM(BOTH '"' FROM modalidade),
    TRIM(BOTH '"' FROM logradouro),
    TRIM(BOTH '"' FROM numero),
    CASE WHEN complemento = '""' THEN NULL ELSE TRIM(BOTH '"' FROM complemento) END,
    CASE WHEN bairro = '""' THEN NULL ELSE TRIM(BOTH '"' FROM bairro) END,
    TRIM(BOTH '"' FROM cidade),
    TRIM(BOTH '"' FROM uf),
    REPLACE(TRIM(BOTH '"' FROM cep), '-', ''), -- Remove hífens do CEP
    CASE WHEN ddd = '""' THEN NULL ELSE TRIM(BOTH '"' FROM ddd) END,
    CASE WHEN telefone = '""' THEN NULL ELSE TRIM(BOTH '"' FROM telefone) END,
    CASE WHEN fax = '""' THEN NULL ELSE TRIM(BOTH '"' FROM fax) END,
    CASE WHEN endereco_eletronico = '""' THEN NULL ELSE TRIM(BOTH '"' FROM endereco_eletronico) END,
    CASE WHEN representante = '""' THEN NULL ELSE TRIM(BOTH '"' FROM representante) END,
    CASE WHEN cargo_representante = '""' THEN NULL ELSE TRIM(BOTH '"' FROM cargo_representante) END,
    CASE WHEN regiao_comercializacao = '""' THEN NULL ELSE TRIM(BOTH '"' FROM regiao_comercializacao) END,
    -- Lidar com o formato de data (assumindo que o formato YYYY-MM-DD está no CSV)
    CASE 
        WHEN TRIM(BOTH '"' FROM data_registro_ans) ~ '^\d{4}-\d{2}-\d{2}$' 
        THEN TO_DATE(TRIM(BOTH '"' FROM data_registro_ans), 'YYYY-MM-DD')
        ELSE NULL
    END
FROM temp_operadoras;

-- Dropa a tabela temporária
DROP TABLE temp_operadoras;

-- Analisa as tabelas para otimizar o desempenho das consultas
ANALYZE operadoras;
ANALYZE modalidades;
ANALYZE uf;
ANALYZE regioes_comercializacao; 