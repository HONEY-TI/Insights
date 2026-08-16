---
name: git-submodule-auto-init
description: Padrão DevOps profissional para inicialização automática de repositórios Git com submodules, baseado em bootstrap script versionado e hooks locais opcionais para garantir setup idempotente e reprodutível do ambiente Insights.
---

# 🚀 Git Submodule DevOps Auto-Init Standard

## 🎯 Objetivo

Definir um padrão DevOps profissional para garantir que repositórios Git com submodules sejam:

- 📦 inicializados automaticamente após clone
- 🔄 sincronizados de forma consistente entre ambientes
- 🧩 idempotentes (podem ser executados várias vezes sem erro)
- ⚙️ prontos para uso com um único comando
- 🧠 independentes de execução manual complexa

---

# 🧠 Princípio central

> O repositório deve ser auto-inicializável por design.

Isso significa:

- o clone não deve depender de memória humana
- o ambiente deve se reconstruir sozinho
- submodules devem ser tratados como dependências declaradas

---

# 🏗️ Arquitetura da solução

A solução DevOps é composta por 3 camadas:

## 1. 🚀 Bootstrap Script (camada obrigatória e versionada)

📁 .scripts/bootstrap.sh

#!/usr/bin/env bash

set -e

echo "🚀 [Insights] Starting full repository bootstrap..."

if [ -f .gitmodules ]; then
  echo "📦 Syncing git submodules..."
  git submodule sync --recursive
  git submodule update --init --recursive
else
  echo "ℹ️ No submodules found"
fi

echo "✅ Bootstrap completed successfully"

---

## ▶️ Execução padrão

Após clone:

git clone --recurse-submodules <repo-url>
cd Insights
bash .scripts/bootstrap.sh

---

# 2. ⚙️ Git Hook Local (camada de conveniência)

📁 .git/hooks/post-checkout

#!/usr/bin/env bash

set -e

if [ -f .gitmodules ]; then
  echo "🔄 [Hook] Auto-syncing submodules after checkout..."
  git submodule sync --recursive
  git submodule update --init --recursive
fi

---

## 🔐 Ativação

chmod +x .git/hooks/post-checkout

---

## ⚠️ Limitação estrutural

- ❌ hooks não são versionados no Git
- ❌ não executam no clone inicial
- ✔ funcionam em checkout, pull e troca de branches

---

# 3. 🧩 Clone padrão recomendado (camada ideal)

git clone --recurse-submodules <repo-url>

---

# ⚙️ Fluxo DevOps completo

📥 Clone repositório  
→ 🧩 Submodules inicializados  
→ 🚀 Bootstrap executado  
→ 🔄 Sync garantido  
→ ⚙️ Ambiente pronto

---

# 🧠 Garantias do padrão

## ✔ Idempotência
Pode rodar múltiplas vezes sem quebrar estado.

## ✔ Reprodutibilidade
Mesmo resultado em qualquer máquina.

## ✔ Auto-recuperação
Submodules podem ser restaurados facilmente.

## ✔ Zero dependência de memória humana
O sistema se inicializa sozinho via script.

---

# 🧱 Estrutura recomendada do repositório

Insights/
├── .scripts/
│   ├── bootstrap.sh
│   ├── sync.sh (opcional)
│   └── install.sh (opcional)
├── .gitmodules
└── .git/hooks/
    └── post-checkout (local)

---

# 🔐 Boas práticas DevOps aplicadas

- 📦 Dependências versionadas (submodules)
- ⚙️ Inicialização automatizada (bootstrap)
- 🔄 Sincronização explícita (sync)
- 🧩 Separação entre core e conveniência (hook)
- 🧠 Design orientado a reprodutibilidade

---

# 🚀 Resultado final

Este padrão transforma o repositório em um sistema:

- auto-inicializável
- auto-consistente
- DevOps-ready
- multi-ambiente (Linux/Windows/CI)

---

# 🔗 Relacionados

- Git Submodule Lifecycle Model
- Insights Bootstrap Architecture
- DevOps Repository Initialization Strategy