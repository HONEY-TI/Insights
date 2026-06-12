---
name: foldres-ownership-enforcer
description: Configuração de workspace compartilhado no Linux utilizando bindfs, ACL e setgid para garantir que todos os arquivos e diretórios criados em /home/jail/workspace mantenham automaticamente o owner como 'jail' e o grupo como 'jailusers', independentemente do usuário que estiver manipulando os arquivos. Inclui instalação, configuração persistente via fstab, permissões herdadas, ACLs padrão, testes, troubleshooting e gerenciamento multiusuário.

---

# 📁 Configuração de Workspace Compartilhado

## 🎯 Objetivo

> Configurar ambiente isolado sem permissionamento de Agentes IA interagir com o SO :


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

> É necessário o uso de montagem usando serviços 

```bash
sudo bindfs \
  --force-user=alexf \
  --force-group=grp-alex \
  /home/alexf/Documentos \
  /home/alex/Documentos

sudo bindfs \
  --force-user=alex \
  --force-group=grp-alex \
  /home/alexf/.workspace  \
  /home/alex/.workspace 

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


# .vscode/extensions
sudo mkdir -p /jail/.vscode/extensions
sudo cp -r /home/alex/.workspace/.extensions/* /jail/.vscode/extensions/
sudo chmod +t /jail/.vscode/extensions/

# .antigravity/extensions
sudo mkdir -p /jail/.antigravity/extensions
sudo cp -r /home/alex/.workspace/.extensions/* /jail/.antigravity/extensions
sudo chmod +t /jail/.antigravity/extensions

# documentos do jail compartilhado com shared-documents
SOURCE_DIR="/home/shared-documents"
TARGET_DIR="/jail/Documentos"

[ -d "$SOURCE_DIR" ] || sudo mkdir -p "$SOURCE_DIR"
[ -d "$TARGET_DIR" ] || sudo mkdir -p "$TARGET_DIR"

sudo bindfs \
    --force-user=root \
    --force-group=jailusers \
    "$SOURCE_DIR" \
    "$TARGET_DIR"

# Criação de pasta home dos usuários 
sudo mkdir -p /jail/home
sudo chown root:jailusers /jail/home
sudo chmod 770 /jail/home

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

## Configurações possivés de estarem desatualiazdas
>  **Uso de bindfs para perssitir recursivamente configurações de permissionamento e compartilhamento**


## Editar `/etc/fstab`

```bash
sudo nano /etc/fstab
```

Adicionar:

```fstab
bindfs#/home/jail/workspace /home/jail/workspace fuse force-user=jail,force-group=jailusers,create-for-user=jail,create-for-group=jailusers 0 0
```

---

# 🔁 Aplicar sem reiniciar

```bash
sudo mount -a
```

---

# 🧪 Teste

## Criar arquivo com outro usuário

```bash
touch /home/jail/workspace/teste.txt
```

Verificar:

```bash
ls -l /home/jail/workspace
```

Resultado esperado:

```bash
-rw-r--r-- 1 jail jailusers teste.txt
```

---

# 🛡️ Observações Importantes

## 📌 Todos os usuários precisam pertencer ao grupo:

```bash
jailusers
```

Adicionar usuário ao grupo:

```bash
sudo usermod -aG jailusers NOME_USUARIO
```

Depois:

```bash
newgrp jailusers
```

ou relogar sessão.

---

# 🔥 Verificações úteis

## Ver ACL

```bash
getfacl /home/jail/workspace
```

---

## Ver montagem bindfs

```bash
mount | grep bindfs
```

---

# 🧹 Remover configuração bindfs

## Desmontar

```bash
sudo umount /home/jail/workspace
```

---

## Remover linha do fstab

Editar:

```bash
sudo nano /etc/fstab
```

Remover a linha do `bindfs`.

---

# ✅ Conclusão

Esta configuração garante:

- 🔒 Padronização de ownership
- 👥 Compartilhamento multiusuário
- 📁 Herança automática de permissões
- ⚡ Controle centralizado
- 🛠️ Ambiente ideal para workspaces compartilhados
