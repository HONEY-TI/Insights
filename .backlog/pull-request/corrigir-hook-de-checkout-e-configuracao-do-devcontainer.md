---
name: corrigir-hook-de-checkout-e-configuracao-do-devcontainer
pr: 18
title: "PR(#18)-Corrigir hook de checkout e configuração do Dev Container"
branch: feature/corrigir-hook-de-checkout-e-configuracao-do-dev
base: main
extends: feature-06-corrigir-hook-de-checkout-e-configuracao-do-devcontainer
status: open
---

## 📋 Descrição

Implementação da correção do hook de checkout e da configuração do Dev Container, com commits
separados por arquivo.

Feature relacionada: `feature-06-corrigir-hook-de-checkout-e-configuracao-do-devcontainer.md`

## 📊 Estatísticas

| Métrica | Valor |
| --- | --- |
| Branch de origem | `feature/corrigir-hook-de-checkout-e-configuracao-do-dev` |
| Branch de destino | `main` |
| Total de commits | 15 de conteúdo |
| Arquivos alterados | 14 |
| Linhas adicionadas | 177 |
| Linhas removidas | 361 |

## Checklist

- [x] Commits separados por arquivo
- [x] Referência da PR incluída nos commits de conteúdo
- [x] Alterações revisadas e enviadas para a branch
- [ ] Revisão funcional
- [ ] Validação em ambiente Linux/jail

## 📝 Commits

- chore(raiz): remover licença duplicada `LICENSE.md` - [6809307](https://github.com/HONEY-TI/Insights/commit/6809307ff3c7a8adf19cf5f26c0cd28da81c3531)
- fix(raiz): atualizar referências de submódulos `.gitmodules` - [0156408](https://github.com/HONEY-TI/Insights/commit/015640853337b4fdbf831c5d3e36d4e959954389)
- fix(raiz): ajustar exclusões do workspace `.gitignore` - [663933d](https://github.com/HONEY-TI/Insights/commit/663933d01785d0fb120aedf1d262324bfb5f570a)
- fix(ci): tornar hook seguro para submódulos `.github/hooks/post-checkout` - [e9d0a05](https://github.com/HONEY-TI/Insights/commit/e9d0a05f317356e43fc3fb7db229d768f00fcfcd)
- feat(ci): configurar atualizações automáticas `.github/dependabot.yml` - [ed35a71](https://github.com/HONEY-TI/Insights/commit/ed35a7113034286a308aa69be4d5524d7407e9f5)
- feat(docker): adicionar inicialização pós-container `.devcontainer/post-start.sh` - [9656937](https://github.com/HONEY-TI/Insights/commit/96569377b3755ad20a5da5959084e395048359c0)
- feat(docker): adicionar exemplo de variáveis `.devcontainer/.env .example` - [9678121](https://github.com/HONEY-TI/Insights/commit/9678121868c3b700a87fa8749bba3b8e56c2c372)
- chore(docker): remover instalador substituído `.devcontainer/setup-codex.sh` - [ca90891](https://github.com/HONEY-TI/Insights/commit/ca9089118bf45cc6c82a483c3fa506c54ef60b9d)
- chore(docker): remover script obsoleto `.devcontainer/init-firewall.sh` - [c6db067](https://github.com/HONEY-TI/Insights/commit/c6db0675280555437725626b3ed4c9b2618b79e6)
- fix(docker): ajustar inicialização do container `.devcontainer/docker-entrypoint.sh` - [d6f7a85](https://github.com/HONEY-TI/Insights/commit/d6f7a8508caf23fce7bb18f06792a4a2120183a4)
- fix(docker): atualizar serviços do ambiente `.devcontainer/docker-compose.yml` - [0a570bb](https://github.com/HONEY-TI/Insights/commit/0a570bb2a3026e0ea0761a76befa202d1729bfc9)
- fix(config): ajustar configuração do Dev Container `.devcontainer/devcontainer.json` - [12375e7](https://github.com/HONEY-TI/Insights/commit/12375e706e5038bb4830b28b7b19fda3d3bfd42b)
- fix(docker): atualizar imagem do Dev Container `.devcontainer/Dockerfile` - [1888bbd](https://github.com/HONEY-TI/Insights/commit/1888bbdfe2692a94d5419e733ac43386570c4530)
- feat(docs): registrar PR da correção `.backlog/pull-request/corrigir-hook-de-checkout-e-configuracao-do-devcontainer.md` - [f2f2ebf](https://github.com/HONEY-TI/Insights/commit/f2f2ebf0c421253462cff30318e1d2e9eab73580)
- feat(docs): documentar correção do hook `.backlog/features/feature-06-corrigir-hook-de-checkout-e-configuracao-do-devcontainer.md` - [4b9c757](https://github.com/HONEY-TI/Insights/commit/4b9c757a9e5d16f4b740e29ecf336237dac10314)
