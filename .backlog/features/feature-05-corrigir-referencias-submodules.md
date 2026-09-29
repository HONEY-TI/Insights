---
name: feature-05-corrigir-referencias-submodules
file: feature-05-corrigir-referencias-submodules.md
description: >
  Corrigir referências inválidas e cadastrar o submodule de despesas pessoais.
---

## Contexto / Problema

O bootstrap falhava ao buscar commits de submodules que não existem mais nos repositórios remotos.

## Objetivo

Manter os ponteiros de submodules válidos localmente e em clones remotos do repositório.

## Critérios de aceite

- [ ] O bootstrap inicializa todos os submodules sem erro de referência.
- [ ] Os ponteiros registrados existem nos respectivos remotes.
- [ ] O novo submodule de despesas pessoais está registrado em `projects/`.
