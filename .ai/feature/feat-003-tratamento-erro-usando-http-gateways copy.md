---
name: feat-003-tratamento-erro-http-gateway
description: Gerenciamento de erros em requisições via ChatGateway com mapeamento contextual e exibição amigável ao usuário.
---

# 🧠 Skill Entry Point: Chat UI Error Handling via Gateway

## 🎯 Objetivo

Garantir que erros provenientes de requisições via **HttpChatGateway** sejam tratados de forma **estruturada, contextual e amigável**, evitando exposição de detalhes técnicos ao usuário final.

---

## 🧱 Arquitetura de Tratamento de Erros

A solução segue princípios de:

- DDD (Domain-Driven Design)
- SOLID
- Clean Code
- Tipagem forte (TypeScript)

Separação clara de responsabilidades:

- **Domínio** → códigos de erro
- **Aplicação** → mapeamento de mensagens
- **Infraestrutura** → captura de erros HTTP
- **UI** → exibição ao usuário

---

## 📌 Regras Gerais

- Não criar complexidade desnecessária.
- Utilizar o sistema global de erros existente em:
  `/core/Infrastructure`
- Nunca expor mensagens técnicas ao usuário final.
- Todo erro deve ser convertido antes de chegar na UI.
- Não executar comandos automaticamente.
- Sempre aguardar resposta antes de exibir erro.
- Erros só devem ser exibidos após interação do usuário.

---

## 🌐 HttpChatGateway (Regras de Comunicação)

### ⏱ Tratamento de latência

Requisições via HTTP podem ter comportamento assíncrono ou demorado.

Regras:

- Sempre aguardar resposta antes de considerar erro.
- Aplicar timeout máximo de **30 segundos**.
- Caso exceda o tempo limite:
  - Cancelar requisição
  - Ignorar qualquer resposta tardia
  - Exibir mensagem amigável de timeout

### ⚠️ Cenários de erro

| Cenário | Tratamento |
|--------|-----------|
| API fora do ar | Erro crítico contextualizado |
| Timeout (>30s) | Mensagem de tempo excedido |
| Erro desconhecido | Fallback global amigável |

---

## 🚨 Tratamento de Erros

### 🧠 Estratégia principal

Todos os erros devem ser convertidos via:

- `ErrorMessageResolverService`

Responsabilidade:

- Receber erro técnico ou de domínio
- Mapear para mensagem amigável
- Aplicar contexto da ação (chat, envio, resposta, tool execution)

---

### 📌 Fallback global

Quando não houver mapeamento específico:

> “Ocorreu um erro inesperado. Tente novamente.”

⚠️ Deve ser usado apenas como último recurso.

---

## 🧩 Estratégia de UX

O sistema deve sempre:

- Interpretar contexto da ação do usuário
- Diferenciar tipos de operação:
  - envio de mensagem
  - resposta de IA
  - execução de ferramentas
  - chamadas HTTP externas
- Evitar mensagens genéricas quando há contexto disponível

---

### 💡 Exemplo

❌ Ruim:
> Ocorreu um erro inesperado.

✅ Melhor:
> O serviço demorou para responder. Tente novamente em instantes.

---

## ⏱ Regra de Timeout (UX)

- Tempo limite padrão: **30 segundos**
- Após esse tempo:
  - cancelar requisição ativa
  - ignorar respostas tardias
  - exibir mensagem amigável:

> “A resposta demorou mais que o esperado. Tente novamente em instantes.”

---

## 🧱 Implementação

O sistema de mensagens deve ser desacoplado de:
  `/workspaces/angular-app/src/app/shared/components/chat`

Estrutura recomendada:

- Gateway
- Resolver (ErrorMessageResolverService)
- Mappers de erro por domínio
- Strategies de mensagens

---

## 🧠 Princípio de Design

> “O usuário não deve ver erros técnicos — deve entender o que aconteceu de forma simples e contextual.”

---

## 🧪 Testes

- Cobertura de erros HTTP (4xx, 5xx, timeout)
- Validação de fallback global
- Garantia de mapeamento correto por tipo de erro
- Testes de comportamento assíncrono (latência > 30s)
- Evitar regressão em mensagens existentes

---

## 🚫 Anti-padrões

- Expor stacktrace ao usuário
- Mostrar códigos HTTP diretamente na UI
- Criar múltiplos handlers redundantes
- Exibir erro antes da resposta final do gateway
- Ignorar contexto da ação do usuário
  