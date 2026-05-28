---
name: foldres-ownership-enforcer
description: Configuração de workspace compartilhado no Linux utilizando bindfs, ACL e setgid para garantir que todos os arquivos e diretórios criados em /home/jail/workspace mantenham automaticamente o owner como 'jail' e o grupo como 'jailusers', independentemente do usuário que estiver manipulando os arquivos. Inclui instalação, configuração persistente via fstab, permissões herdadas, ACLs padrão, testes, troubleshooting e gerenciamento multiusuário.

---

# 📁 Configuração de Workspace Compartilhado

## 🎯 Objetivo

Configurar a pasta:

```bash
/home/jail/workspace
```

Para que:

- ✅ Qualquer usuário possa criar, alterar e remover arquivos
- ✅ Todos os arquivos e pastas tenham sempre:
  - Usuário (owner): `jail`
  - Grupo: `jailusers`
- ✅ Funcione também em subpastas
- ✅ Novos arquivos herdem automaticamente as permissões corretas

---

# 🚀 Solução Recomendada (bindfs)

O Linux não permite forçar automaticamente o *owner* real de arquivos apenas com `chmod`/`setfacl`.

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

---

# 🛠️ Configuração Inicial

## 1️⃣ Ajustar dono da pasta

```bash
sudo chown -R jail:jailusers /home/jail/workspace
```

---

## 2️⃣ Aplicar permissões corretas

```bash
sudo chmod 2775 /home/jail/workspace
```

### 📌 Explicação

O `2` no início ativa o **setgid**, fazendo com que:

- todos os novos arquivos
- e subpastas

herdem automaticamente o grupo:

```bash
jailusers
```

---

## 3️⃣ Aplicar em todas subpastas

```bash
sudo find /home/jail/workspace -type d -exec chmod 2775 {} \;
```

---

# 🔐 Configurar ACL padrão

## Permissões automáticas para novos arquivos

```bash
sudo setfacl -R -m d:u:jail:rwx /home/jail/workspace
sudo setfacl -R -m d:g:jailusers:rwx /home/jail/workspace
```

---

## Aplicar permissões atuais

```bash
sudo setfacl -R -m u:jail:rwx /home/jail/workspace
sudo setfacl -R -m g:jailusers:rwx /home/jail/workspace
```

---

# 🔄 Montagem com bindfs

## Montar forçando owner e grupo

```bash
sudo bindfs \
  --force-user=jail \
  --force-group=jailusers \
  /home/jail/workspace \
  /home/jail/workspace
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
owner  => jail
group  => jailusers
```

---

# 💾 Persistir Após Reiniciar

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
