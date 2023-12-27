# SAP HCM Payroll Data Analysis

Este é um programa desenvolvido para o módulo SAP HCM (Human Capital Management) com o objetivo de realizar a análise detalhada dos dados da folha de pagamento.

## Funcionalidades Principais

- **Parâmetros de Entrada:**
  - O usuário fornece três parâmetros na tela de seleção: `p_abkrs` (Área de Folha de Pagamento), `p_month1` (Mês), e `p_fyear1` (Ano).

- **Validações de Entrada:**
  - Verificações são realizadas para garantir que os parâmetros inseridos sejam válidos, como a validação do mês para não ser superior a 12, e a validação da área de folha de pagamento.

- **Determinação do Período:**
  - Utiliza a função `get_period` para calcular o período de início e fim com base no mês e ano fornecidos.

- **Seleção de Empregados Ativos:**
  - Realiza uma seleção na tabela `pa0001` para obter informações sobre empregados ativos durante o período e na área de folha de pagamento especificada.

- **Leitura de Dados da Folha de Pagamento:**
  - Utiliza funções específicas do HCM, como `CU_READ_RGDIR` e `PYXX_READ_PAYROLL_RESULT`, para acessar informações relevantes da folha de pagamento.

- **Apresentação de Resultados:**
  - Apresenta os resultados na tela de forma estruturada, incluindo número pessoal, rubricas salariais e detalhes de cálculo das folhas de pagamento.

## Pré-requisitos

- Ambiente SAP HCM configurado e funcional.

## Como Utilizar

1. Clone este repositório.
2. Carregue o código ABAP no ambiente SAP.
3. Crie um programa executável pela se38 ou se80 e cole o codigo, lembrando de atualizar o nome do programa no `REPORT z_algj_43`.
4. Insira os parâmetros solicitados na tela de seleção.
5. Analise os resultados apresentados na tela.

## Contribuindo

Sinta-se à vontade para contribuir melhorando o programa ou corrigindo os possíveis erros.

## Contato

Se você tiver dúvidas ou sugestões, sinta-se à vontade para entrar em contato:

- `André Luiz G.J.` - [andreluizguilhermini@gmail.com]