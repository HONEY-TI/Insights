---
name: jail-configurations
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


* ### ⚙️ Adicionar Programas na Jail 
```bash
sudo jk_init -v -j /home/jail basicshell jk_lsh uidbasics editors git xauth
```

* ### 🧱 Correção de Jail Mal Montado (Jailkit)

> obs.: É preciso fazer mais teste e garntir ganho de perfornce sem quebar a jail 
Este guia corrige problemas comuns em jail usando o Jailkit (Linux chroot/jail environment tool), especialmente falta de `/proc`, `/dev`, `/dev/pts` e `/sys`.

---

#### ⚠️ Importante

- `/proc` e `/dev` são essenciais para o funcionalsento correto do jail.
- `/sys` é opcional e geralmente não recomendado.
- Jail mal montado pode causar:
  - lentidão geral
  - travamentos em comandos (git, node, ssh)
  - falhas de rede e DNS

#### 🧱 1. Montar /proc (OBRIGATÓRIO)
```bash
sudo mount -t proc proc /home/jail/proc
```

#### 🔌 2. Montar /dev (OBRIGATÓRIO)
```bash
sudo mount --bind /dev /home/jail/dev
```
#### 🧵 3. Montar /dev/pts (IMPORTANTE)
```bash
sudo mount --bind /dev/pts /home/jail/dev/pts
```
#### 🌐 4. Montar /sys (OPCIONAL)
```bash
sudo mount --bind /sys /home/jail/sys
```

## 🔁 5. Tornar persistente os mout mesmo após reebot (fstab)

**Obs.:** O uso aqui não é a melhor solução sendo o uso correto de script e serviço 
> Edite /etc/fstab:
```bash
/proc     /home/jail/proc      proc    defaults,nofail        0 0
/dev      /home/jail/dev       none    bind,nofail            0 0
/dev/pts  /home/jail/dev/pts   none    bind,nofail            0 0
/sys      /home/jail/sys       none    bind,nofail            0 0
```


## 🧪 6. Teste dentro do jail
```bash
ls /proc
cat /proc/cpuinfo
ls /dev
ls /sys
```
---

## 7. Criar arquivo contendo usuários pertencentes a jail  `jail-users.list`
```bash
echo  ""  >  /home/jail/etc/jail-users.list
```
### 🌐 DNS dentro da jailcl
```bash
sudo tee /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
```



## 🧰 Adicionar Mais Programas na Jail Compartilhada

### 🟢 Node.js
```bash
sudo jk_cp -j /home/jail $(which node)
```

### 📦 NPM
```bash
sudo jk_cp -j /home/jail $(which npm)
```

### ✍️ Git Credential usando gh 
```bash
sudo jk_cp -j /home/jail $(which gh)
```

### Garantir persistência do mesmo usuário git para todos
```bash
gh auth login
```

```bash
git config --global user.name "Alex Ribeiro de Faria"
git config --global user.email "135660435+alexribeirofaria@github.com"
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


### ✍️ Docker
```bash
# copiar usando jailkit
sudo jk_cp -j /home/jail $(which docker)
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
USER="root" 
GROUP="jailusers"
```

```bash
 sudo groupadd $GROUP
 sudo usermod -aG $GROUP $USER
``` 

## 📁 Criar Estrutura de Pastas 
```bash
# home
sudo mkdir -p /home/jail/home
sudo chown -R root:root /home/jail/home


# workspace
sudo mkdir -p /home/$USER/workspace
sudo chown -R $USER:$GROUP /home/$USER/workspace
sudo chmod 2775 /home/$USER/workspace

# documentos
sudo mkdir -p /shared-documents
sudo chmod +t /shared-documents
sudo mkdir -p /home/$USER/Documentos
```

## 🔄 Montagem com bindfs

### Montar forçando owner e grupo

```bash
# workspace
sudo bindfs --force-user=$USER_ORG --force-group=$GROUP  /home/$USER_ORG/workspace /home/$USER_DEST/workspace

# documentos
sudo bindfs --force-user=$USER_ORG --force-group=$GROUP  /home/$USER_ORG/documentos /home/$USER_DEST/documentos
```

### Cirando serviço para persistir montagem após reboot
```bash 
#!/usr/bin/env bash
set -euo pipefail

readonly USER_ORG="alexf"
readonly USER_DEST="alex"
readonly GROUP_DEFAULT="grp-alex"

# =========================================================
# 🧱 MOUNTS FIXOS
# =========================================================
declare -a MOUNTS=(
    "/home/$USER_ORG/.workspace:/home/$USER_DEST/.workspace:$USER_DEST"
    "/home/$USER_ORG/Documentos:/home/$USER_DEST/Documentos:$USER_DEST"
    "/home/$USER_ORG/.virtual-vms:/home/$USER_DEST/.virtual-vms:$USER_DEST"

    "/home/shared-documents:/home/jail/Documentos:root:jailusers"
    "/home/$USER_DEST/.workspace:/home/jail/workspace:root:jailusers"
)

# =========================================================
# 📦 CARREGA USUÁRIOS DO JAIL
# =========================================================
JAIL_USERS=()

if [[ -f /home/jail/etc/jail-users.list ]]; then
    mapfile -t JAIL_USERS < /home/jail/etc/jail-users.list
fi

# =========================================================
# 🔗 MOUNT BASE
# =========================================================
mount_bindfs() {
    local source="$1"
    local target="$2"
    local force_user="${3:-$USER_ORG}"
    local force_group="${4:-$GROUP_DEFAULT}"

    mkdir -p "$target"

    if mountpoint -q "$target"; then
        return 0
    fi

    bindfs \
        --force-user="$force_user" \
        --force-group="$force_group" \
        "$source" \
        "$target"
}

# =========================================================
# 🔒 JAIL USERS MOUNTS
# =========================================================
mount_bindfs_jail() {
    local SHARED_DOCUMENTS="/home/jail/Documentos"
    local SHARED_WORKSPACE="/home/jail/workspace"

    for user in "${JAIL_USERS[@]}"; do
        local documents="/home/jail/home/$user/Documentos"
        local workspace="/home/jail/home/$user/workspace"

        chmod 2776 "$SHARED_DOCUMENTS" 2>/dev/null || true
        bindfs \
            --force-user="$user" \
            --force-group="$user" \
            "$SHARED_DOCUMENTS" \
            "$documents" || true
        chmod 2776 "$documents" 2>/dev/null || true

        chmod 2776 "$SHARED_WORKSPACE" 2>/dev/null || true
        bindfs \
            --force-user="$user" \
            --force-group="$user" \
            "$SHARED_WORKSPACE" \
            "$workspace" || true
        chmod 2776 "$workspace" 2>/dev/null || true
    done
}

# =========================================================
# 🚀 EXECUÇÃO
# =========================================================

for mount_def in "${MOUNTS[@]}"; do
    IFS=':' read -r source target user group <<< "$mount_def"

    mount_bindfs "$source" "$target" "$user" "$group"
done

mount_bindfs_jail
``` 

```bash 
#sudo nano /etc/systemd/system/jail-mounts.service
[Unit]
Description=Jail BindFS Mounts
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/jail-mounts.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

``` 

```bash
# Ative:

sudo systemctl daemon-reload
sudo systemctl enable jail-mounts.service
sudo systemctl start jail-mounts.service
```
```bash
# Verifique:

systemctl status jail-mounts.service
```
---


# 📌 Resumo Final

| Item | Valor |
|---|---|
| 👤 Usuário | `dinamico criado dentro da jail permitindo compratilhamento de pastas gti e docker ` |
| 🔒 Jail Compartilhada | `/home/jail` |
| 🏠 Home Interna dos uiáriso | `/home/jail/home` |
| 👥 Compartilha estrutura com outros usuários | ✅ |
| 📁 Compartilha arquivos pessoais | ❌ |
| 🛡️ Isolamento via da Jail | ✅ |



