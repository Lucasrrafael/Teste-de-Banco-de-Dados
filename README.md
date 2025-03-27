# Base de Dados de Operadoras de Saúde ANS

Este repositório contém scripts PostgreSQL para construir um banco de dados para análise de dados de operadoras de saúde da Agência Nacional de Saúde Suplementar (ANS).

## Visão Geral

O banco de dados consiste em dois conjuntos principais de dados:

1. **Relatorio_cadop.csv** - Informações de registro das operadoras de saúde, incluindo detalhes da empresa, informações de contato e dados de registro.
2. **Dados financeiros trimestrais** (1T2023.csv até 4T2024.csv) - Demonstrações financeiras das operadoras de saúde, contendo saldos de contas organizados por trimestres.

Os scripts criam um esquema de banco de dados relacional, importam os dados e fornecem consultas úteis para análise.

## Estrutura do Banco de Dados

### Tabelas Principais

1. `operadoras` - Armazena informações básicas sobre as operadoras de saúde
2. `dados_contabeis_trimestral` - Armazena dados financeiros trimestrais das operadoras
3. `plano_contas` - Estrutura do plano de contas com relacionamentos hierárquicos
4. Tabelas de suporte: `modalidades`, `uf`, `regioes_comercializacao`

## Arquivos neste Repositório

- `create_tables_cadop.sql` - Cria tabelas para dados das operadoras
- `import_data_cadop.sql` - Importa dados do Relatorio_cadop.csv
- `create_tables_trimestral.sql` - Cria tabelas para dados financeiros trimestrais
- `import_data_trimestral.sql` - Importa dados dos arquivos CSV trimestrais
- `queries_3_5.sql` - Consultas específicas para análise de despesas com eventos/sinistros

### Arquivos de Dados

- `Relatorio_cadop.csv` - Dados cadastrais das operadoras
- Dados financeiros trimestrais:
  - 2023: `1T2023.csv`, `2T2023.csv`, `3T2023.csv`, `4T2023.csv`
  - 2024: `1T2024.csv`, `2T2024.csv`, `3T2024.csv`, `4T2024.csv`

## Instruções de Uso

### Pré-requisitos

- PostgreSQL 10 ou superior
- Espaço em disco suficiente (os arquivos trimestrais são grandes)
- Todos os arquivos CSV e SQL devem estar no mesmo diretório ou em um caminho acessível

### Preparação dos Scripts

**IMPORTANTE**: Antes de executar os scripts, você precisa editar os caminhos dos arquivos:

1. No arquivo `import_data_cadop.sql`, substitua:
   ```sql
   COPY temp_operadoras FROM '/caminho/completo/Relatorio_cadop.csv'
   ```
   pelo caminho completo ou relativo do seu arquivo `Relatorio_cadop.csv`

2. No arquivo `import_data_trimestral.sql`, atualize os caminhos para cada arquivo trimestral:
   ```sql
   SELECT importar_dados_trimestrais('/caminho/completo/1T2023.csv', '1T', 2023);
   ```
   para o caminho correto, por exemplo:
   ```sql
   SELECT importar_dados_trimestrais('/caminho/completo/1T2023.csv', '1T', 2023);
   ```
   ou, se os arquivos estiverem no mesmo diretório do PostgreSQL:
   ```sql
   SELECT importar_dados_trimestrais('1T2023.csv', '1T', 2023);
   ```

### Configuração do Banco de Dados

**ATENÇÃO**: A ordem de execução dos scripts é crítica para o funcionamento do banco de dados. Os scripts devem ser executados EXATAMENTE na seguinte sequência:

1. Primeiro, crie as tabelas para operadoras:
```sql
\i create_tables_cadop.sql
```

2. Importe os dados das operadoras:
```sql
\i import_data_cadop.sql
```

3. Só após importar os dados das operadoras, crie as tabelas para dados financeiros:
```sql
\i create_tables_trimestral.sql
```
**Nota de segurança**: O script `create_tables_trimestral.sql` inclui verificações automáticas que impedem sua execução caso a tabela `operadoras` não exista, garantindo que os passos 1 e 2 tenham sido executados corretamente.

4. Finalmente, importe os dados financeiros trimestrais:
```sql
\i import_data_trimestral.sql
```
**Nota de segurança**: O script `import_data_trimestral.sql` também verifica a existência das tabelas `operadoras` e `dados_contabeis_trimestral` antes de prosseguir, garantindo que a sequência correta seja seguida.

**Observação**: O processo de importação dos dados trimestrais pode levar bastante tempo devido ao volume de dados.

### Executando Consultas de Análise

```sql
-- Execute consultas específicas para análise de despesas com eventos/sinistros
\i queries_3_5.sql
```

## Modelos de Dados

### Modelo de Dados das Operadoras

A tabela `operadoras` contém os seguintes campos principais:
- `registro_ans` - Número de registro ANS (chave primária)
- `cnpj` - CNPJ da empresa
- `razao_social` - Nome da empresa
- `modalidade` - Tipo de operadora (ex: "Medicina de Grupo", "Cooperativa odontológica")
- Dados de localização (endereço, cidade, estado)
- Informações de contato (telefone, email)
- Informações do representante

### Modelo de Dados Financeiros

A tabela `dados_contabeis_trimestral` inclui:
- `registro_ans` - Número de registro ANS (chave estrangeira para operadoras)
- `data_referencia` - Data de referência
- `codigo_conta_contabil` - Código da conta
- `descricao_conta` - Descrição da conta
- `valor_saldo_inicial` - Saldo inicial
- `valor_saldo_final` - Saldo final
- `trimestre` - Trimestre (1T, 2T, 3T, 4T)
- `ano` - Ano

A tabela `plano_contas` estabelece uma estrutura hierárquica de contas com relacionamentos pai-filho.

## Análises Disponíveis

1. Posição financeira por operadora através da view `posicao_financeira_operadoras`
2. Análise de despesas com eventos/sinistros através das consultas em `queries_3_5.sql`, incluindo:
   - 10 operadoras com maiores despesas em eventos/sinistros médico-hospitalares no último trimestre
   - 10 operadoras com maiores despesas em eventos/sinistros médico-hospitalares no último ano

## Otimização de Desempenho

O banco de dados inclui:
- Índices apropriados para todas as tabelas principais
- Restrições e verificações para garantir a integridade dos dados
- Funções e triggers para manter a consistência dos dados

## Requisitos

- PostgreSQL 10 ou superior
- Arquivos CSV com dados da ANS
- Espaço em disco suficiente para o banco de dados (os arquivos trimestrais podem ser grandes)

## Limitações Conhecidas

- Algumas operadoras podem não possuir dados financeiros para determinados períodos
- Os códigos de contas financeiras podem variar entre operadoras, afetando a precisão da agregação
- O processo de importação pode levar um tempo considerável para arquivos trimestrais grandes

## Problemas Conhecidos e Soluções

1. **Inconsistência nos nomes dos arquivos**: Certifique-se de que todos os arquivos trimestrais seguem o padrão `NT2023.csv` onde N é o número do trimestre. Se existir, por exemplo, `2t2023.csv` (com 't' minúsculo), renomeie para `2T2023.csv`.

2. **Formatação dos CSV**: Os arquivos CSV podem conter formatações específicas. Se ocorrerem erros durante a importação, verifique se:
   - As colunas estão separadas por ponto e vírgula (;)
   - Os campos de texto estão entre aspas duplas (")
   - A codificação do arquivo é UTF-8

3. **Requisitos de espaço**: A importação dos dados requer espaço suficiente no servidor PostgreSQL. Certifique-se de que há espaço disponível. 