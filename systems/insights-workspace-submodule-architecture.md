---
name: insights-workspace-submodule-architecture
description: Define a arquitetura modular do workspace Insights baseada em Git Submodules, incluindo organização estrutural, desacoplamento entre projetos e governança do ecossistema multi-repo.
---

# 🖥️ Sistemas — Arquitetura de Submodules Git `Insights`

##  🔗 Relacionados

- [Git Integration Project](/knowledge/git/integration-project.md)
- [Sub Modules Life Cycle](/knowledge/git/submodules/lifecycle.md)

## 📌 Modelo

O repositório do `Insights` segue uma arquitetura híbrida entre monorepo e multi-repo.

---

## 📂 Camadas

### 1. Repositório Principal (/insights)
- Orquestra estrutura geral
- Mantém apenas referências

### 2. Submodules (/projects)
- Repositórios independentes
- Ciclo de vida próprio
- Pipelines próprias

---

## 🔄 Princípios de Arquitetura

- Desacoplamento entre projetos
- Sincronização explícita
- Estado determinístico
- Compatibilidade entre sistemas operacionais

---

## 📌 Relações

- `knowledge/` → conhecimento e governança operacional
- `playbooks/` → execução reproduzível e recuperação
- `operations/` → rotinas operacionais e administração
- `systems/` → arquitetura, topologia e regras sistêmicas