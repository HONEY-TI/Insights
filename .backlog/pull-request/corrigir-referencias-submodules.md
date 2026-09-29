---
name: corrigir-referencias-submodules
pr: 17
title: "PR(#17)-Corrigir referencias invalidas de submodules"
branch: hotfix/corrigir-referencias-submodules
base: main
extends: feature-05-corrigir-referencias-submodules
status: open
---

## 📋 Descrição

Corrige referências inválidas de submodules e registra o projeto de despesas pessoais, garantindo inicialização local e remota pelo bootstrap.

Feature relacionada: `.backlog/features/feature-05-corrigir-referencias-submodules.md`

## 📊 Estatísticas

| Métrica | Valor |
|---|---:|
| 🌿 Branch de origem | `hotfix/corrigir-referencias-submodules` |
| 🎯 Branch de destino | `main` |
| 📝 Total de commits | 2 |
| 📁 Arquivos alterados | 8 |

## 📦 Repositórios/branches atualizados

- **repositório pai** — branch `hotfix/corrigir-referencias-submodules`
  - 2 commits; 8 arquivos alterados
  - Atualiza `.ai`, `app-ai-assistants`, `prj-estacio-rstudio-jupyter` e registra `prj-estacio-despesas-pessoais`.

## Checklist

- [x] Referências dos submodules apontam para commits existentes nos remotes
- [x] Bootstrap validado localmente sem erro de referência
- [x] Commits incluem `Refs: #17`
- [ ] Revisão funcional
- [ ] Validação em ambiente Linux/jail

## Commits

- `chore: iniciar feature hotfix/corrigir-referencias-submodules`
- `docs(backlog): documentar hotfix de submodules`
