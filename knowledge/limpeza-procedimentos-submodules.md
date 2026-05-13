# 🧹 Conhecimento — Procedimentos de Limpeza de Submodules Git

## 📌 Contexto do Problema

Um submodule pode ficar inconsistente quando:
- `.gitmodules` é modificado sem commit
- o índice ainda mantém referência antiga
- a pasta existe parcialmente
- há desalinhamento entre estado local e remoto

---

## ⚠️ Fluxo Padrão de Limpeza

### 1️⃣ Remover do índice

```bash
git rm --cached projects/<modulo>
```

---

### 2️⃣ Adicionar alterações do .gitmodules

```bash
git add .gitmodules
```

---

### 3️⃣ Remover metadados internos

```bash
rm -rf .git/modules/projects/<modulo>
```

---

### 4️⃣ Commit da limpeza

```bash
git commit -m "limpeza de submodule"
```

---

## 🔥 Reset Completo (Recuperação Total)

```bash
git submodule deinit -f projects/<modulo>
git rm -f projects/<modulo>
rm -rf .git/modules/projects/<modulo>
```

---

## ⚠️ Problemas com sudo

Se houver corrupção por uso de `sudo`:

```bash
sudo chown -R $USER:$USER .git
```

---

## 🔗 Relacionados

- `operations/ciclo-vida-submodules-git.md`
- `knowledge/integracao-submodules-git-projetos.md`
- `knowledge/troubleshooting-submodules-git.md`