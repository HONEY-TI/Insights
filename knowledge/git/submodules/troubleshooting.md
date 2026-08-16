---
name: troubleshooting-submodules
description: Soluções para inconsistências, conflitos e erros operacionais relacionados a submodules Git.
---

# 🚨 Conhecimento — Troubleshooting de Submodules Git

## 🔗 Relacionados

## 🔗 Relacionados

- [Git Integration Project](/knowledge/git/integration-project.md)
- [Sub Modules Life Cycle](/knowledge/git/submodules/lifecycle.md)
- [Sub Modules Procedimentos de Limpeza](/knowledge/git/submodules/cleanup.md)


## 📌 Erro

```bash
fatal: please stage your changes to .gitmodules or stash them to proceed
```

---

## 📌 Causa Raiz

O Git bloqueia operações quando:
- o arquivo `.gitmodules` está modificado e não foi commitado
- o índice está inconsistente com o estado atual

---

## ✅ Ordem de Correção

### 1️⃣ Stage do .gitmodules

```bash
git add .gitmodules
```

---

### 2️⃣ Remover submodule do índice

```bash
git rm -rf --cached projects/<modulo>
```

---

## ⚠️ Alternativa

```bash
git stash
```