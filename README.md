# 💾 Laboratório de Hardware - System On a Chip (VHDL)

- Rafael Torres Nantes
- Sarah Merigue Baraldi 

Este repositório contém o trabalho desenvolvido para modelar um hardware denominado **System on a Chip (SoC)**. O sistema foi projetado e implementado em VHDL e consiste em diversos subcomponentes, incluindo um processador, duas memórias principais e um codec. O objetivo principal é executar um conjunto de instruções RISC e avaliar a viabilidade do desempenho e a redução do consumo de recursos físicos.

## 📌 Estrutura do Projeto

- **Processador**: Implementa uma arquitetura MISC com instruções simples e opera com dados de 1 byte.
- **Memória**: Inclui duas memórias principais - IMEM (Memória de Instruções) e DMEM (Memória de Dados).
- **Codec**: Realiza comunicação de entrada e saída com a CPU.
- **SoC**: Entidade de mais alto nível que encapsula e conecta todos os componentes.

## 📂 Estrutura do Repositório

- **src**: Código-fonte VHDL dos componentes do SoC.
  - **Processor**: Implementação do processador, incluindo características, funções e instruções.
  - **Memory**: Implementação das memórias IMEM e DMEM.
  - **Codec**: Implementação do codec para comunicação de entrada e saída.
  - **SoC**: Implementação da entidade System on a Chip que conecta todos os componentes.
- **testbenches**: Scripts de teste para verificar o funcionamento dos componentes.
- **docs**: Documentação adicional e diagramas.

## 🔧 Componentes e Funcionalidades

### 1. Processador

#### Proposta

O processador segue uma arquitetura MISC (Minimal Instruction Set Computer) com:
- Dados de 1 byte
- Suporte a complemento de 2
- Duas memórias principais (IMEM e DMEM)

#### Funções Implementadas

O processador opera como uma máquina de estados com os seguintes estados:
1. **Halted**: CPU parada sem execução.
2. **Fetch Instruction**: Busca o endereço da próxima instrução.
3. **Decode Instruction**: Decodifica a instrução e carrega os operandos.
4. **Execute Instruction**: Executa a instrução.
5. **Modify IP**: Altera o endereço no registrador IP.

Instruções suportadas:
- `HLT`, `IN`, `OUT`, `PUSH`, `DROP`, `DUP`, `ADD`, `SUB`, `NAND`, `SLT`, `SHL`, `SHR`, `JEQ`, `JMP`

### 2. Memória

#### Proposta

- **IMEM**: Memória de instruções.
- **DMEM**: Memória de dados.
- **Parâmetros**: 16 bits para endereço e 8 bits para dado.

#### Funções Implementadas

Implementada como arquitetura comportamental. Retorna 4 bytes lidos a partir do endereço enviado.

### 3. Codec

#### Proposta

Comunica-se com a CPU através de instruções `IN` e `OUT`. 
- **IN**: Lê dados e atribui sinais de leitura e escrita.
- **OUT**: Escreve dados e atribui sinais de leitura e escrita.

#### Funções Implementadas

Implementado como uma arquitetura de fluxo de dados. Lê do arquivo "input.txt" e escreve no "output.txt".

### 4. SoC

#### Proposta

A entidade SoC é a mais alta na hierarquia e conecta todos os componentes. 
- **Entradas**: Clock e Started.
- **Funções Implementadas**: Mapeia e conecta Codec, IMEM, DMEM e CPU. Lê o arquivo "firmware.bin".

## 🛠️ Configuração e Testes

### Ferramentas e Ambiente

- **VHDL**: Linguagem utilizada para modelagem do hardware.
- **Simuladores**: Utilize um simulador VHDL compatível para testar os componentes e o SoC.

### Testes

Scripts de teste estão localizados na pasta `testbenches`. Execute os testes para verificar o funcionamento dos componentes e a integração do SoC.

## 🚧 Problemas e Soluções

### Dificuldades Encontradas

- Definição das entradas e saídas do testbench da CPU.

### Problemas Solucionados

- Conversões de dados (unsigned para signed e tipo natural para std_vector).
- Problemas no testbench da CPU resolvidos com a instrução `wait`.

### Problemas Não Solucionados

- Warning no testbench do SoC e incertezas sobre a funcionalidade completa do SoC.

## 📄 Documentação

Para detalhes adicionais, consulte os arquivos na pasta `docs`, onde estão incluídos diagramas e explicações sobre o projeto.