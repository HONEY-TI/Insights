---
name: jail-initial-configurations
description: Instalar JailKit e compartilhar Jail com novos usuário adicionados a JailKit.
---

# 🎯 Configurações JailKit

## 🚀 1 . Instalar Jailkit


*  ### Comando de instalação no bash
```bash
sudo apt update
sudo apt install jailkit
```

* ### 🔎 Verificar se Jail foi instalada 
```bash
sudo jk_list
```

## 🧰 2. Criar estrutura base da jail

* ### ⚙️ Criar pasta de configuração Jail
```bash
sudo mkdir -p /home/jail
```
* ### ⚙️ Adicionar Programas na Jail 
```bash
sudo jk_init -v -j jail basicshell  jk_chrootsh  uidbasics editors  extendedshell python  jk_lsh interactiveshell xauth netutils ssh  git
```
* ### ⚙️ Copiar jk_chrootsh para Jail
```bash
sudo cp -r /usr/sbin/jk_chrootsh /home/jail/usr/sbin
```

* ### ⚙️ Remover Acesso de grupo root a Jail
```bash
sudo chmod 750 /home/jail  
```

* ### ⚙️ Desfazer proibição de Acesso de grupo root a Jail
```bash
sudo chown root:root /home/jail
sudo chmod 755 /home/jail
```

## 🧰 4. Adicionar Mais Programas na Jail Compartilhada

### 🟢 Node.js
```bash
sudo jk_cp -j /home/jail $(which node)
```

### 📦 NPM
```bash
sudo jk_cp -j /home/jail $(which npm)
```

### ✍️ Nano
```bash
sudo jk_cp -j /home/jail $(which nano)
```
### ✍️ Git
```bash
sudo jk_cp -j /home/jail $(which git)
```
```bash
#wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
```
```bash
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
```

```bash
git-credential-manager configure
```

```bash
sudo git config --system credential.helper manager
```

```bash
git credential-manager github login
```

```bash
git config --global user.name "Alex Ribeiro de Faria"
git config --global user.email "135660435+alexribeirofaria@github.com"
```

```
### ✍️ Antigravity
```bash
sudo jk_cp -j /home/jail $(which antigravity)
```

### ✍️ vscode
```bash
sudo jk_cp -j /home/jail $(which code)
```

### ✍️ Angular
```bash
sudo jk_cp -j /home/jail $(which ng)
```

## 👤👤 Criar Grupo jailusers

```bash
 sudo groupadd jailusers
``` 

## 📁 Criar Pasta home 
```bash
sudo mkdir -p /home/jail/home
```

*  ## Definição de variavés 
´´´bash
USER="jail" 
GROUP="jailusers"
´´´ 

# 🧨 Como evitar “exclusão acidental de estrutura”

> O risco de delete vem do diretório pai.
## ✔ sticky bit (controle de remoção em diretórios compartilhados)
```bash 
sudo chmod +t /home/$USER/workspace

```

## 📁 Criar Link da Pasta workspace em Jail 
```bash
# Criar pasta real na Jail

sudo chown -R $USER:$GROUP /home/$USER/workspace 
sudo chmod +t /home/$USER/workspace
sudo mkdir -p /home/jail/workspace
sudo chown -R $USER:$GROUP /home/jail/workspace 
# Bind mount

sudo mount --bind /home/$USER/workspace /home/jail/workspace
x
# Permissões seguras para DEV
sudo chmod -R u=rwX,g=rwX,o=  /home/$USER/workspace
```



### 📁 Criar Link da Pasta shared-documents em Jail 
```bash
# Criar pasta real na Jail
sudo mkdir -p /home/jail/documentos
sudo chown -R $USER$:$GROUP /home/jail/documentos 
# Bind mount
sudo mkdir -p /home/$USER/shared-documents
sudo chmod +t /home/$USER/shared-documents
sudo chown -R $USER:$GROUP /home/$USER/shared-documents 
sudo chmod -R u=rwX,g=rwX,o=  /home/$USER/shared-documents 
sudo mount --bind /home/$USER/shared-documents /home/jail/documentos
```

### 📁 Criar Link de configurações da extensions do .vscode em Jail 

```bash

# Criar pasta real na Jail
sudo mkdir -p /home/jail/.vscode/extensions
sudo cp -r /home//$USER/.vscode/extensions/* /home/jail/.vscode/extensions/
sudo chown -R root:$GROUP /home/jail/.vscode
sudo chown -R root:$GROUP /home/jail/.vscode/extensions
sudo chmod -R u=rwX,g=rwX,o=  /home/jail/.vscode
sudo chmod -R u=rwX,g=rwX,o=  /home/jail/.vscode/extensions
sudo chmod +t /home/jail/.vscode/extensions
sudo chmod +t /home/jail/.vscode
sudo find /home/jail/.vscode/extensions -type d -exec chown root:$GROUP {} \; -exec chmod 1770 {} \;
sudo find /home/jail/.vscode/extensions -type f -exec chown root:$GROUP {} \; -exec chmod 660 {} \;
```

### 📁 Criar Link de configurações da extensions do .antigravity em Jail 

```bash

# Criar pasta real na Jail
sudo mkdir -p /home/jail/.antigravity/extensions
sudo cp -r /home//$USER/.antigravity/extensions/* /home/jail/.antigravity/extensions/
sudo chown -R root:$GROUP /home/jail/.antigravity
sudo chown -R root:$GROUP /home/jail/.antigravity/extensions
sudo chmod -R u=rwX,g=rwX,o=  /home/jail/.antigravity
sudo chmod -R u=rwX,g=rwX,o=  /home/jail/.antigravity/extensions
sudo chmod +t /home/jail/.antigravity/extensions
sudo chmod +t /home/jail/.antigravity
sudo find /home/jail/.antigravity/extensions -type d -exec chown root:$GROUP {} \; -exec chmod 1770 {} \;
sudo find /home/jail/.antigravity/extensions -type f -exec chown root:$GROUP {} \; -exec chmod 660 {} \;
```


## 🚀  Método mais seguro (ACL – recomendado em sistemas multiusuário)

   1. Definir permissões base
```bash 
sudo setfacl -R -m u:$USER:rwx,g:$GROUP:rwx /home/jail/documentos
sudo setfacl -R -m u:$USER:rwx,g:$GROUP:rwx /home/jail/workspace
sudo setfacl -R -m u:$USER:rwx,g:$GROUP:rwx /home/jail/.vscode
sudo setfacl -R -m u:$USER:rwx,g:$GROUP:rwx /home/jail/.antigravity
```

   2. Definir herança para novos arquivos (CRÍTICO)
```bash 
sudo setfacl -d -m u:$USER:rwx,g:$GROUP:rwx /home/jail/documentos
sudo setfacl -d -m u:$USER:rwx,g:$GROUP:rwx /home/jail/workspace
sudo setfacl -d -m u:$USER:rwx,g:$GROUP:rwx /home/jail/.vscode
sudo setfacl -d -m u:$USER:rwx,g:$GROUP:rwx /home/jail/.antigravity
``` 


# 🗂️ Estrutura Esperada

```text
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
     sudo create-jail-user carlos.noeh
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
/home/jail/home/carlos-noeh
```

---

# 🧪 6. Testar Login

## 🖥️ Login local

```bash
su - carlos-.noeh
```

---


# ✅ Validar Restrição

Após login:

```bash
pwd
```

Resultado esperado:

```text
/home/carlos-noeh
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
      ├── carlos-noeh
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
cat /etc/passwd | grep carlos.noeh
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
carlos.noeh carlos.noeh
```

ou permissões:

```text
777
```

---


# 📌 Resumo Final

| Item | Valor |
|---|---|
| 👤 Usuário | `carlos.noeh` |
| 🔒 Jail Compartilhada | `/home/jail` |
| 🏠 Home Interna | `/home/jail/home/carlos.noeh` |
| 👥 Compartilha estrutura com outros usuários | ✅ |
| 📁 Compartilha arquivos pessoais | ❌ |
| 🛡️ Isolamento via Chroot | ✅ |



