# 🛠️ Conhecimento — Recuperação de Repositórios Git

## 📌 Objetivo

Definir procedimentos para recuperação de repositórios Git e submodules em estados inconsistentes, corrompidos ou parcialmente inicializados.

---

# 🚨 Cenários de Falha

Este processo cobre situações como:

- submodule não inicializa corretamente
- `.gitmodules` inconsistente
- índice corrompido
- referências quebradas em `.git/modules`
- repositório clonado sem submodules
- erro de commit incompleto

---

# 🔄 Recuperação Padrão

## 1️⃣ Re-sincronizar submodules

```bash
git submodule sync --recursive
```

---

## 2️⃣ Inicializar corretamente

```bash
git submodule update --init --recursive
```

---

## 3️⃣ Forçar atualização remota

```bash
git submodule update --remote --recursive
```

---

# 🔥 Recuperação Total (estado crítico)

Usar quando o estado está inconsistente ou quebrado:

```bash
git submodule deinit -f --all
rm -rf .git/modules/*
git submodule update --init --recursive
```

---

# ⚠️ Caso extremo (reset completo)

Quando nada funciona:

```bash
rm -rf .git
git init
git remote add origin <repo>
git fetch
git checkout -f main
git submodule update --init --recursive
```

---

# 🧠 Regras de Ouro

- Submodule nunca deve ser tratado como pasta comum
- Sempre sincronizar antes de operar
- `.gitmodules` é fonte de verdade estrutural
- `.git/modules` é estado interno crítico

---

# 🔗 Relacionados

- `operations/ciclo-vida-submodules-git.md`
- `knowledge/procedimentos-limpeza-submodules.md`