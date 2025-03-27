-- Script para criar as tabelas para os dados do Relatorio_cadop.csv

-- Dropa a tabela se ela existir
DROP TABLE IF EXISTS operadoras;

-- Cria a tabela para os dados das operadoras
CREATE TABLE operadoras (
    registro_ans VARCHAR(10) PRIMARY KEY,
    cnpj VARCHAR(14) NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    nome_fantasia VARCHAR(255),
    modalidade VARCHAR(100) NOT NULL,
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(20),
    complemento VARCHAR(255),
    bairro VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep VARCHAR(8) NOT NULL,
    ddd VARCHAR(4),
    telefone VARCHAR(20),
    fax VARCHAR(20),
    endereco_eletronico VARCHAR(255),
    representante VARCHAR(255),
    cargo_representante VARCHAR(100),
    regiao_comercializacao VARCHAR(10),
    data_registro_ans DATE,
    -- Adiciona índices para campos de busca comuns
    CONSTRAINT operadoras_cnpj_ck CHECK (cnpj ~ '^[0-9]{14}$'),
    CONSTRAINT operadoras_cep_ck CHECK (cep ~ '^[0-9]{8}$')
);

-- Cria índices para melhorar o desempenho das consultas
CREATE INDEX idx_operadoras_razao_social ON operadoras(razao_social);
CREATE INDEX idx_operadoras_modalidade ON operadoras(modalidade);
CREATE INDEX idx_operadoras_uf ON operadoras(uf);
CREATE INDEX idx_operadoras_cidade ON operadoras(cidade);
CREATE INDEX idx_operadoras_cnpj ON operadoras(cnpj);

-- Tabela adicional para armazenar diferentes modalidades (tipos de operadoras)
CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL
);

-- Cria uma função para atualizar automaticamente a tabela de modalidades
CREATE OR REPLACE FUNCTION update_modalidades()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO modalidades (nome)
    VALUES (NEW.modalidade)
    ON CONFLICT (nome) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cria um trigger para manter a tabela de modalidades atualizada
CREATE TRIGGER trig_update_modalidades
AFTER INSERT OR UPDATE ON operadoras
FOR EACH ROW
EXECUTE FUNCTION update_modalidades();

-- Cria uma tabela para UF (estados)
CREATE TABLE uf (
    sigla CHAR(2) PRIMARY KEY,
    nome VARCHAR(50) NOT NULL
);

-- Cria uma tabela para regiões de comercialização
CREATE TABLE regioes_comercializacao (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    descricao VARCHAR(100)
);

-- Comentários para melhor documentação
COMMENT ON TABLE operadoras IS 'Armazena dados das operadoras de saúde da ANS';
COMMENT ON COLUMN operadoras.registro_ans IS 'Número de registro na ANS - chave primária';
COMMENT ON COLUMN operadoras.cnpj IS 'CNPJ (ID fiscal corporativo) da operadora';
COMMENT ON COLUMN operadoras.modalidade IS 'Tipo de operador (e.g., Medicina de Grupo, Cooperativa odontológica)';
COMMENT ON COLUMN operadoras.regiao_comercializacao IS 'Código da região onde a operadora é permitida a operar';
COMMENT ON COLUMN operadoras.data_registro_ans IS 'Data de registro na ANS'; 