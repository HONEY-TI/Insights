# 🖥️ Sistemas — Arquitetura de Submodules Git Insights`

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

## 🔗 Relações

- `operations/` → execução
- `knowledge/` → conhecimento procedural
- `systems/` → regras arquiteturais

---

## 📌 Relacionados

- `knowledge/integracao-submodules-git-projetos.md`
- `operations/ciclo-vida-submodules-git.md`****