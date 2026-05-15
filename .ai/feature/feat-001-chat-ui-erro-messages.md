
---
name: feat-chat-ui-erro-messages
description: Controlar a exibição de mensagens no chat garantindo que erros não apareçam antes da interação do usuário, mantendo mensagens amigáveis e delegando a renderização ao componente de UI.
---

# 🧠 Skill Entry Point: Chat UI Erro Messages


## Regras

  - Não criar complexidade desnecessárias
  - Utilizar tratamento de errro ja existenmte de eErros Globas Global localizado em /core/Infrastructure
  - Criar implementações usando O.O. SOLID, Clean Code, Tipagem Forta e Testes Unitários
  - Não executar comandos pedir para que eu execute manualmente e entregeue a saida 
  - Erros não devem aparecer antes da interação do usuário
### 1. Exemplos de erro não tratados ocorrendo em CoreChatGateway
  *  [UNKNOWN ERROR] 401 {"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"},"request_id":"req_011CagHD2NiMrF5j4pJsLJ8p"} 
  *  [UNKNOWN ERROR] 400 The model `llama3-70b-8192` has been decommissioned...
  *  [QUOTA ERROR] Limite de cota atingido 

### 2. Mensagens amigáveis
- O conteúdo já vem tratado externamente, caso não haja criar um tratamento de erro global cada tipo de erro com mensagens amigáveis
- Gerar Comforme Implementação já criada padronizada o log de erro 


### 3. Responsabilidade do ChatMessageComponent
- Exibir mensagem dentro de message.content no componente ChatMessageComponent
- Aplicar estilo de erro na caixa de mensage 

### 4. Estilização de erro
Se message.type === 'error':
- aplicar estilo visual de erro (cor, fundo, borda, destaque)

## Resultado Esperado

- Nenhum erro exibido antes da interação
- Mensagens padronizadas sempre registatradas na pasta /.log_erros seguindo padrão de tratamento e exebição de erro
- UI desacoplada da lógica de erro
- Renderização consistente no ChatMessageComponent
