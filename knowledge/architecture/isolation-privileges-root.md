---
name: isolation-privileges-root
description: Configuração de segurança para Ubuntu com isolamento do root, controle de sudo e bloqueio de shell root interativo (sudo -i), baseada em sudoers policy.
---

# 🧠 1. Fundamento do modelo Linux

- root = UID 0 (superusuário)
- usuários comuns = UID ≥ 1000
- elevação de privilégios = sudo

A separação já é estrutural do sistema Linux.

# 🔐 2. Fato de segurança crítico

No Ubuntu:

- sudo usa senha do usuário
- não usa senha do root
- root não participa da autenticação sudo

👉 Segurança depende de sudoers policy, não do root.

# ⚙️ 3. sudo -i (comportamento real)

sudo -i

- abre shell root temporário
- usa senha do usuário
- equivale a: sudo su -

# 🧱 4. Objetivo do hardening

- root inacessível diretamente
- sudo permitido, mas controlado
- bloqueio de shell root interativo
- administração baseada em comandos (não shell root)

# 🔒 5. Proteção do root

## 🚫 Modificar Senha root
```bash
sudo passwd root
```
---

## 🚫 Ou Bloquear acesso do root
```bash 
sudo passwd -l root
```
---

## 🚫 Bloquear login gráfico (se existir desktop)

---

### GDM (Ubuntu padrão):
```bash
sudo cp /etc/pam.d/gdm-password /etc/pam.d/gdm-password.bak
sudo nano /etc/pam.d/gdm-password
# coloca abaixo: `@include common-auth`
auth    requisite    pam_succeed_if.so user != root
```
### LightDM (se usado):

```bash
sudo nano /etc/pam.d/lightdm
# coloca abaixo: `@include common-auth`
auth    requisite    pam_succeed_if.so user != root
```

# 👤 6. Usuário admin

adduser sadmin
usermod -aG sudo sadmin

# 🔐 7. Bloqueio de sudo -i via sudoers
```bash
sudo visudo
```

---

## 🧱 Opção 1 (simples)

```bash
%sudo ALL=(ALL) ALL, !/bin/bash, !/bin/sh, !/usr/bin/su
```

---

## 🧱 Opção 2 (robusta)

```bash
Cmnd_Alias SHELLS = /bin/bash, /bin/sh, /usr/bin/zsh, /usr/bin/su, /usr/bin/sudo -i
%sudo ALL=(ALL) ALL, !SHELLS
```

# ⚠️ 8. Resultado prático

## ✔ Permitido
```bash
sudo apt update
sudo systemctl restart nginx
```

---

## ❌ Bloqueado
```bash
sudo -i
sudo su -
sudo bash
```

# 🧠 9. Limitação do sudo

### Mesmo com bloqueio:
```bash
sudo apt install git
```
✔ ainda funciona (execução por comando)


# 🧱 10. Modelo avançado (whitelist)

```bash
Cmnd_Alias SHELLS = /bin/bash, /bin/sh, /usr/bin/zsh, /usr/bin/su, \
                     /usr/bin/sudo -i, /usr/bin/sudo -s, \
                     /usr/bin/newgrp, /usr/bin/newgrp *
%sudo ALL=(ALL) SYSTEM, ALL, !SHELLS
```

# 📌 11. Conclusão

✔ root isolado  
✔ sudo ativo  
✔ sudo -i bloqueado  
✔ controle via sudoers policy  
✔ modelo seguro e compatível com Ubuntu moderno