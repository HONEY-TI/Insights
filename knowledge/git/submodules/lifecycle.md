---
name: lifecycle
description: Define o ciclo operacional de gerenciamento de submodules Git dentro do workspace Insights.
---

# ⚙️ Operações — Ciclo de Vida dos Submodules Git

## 📌 Escopo

Ciclo operacional dos submodules dentro de `/projects`.

---

## 🔗 Relacionados

# 🔗 Relacionados

- [Sub Modules Integration Project](/knowledge/git/integration-project.md)
- [Sub Modules Clean Up](/knowledge/git/submodules/cleanup.md)
 
---

## 🔄 Etapas do Ciclo

1. Adicionar submodule
2. Inicializar submodule
3. Sincronizar submodule
4. Atualizar submodule
5. Remover ou recriar submodule

---

## 📌 Adicionar

```bash
git submodule add <repo> projects/<nome>
```

---

## 📌 Atualizar

```bash
git submodule update --remote --recursive
```

---

## 📌 Sincronizar

```bash
git submodule sync
```