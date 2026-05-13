# 📘 Playbook — Limpeza de Submodule Git

## 🎯 Objetivo

Remover completamente um submodule quebrado ou inconsistente e restaurar o estado limpo do repositório.

---

# 🚨 Quando usar

- erro `fatal: please stage your changes`
- submodule não responde
- `.gitmodules` inconsistente
- índice corrompido
- falha de sync ou init

---

# 🧠 Diagnóstico inicial

```bash
git status
git submodule status
```

---

# 🧹 Execução passo a passo

## 1️⃣ Remover do índice

```bash
git rm --cached projects/<modulo>
```

---

## 2️⃣ Garantir estado do .gitmodules

```bash
git add .gitmodules
```

---

## 3️⃣ Remover estado interno

```bash
rm -rf .git/modules/projects/<modulo>
```

---

## 4️⃣ Remover diretório local (opcional)

```bash
rm -rf projects/<modulo>
```

---

## 5️⃣ Consolidar estado

```bash
git commit -m "cleanup submodule: restore consistency"
```

---

# 🔥 Modo crítico (reset total do submodule)

```bash
git submodule deinit -f projects/<modulo>
git rm -f projects/<modulo>
rm -rf .git/modules/projects/<modulo>
```

---

# ⚠️ Validação final

```bash
git submodule sync
git submodule update --init --recursive
```

---

# 🧠 Resultado esperado

- índice limpo
- submodule removido corretamente
- `.gitmodules` consistente
- workspace reutilizável

---

# 🔗 Relacionados

- `knowledge/procedimentos-limpeza-submodules.md`
- `knowledge/troubleshooting-submodules-git.md`