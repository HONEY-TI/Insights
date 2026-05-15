---
name: feat-chat-ui-error-messages
description: Gerenciar a exibição de mensagens de erro no chat, garantindo comunicação amigável, consistente e contextualizada ao usuário, sem expor erros técnicos.
---

# 🧠 Skill Entry Point: Chat UI Error Messages

## 🎯 Objetivo

Garantir que erros ocorridos no chat sejam apresentados de forma amigável, contextualizada e consistente, evitando mensagens técnicas ou críticas desnecessárias ao usuário final.

---

## 📌 Regras Gerais

- Não criar complexidade desnecessária.
- Utilizar o sistema de tratamento de erros já existente em:
  `/core/Infrastructure` (Error Handling Global).
- Seguir princípios de:
  - Clean Code
  - SOLID
  - Tipagem forte
  - Testes unitários obrigatórios
- Não executar comandos automaticamente.
  - Sempre solicitar execução manual quando necessário.
  - Sempre retornar a saída esperada ou simulada.
- Nenhum erro deve ser exibido antes da interação do usuário.
- Nunca expor mensagens técnicas diretamente ao usuário final.

---

## 🚨 Tratamento de Erros

### 1. Padronização de mensagens

Erros técnicos devem ser convertidos em mensagens amigáveis através do:

- `ErrorMessageResolverService`

Exemplo:

| Erro técnico | Exibição ao usuário |
|--------------|---------------------|
| `[QUOTA ERROR] Limite de cota atingido` | Mensagem amigável contextual |

---

### 2. Mensagem padrão global

Caso o erro não seja reconhecido:

> “Ocorreu um erro inesperado. Tente novamente.”

⚠️ Essa mensagem é o fallback universal e NÃO deve ser usada como primeira opção quando houver contexto disponível.

---

## 🧩 Estratégia de UX para mensagens

Evitar mensagens genéricas sempre que possível.

Em vez disso:

- Interpretar o contexto da ação do usuário
- Mapear o tipo de erro
- Gerar mensagem contextual e amigável

### Exemplo de melhoria

❌ Ruim:
> Ocorreu um erro inesperado.

✅ Melhor:
> Você atingiu o limite de uso deste recurso no momento. Tente novamente em alguns minutos.

---

## 🧱 Implementação

As mensagens devem ser criadas e organizadas dentro de:

/workspaces/angular-app/src/app/shared/components/chat

Criar um sistema de mensagens amigáveis baseado no contexto da ação:

- envio de mensagem
- carregamento de resposta
- execução de ferramentas
- chamadas externas

---

## 🧠 Princípio de Design

“O usuário não deve ver erros — deve entender o problema.”

---

## 🧪 Testes

- Cobrir cenários de erro conhecidos
- Validar fallback global
- Garantir coerência das mensagens por tipo de ação
- Evitar regressões em mensagens já existentes

---

## 🚫 Anti-padrões

- Expor stacktrace ao usuário
- Mostrar códigos de erro técnicos
- Usar mensagens genéricas sem contexto quando há informação disponível
- Criar múltiplos handlers redundantes para o mesmo erro