---
name: jail-initial-configurations
description: Instalar JailKit e compartilhar Jail com novos usuário adicionados a JailKit.
---

# 🎯 Objetivo - Configurações JailKit

# 🔗 Relacionados

- [Configurações de Workspace Compartilhado](./foldres-ownership-enforcer.md)

## 🚀 1 . Instalar Jailkit

*  ### Comando de instalação no bash
```bash
sudo apt update
sudo apt install jailkit
```

* ### 🔎 Verificar se Jail foi instalada 
```bash
which jk_list
```

## 🧰 2. Criar estrutura base da jail

* ### ⚙️ Criar pasta de configuração Jail
```bash
sudo mkdir -p /jail
sudo chown root:root /jail
sudo chmod 700 /jail
```

* ### ⚙️ Adicionar Programas na Jail 
```bash
sudo jk_init -v -j jail basicshell jk_lsh uidbasics editors  git
```

## 🧰 Adicionar Mais Programas na Jail Compartilhada

### 🟢 Node.js
```bash
sudo jk_cp -j /jail $(which node)
```

### 📦 NPM
```bash
sudo jk_cp -j /jail $(which npm)
```

### ✍️ Nano
```bash
sudo jk_cp -j /jail $(which nano)
```
### ✍️ Git Credential usando gh 
```bash
sudo jk_cp -j /jail $(which gh)
```

```bash
gh auth login
```

```bash
git config --global user.name "Alex Ribeiro de Faria"
git config --global user.email "135660435+alexribeirofaria@github.com"
```

### ✍️ Antigravity
```bash
sudo jk_cp -j /jail $(which antigravity)
```

### ✍️ vscode
```bash
sudo jk_cp -j /jail $(which code)
```

### ✍️ Angular
```bash
sudo jk_cp -j /jail $(which ng)


### ✍️ Docker
```bash
# copiar usando jailkit
sudo jk_cp -j /jail $(which docker)


```

### ✍️ Pandoc Usuario pela IA para manipular arquivos .doc, odcx
```bash
# copiar usando jailkit
sudo jk_cp -j /jail $(which pandoc)

# ou copiar manualmente
sudo cp -a $(which pandoc) /home/jail/$(which pandoc)
```

## 👤👤 Criar Grupo jailusers

```bash
#  Definição de variavés 
SKELL_USER="alexf"
USER="jail" 
GROUP="jailusers"
```

```bash
 sudo groupadd $GROUP
 sudo usermod -aG $GROUP $USER
``` 

## 📁 Criar Estrutura de Pastas 
```bash
# home
sudo mkdir -p /home/$GROUP/home
sudo chown -R root:$GROUP /home/$GROUP/home


# workspace
sudo mkdir -p /home/$USER/workspace
sudo chown -R $USER:$GROUP /home/$USER/workspace
sudo chmod 2775 /home/$USER/workspace

# documentos
sudo mkdir -p /home/$SKELL_USER/shared-documents
sudo chmod +t /home/$SKELL_USER/shared-documents
sudo mkdir -p /home/$USER/documentos

# .vscode/extensions
sudo mkdir -p /home/$USER/.vscode/extensions
sudo cp -r /home/$SKELL_USER/.vscode/extensions/* /home/jail/.vscode/extensions/
sudo chmod +t /home/jail/.vscode/extensions/

# .antigravity/extensions
sudo mkdir -p /home/$USER/.antigravity/extensions
sudo cp -r /home/$SKELL_USER/.antigravity/extensions/* /home/jail/.antigravity/extensions
sudo chmod +t /home/jail/.antigravity/extensions
``` 

# 🧨 Garantir pastas compartilhadas utilizando bindfs, ACL e setgid


## 🔐 Configurar ACL padrão

### Permissões automáticas para novos arquivos

```bash
# workspace
sudo setfacl -R -m d:u:$USER:rwx /home/$USER/workspace
sudo setfacl -R -m d:g:$GROUP:rwx /home/$USER/workspace

# documentos
sudo setfacl -R -m d:u:$USER:rwx /home/$USER/documentos
sudo setfacl -R -m d:g:$GROUP:rwx /home/$USER/documentos

# .vscode/extensions
sudo setfacl -R -m d:u:$USER:rwx /home/$USER/.vscode/extensions/
sudo setfacl -R -m d:g:$GROUP:rwx /home/$USER/.vscode/extensions/


# .antigravity/extensions
sudo setfacl -R -m d:u:$USER:rwx /home/$USER/.antigravity/
sudo setfacl -R -m d:g:$GROUP:rwx /home/$USER/.antigravity/
```

## 🔄 Montagem com bindfs

### Montar forçando owner e grupo

```bash
# workspace
sudo bindfs --force-user=$USER$--force-group=$GROUP  /home/$USER/workspace /home/$USER/workspace

# documentos
sudo bindfs --force-user=$USER$--force-group=$GROUP  /home/$USER/documentos /home/$USER/documentos

# .vscode/extensions
sudo bindfs --force-user=$USER$--force-group=$GROUP /home/$USER/.vscode/extensions/ /home/$USER/.vscode/extensions/

# .antigravity/extensions
sudo bindfs --force-user=$USER$--force-group=$GROUP  /home/$USER/.antigravity/ /home/$USER/.antigravity/
```

---


# 🗂️ Estrutura Esperada

```bash
/home/jail
 ├── .antigravity
 ├── .vscode 
 ├── bin -> usr/bin
 ├── dev
 ├── documentos
 ├── etc
 ├── home 
 ├── lib -> usr/lib
 ├── lib64 -> usr/lib64
 ├── run
 ├── usr
 └── workspace
```

---

# 👤 Criar Novo Usuário

```bash
     sudo create-jail-user noeh
```

##  ✅ O comando faz automaticamente

- 📁 Cria home interna
- 🔒 Configura chroot
- 🛡️ Ajusta permissões
- ⚙️ Configura shell
- 🧱 Integra o usuário na jail existente

---

# 🏠 4. Home Criada Automaticamente

```text
/home/jail/home/noeh
```

---

# 🧪 6. Testar Login

## 🖥️ Login local

```bash
su - noeh
```

---


# ✅ Validar Restrição

Após login:

```bash
pwd
```

Resultado esperado:

```text
/home/noeh
```

---

# 🔒 O usuário estará preso em

```text
/home/jail
```

---

# 👥 Exemplo com Múltiplos Usuários

```text
/home/jail
 └── home
      ├── noeh
      ├── maria
      └── joao
```

Todos compartilham:

- 📚 libs
- ⚙️ comandos
- 🐚 shell
- 🧱 estrutura

Mas cada um possui sua própria home.

---

# 🔍 Verificar Home do Usuário

```bash
cat /etc/passwd | grep noeh
```

---

# 🛡️ Validar Permissões da Jail

## ⚠️ Diretório raiz NÃO pode ser do usuário

---

## ✅ Correto

```bash
ls -ld /home/jail
```

Resultado esperado:

```text
drwxr-xr-x root root
```

---

# ❌ ERRADO

```text
noeh noeh
```

ou permissões:

```text
777
```

---


# 📌 Resumo Final

| Item | Valor |
|---|---|
| 👤 Usuário | `noeh` |
| 🔒 Jail Compartilhada | `/home/jail` |
| 🏠 Home Interna | `/home/jail/home/noeh` |
| 👥 Compartilha estrutura com outros usuários | ✅ |
| 📁 Compartilha arquivos pessoais | ❌ |
| 🛡️ Isolamento via da Jail | ✅ |



