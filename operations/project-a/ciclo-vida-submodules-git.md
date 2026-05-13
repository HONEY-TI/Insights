# ⚙️ Operações — Ciclo de Vida dos Submodules Git

## 📌 Escopo

Ciclo operacional dos submodules dentro de `/projects`.

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

---

## 🔗 Relacionados

- `knowledge/integracao-submodules-git-projetos.md`
- `knowledge/procedimentos-limpeza-submodules.md`