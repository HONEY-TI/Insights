---
name: remove-submodule
description: Remove completamente um submódulo Git incluindo deinit, remoção do index e limpeza do cache interno do Git.
---

# 🧹 Remover Submódulo Git

## 📌 Visão Geral

Este processo remove completamente um submódulo Git do repositório principal, incluindo:

* 🔌 desinicialização do submódulo
* 🗑️ remoção do index do Git
* 🧼 limpeza do cache interno de módulos do Git
* 🔗 remoção das referências internas do submodule

---

# 🚀 Comandos

## 1️⃣ Desinicializar o submódulo

Remove o registro local do submódulo da configuração do Git.

Deve esta na pasta raiz do projeto  
```bash 
cd /Insights
```

```bash
git submodule deinit -f projects/project-a
```

---

## 2️⃣ Remover o submódulo do index do Git

Remove a referência do submódulo do repositório principal.

```bash
git rm -f projects/project-a
```

---

## 3️⃣ Limpar cache interno de módulos do Git

Remove referências internas armazenadas em `.git/modules`.

```bash
rm -rf .git/modules/projects/project-a
```

---

# ✅ Resultado Esperado

Após executar os comandos:

* ✅ o submódulo será removido do repositório
* ✅ o `.gitmodules` será atualizado
* ✅ o cache interno do Git será limpo
* ✅ o repositório deixará de rastrear o submódulo

---

# 🔍 Validação Recomendada

Verifique se o submódulo foi removido corretamente:

```bash
git
```
