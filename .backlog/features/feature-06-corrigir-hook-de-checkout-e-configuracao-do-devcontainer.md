---
name: feature-06-corrigir-hook-de-checkout-e-configuracao-do-devcontainer
file: feature-06-corrigir-hook-de-checkout-e-configuracao-do-devcontainer.md
description: >
  Corrigir o hook de checkout e consolidar ajustes do ambiente Dev Container.
---

## Contexto / Problema

O hook `post-checkout` executava um bootstrap mutável automaticamente durante cada checkout,
podendo alterar o estado local e os ponteiros de submódulos sem uma ação explícita.

## Objetivo

Tornar o hook seguro e garantir que a configuração do ambiente e dos submódulos permaneça
previsível durante operações Git.

## Critérios de aceite

- [ ] O hook inicializa submódulos sem executar rotinas mutáveis de bootstrap.
- [ ] A configuração do Dev Container permanece consistente.
- [ ] As alterações são rastreáveis em commits individuais por arquivo.
