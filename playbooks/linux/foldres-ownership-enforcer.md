---
name: foldres-ownership-enforcer
description: Configuração de workspace compartilhado no Linux utilizando bindfs, ACL e setgid para garantir que todos os arquivos e diretórios criados em /home/jail/workspace mantenham automaticamente o owner como 'jail' e o grupo como 'jailusers', independentemente do usuário que estiver manipulando os arquivos. Inclui instalação, configuração persistente via fstab, permissões herdadas, ACLs padrão, testes, troubleshooting e gerenciamento multiusuário.

---

# 📁 Configuração de Workspace Compartilhado

## 🎯 Objetivo


# 🚀 Solução Recomendada (bindfs)

O Linux não permite forçar automaticamente o *owner* real de arquivos apenas com `chmod`/`setfacl` nem herenaça recursiva sem alteração de permissionamento .

A solução mais limpa e profissional é utilizar:

## 🔧 bindfs

Ele força visualmente e funcionalmente:

- owner = `jail`
- group = `jailusers`

independentemente do usuário que criou o arquivo.

---

# 📦 Instalação

## Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y bindfs acl
```

# 🔄 Montagem com bindfs

## Montar forçando owner e grupo manualmente

> É necessário o uso de montagem usando serviços para persisntir após reboot 

```bash
sudo bindfs --force-user=alexf --force-group=grp-alex /home/alexf/Documentos /home/alex/Documentos
sudo bindfs --force-user=alexf --force-group=grp-alex /home/alexf/.workspace  /home/alex/.workspace

SOURCE_DIR="/home/alex/.workspace"
TARGET_DIR="/jail/workspace"

[ -d "$SOURCE_DIR" ] || sudo mkdir -p "$SOURCE_DIR"
[ -d "$TARGET_DIR" ] || sudo mkdir -p "$TARGET_DIR"

sudo bindfs \
    --force-user=root \
    --force-group=jailusers \
    "$SOURCE_DIR" \
    "$TARGET_DIR"

sudo bindfs \
  --force-user=alex \
  --force-group=vboxusers \
  /home/alexf/.virtual-vms  \
  /home/alex/.virtual-vms 
```

---

# ✅ Resultado

Qualquer usuário poderá:

- criar arquivos
- editar
- mover
- remover

Mas os arquivos sempre aparecerão como:

```bash
owner  => root
group  => jailusers
```

---

# 💾 Persistir Após Reiniciar

## Configuração ACL
```bash 
sudo setfacl -R -m u:alexf:rwx /home/alexf/.workspace
sudo setfacl -R -m u:alexf:rwx /home/alexf/Documentos
sudo setfacl -R -m u:alexf:rwx /home/alexf/.virtual-vms

sudo setfacl -R -d -m u:alexf:rwx /home/alexf/.workspace
sudo setfacl -R -d -m u:alexf:rwx /home/alexf/Documentos
sudo setfacl -R -d -m u:alexf:rwx /home/alexf/.virtual-vms
```

## Criar arquivo `sudo nano /usr/local/bin/jail-mounts.sh` 

```bash 
#!/bin/bash

USER_ORG="alexf"
USER_DEST="alex"

if [ ! -d "/home/$USER_DEST/.workspace" ]; then
    mkdir -p "/home/$USER_DEST/.workspace"
fi

if [ ! -d "/home/$USER_DEST/Documentos" ]; then
    mkdir -p "/home/$USER_DEST/Documentos"
fi

if [ ! -d "/home/$USER_DEST/.virtual-vms" ]; then
    mkdir -p "/home/$USER_DEST/.virtual-vms"
fi


mount_bindfs() {
    local source="$1"    
    local target="$2"

    if ! mountpoint -q "$target"; then
        bindfs \
            --force-user="$USER_ORG" \
            "$source" \
            "$target"
    fi
}


mount_bindfs "/home/$USER_ORG/.workspace " "/home/$USER_DEST/.workspace"
mount_bindfs "/home/$USER_ORG/Documentos" "/home/$USER_DEST/Documentos"
mount_bindfs "/home/$USER_ORG/.virtual-vms" "/home/$USER_DEST/.virtual-vms"

```

## Permissões: `sudo chmod +x /usr/local/bin/jail-mounts.sh` 

## Criar Serviço `Serviço systemd` 
```bash 
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

## 🔁  Aplicar sem reiniciar
```bash
sudo systemctl daemon-reload
sudo systemctl enable jail-mounts.service
sudo systemctl start jail-mounts.service
```

## 🧪 Verifique: `systemctl status jail-mounts.service` 

---


# ✅ Conclusão

Esta configuração garante:

- 🔒 Padronização de ownership
- 👥 Compartilhamento multiusuário
- 📁 Herança automática de permissões
- ⚡ Controle centralizado
- 🛠️ Ambiente ideal para workspaces compartilhados
