# 🚨 Conhecimento — Troubleshooting de Submodules Git

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

---

## 🔗 Relacionados

- `knowledge/procedimentos-limpeza-submodules.md`
- `operations/ciclo-vida-submodules-git.md`