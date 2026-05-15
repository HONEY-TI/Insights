---
name: auto_commit_message
description: Executar Commit por Arquivo com Mensagem Inteligente automatizada

---

# 🧠 Skill Entry Point: Commit por Arquivo com Mensagem Inteligente

---

## 🎯 Objetivo

Criar commits **granulares e semânticos**, onde:

* Cada arquivo modificado gera **um commit individual**
* Cada commit possui uma **mensagem específica baseada na alteração** e sua descrição detalahda sucintamente no formato markdown
* Sempre criar descrições para mensagem utilizando língua portuguesa
* Cire sempre mensagens com descrições siginificativas sobre as alterações
* O processo é **automatizado via Git + análise de diff**

---

## ⚙️ Pré-requisitos

* Git instalado
* Repositório inicializado
* Não criar script para execução das tarefas 

---

## 🚀 Fluxo da Skill

### 1. Obter lista de arquivos modificados

```bash
git status --porcelain=v1 -uall
```

Ou mais direto:

```bash
git diff --name-only
```

Para incluir staged:

```bash
git diff --name-only --cached
```

---

### 2. Iterar sobre cada arquivo

```bash
git diff --name-only | while read file; do
  echo "Processando $file"
done
```

---

### 3. Analisar o diff do arquivo

```bash
git diff "$file"
```

Ou (staged):

```bash
git diff --cached "$file"
```

---

## 🧠 Regras para geração de mensagem

Para cada arquivo, analisar:

### 📌 Tipo de alteração

| Tipo       | Regra                   |
| ---------- | ----------------------- |
| Novo       | `git status` mostra `A` |
| Modificado | `M`                     |
| Removido   | `D`                     |

---

### 📌 Heurísticas de mensagem

Baseado no conteúdo do diff:

#### ✔ Código

* Adição de função → `feat: add <nome_da_funcao>`
* Refatoração → `refactor: improve structure`
* Bugfix → `fix: correct <problema>`

#### ✔ Configuração

* `chore: update configuration`

#### ✔ Testes

* `test: add/update tests`

#### ✔ Docs

* `docs: update documentation`

---

## 🔁 Execução automática (bash)

```bash
git diff --name-only | while read file; do

  diff=$(git diff "$file")

  # Detectar tipo
  status=$(git status --porcelain "$file" | awk '{print $1}')

  if [[ "$status" == "A" ]]; then
    type="feat"
    action="add"
  elif [[ "$status" == "M" ]]; then
    type="fix"
    action="update"
  elif [[ "$status" == "D" ]]; then
    type="chore"
    action="remove"
  else
    type="chore"
    action="update"
  fi


  message="$type: $action changes"
  description="mensagem detalhada sucintamente no formato markdown"

  git add "$file"
  git commit -m "$message" -m "$description"

done
```

---

## 💡 Versão avançada (com diff inteligente)

Você pode melhorar a mensagem analisando o conteúdo:

```bash
if echo "$diff" | grep -q "function"; then
  message="feat: add or update function"
elif echo "$diff" | grep -q "class"; then
  message="refactor: update class structure"
elif echo "$diff" | grep -q "test"; then
  message="test: update tests"
fi
```

---

## 🔒 Boas práticas

* Nunca fazer commit em massa sem revisar
* Garantir que o código compila antes
* Evitar mensagens genéricas como "update file"

---

## 🧪 Exemplo real

Alterações:

```
M src/app/service.ts
A src/app/new-feature.ts
```

Resultado:

```
commit 1 → feat: add changes
commit 2 → fix: update changes
```

---

## 🚀 Benefícios

* Histórico limpo
* Melhor rastreabilidade
* Facilita code review
* Ideal para CI/CD e debugging

---

## ⚠️ Limitações

* Heurísticas simples podem não capturar contexto completo
* Pode precisar ajuste manual em casos complexos

---

## 🔥 Evoluções futuras

* Integração com IA para gerar mensagens mais precisas
* Suporte a Conventional Commits completo
* Classificação por diretório (`domain`, `infra`, etc.)

---

## ✅ Conclusão

Essa skill transforma commits em:

✔ Granulares
✔ Inteligentes
✔ Padronizados

Sem depender de esforço manual.

---
