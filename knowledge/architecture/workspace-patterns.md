---
name: workspace-patterns
description: Define padrões estruturais, organizacionais e operacionais do workspace Insights para projetos, automações, playbooks e integração Git.
---


# 🧩 Conhecimento — Padrões de Workspace Git

## 📌 Objetivo

Definir padrão estrutural e comportamental do workspace `/insights` para garantir consistência entre projetos, submodules e automações.

---

# 🧱 Estrutura Base

```bash
## 📂 Estrutura

```bash
/Insights
├── .git
├── .gitmodules
├── /knowledge
│   ├── /architecture
│   │   └── /linux-debian\ubuntu
│   ├── /git
│   │   ├── /recovery
│   │   └── /submodules
│   ├── git-ssh-generate.md
│   └── integration-project.md
│
├── /operations
│   ├── /linux
│   │   └── .gitKepp
│   └── /windows
│       └── .gitKepp
│
├── /playbooks
│   ├── /linux
│   │   └── .gitKepp
│   └── /windows
│       └── .gitKepp
│
├── /projects
│   ├── /project-a
│   │   └── .git
│   └── /project-b
│       └── .git
│
└── systems
│   ├── /linux
│   │   └── .gitKepp
│   └── /windows
        └── .gitKepp

```

---

# ⚙️ Princípios de Organização

## 1️⃣ Separação por responsabilidade

Cada diretório possui um papel único:

- `systems` → arquitetura e regras estruturais
- `operations` → execução e processos
- `playbooks` → execução passo a passo
- `knowledge` → entendimento e aprendizado

---

## 2️⃣ Independência de projeto

Cada projeto pode conter:

- documentação própria
- pipelines próprias
- regras próprias
- submodules independentes

---

## 3️⃣ Compatibilidade cross-platform

O workspace deve funcionar em:

- Linux
- Windows
- macOS

Sem dependências rígidas de sistema.

---

# 🔄 Fluxo de Evolução

```text
ideia → documentação → playbook → automação → execução → observação → melhoria
```

---

# 🧠 Regras de Padronização

- evitar dependência de caminhos absolutos
- usar sempre estrutura relativa
- evitar scripts não portáveis
- priorizar Git-native workflows

---

# 🔗 Integração com Git Flow

Compatível com:

- feature branches
- hotfix
- pull requests
- code review
- CI/CD pipelines

---

# 📌 Relacionados

- `systems/arquitetura-submodules-git.md`
- `operations/ciclo-vida-submodules-git.md`