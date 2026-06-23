---

name: virtualbox-persintence-perms
description: Procedimento para persistir proprietário (owner) e grupo em arquivos e diretórios compartilhados, mantendo o acesso colaborativo entre usuários pertencentes ao grupo `vboxusers`. Utiliza o inotify como observador de eventos para garantir que as permissões sejam reaplicadas automaticamente sempre que houver alterações.
vboxusers.
----------

# 📦 Instalação do inotify

Instale o pacote responsável por monitorar alterações em arquivos e diretórios:

```bash
sudo apt install inotify-tools
```

---

# 🛠️ Criar Script `/usr/local/bin/fix-vbox-perms`

```bash
#!/bin/bash

DIR="/home/$USER/.virtual-vms"

run_fix() {

    # 📁 Diretórios de logs
    find "$DIR" -type d -name "Logs" -exec chmod 774 {} \;

    # 📄 Arquivos comuns
    find "$DIR" -type f \
        ! -name "*.vdi" \
        ! -name "*.nvram" \
        ! -name "*.vbo*" \
        -exec chmod 660 {} \;

    # 💿 Arquivos de disco e configuração do VirtualBox
    find "$DIR" -type f \( \
        -name "*.vdi" -o \
        -name "*.nvram" -o \
        -name "*.vbo*" \
    \) -exec chmod 664 {} \;
}

# 👀 Monitora alterações e reaplica permissões
inotifywait -m -r -q \
    -e create \
    -e moved_to \
    -e modify \
    "$DIR" | while read -r _ _; do

    # 🔄 Reaplica permissões automaticamente
    run_fix

done
```

---

# 🔐 Permissões do Script

Conceda permissão de execução e restrinja o acesso apenas ao proprietário e grupo:

```bash
sudo chmod +x /usr/local/bin/fix-vbox-perms
sudo chmod 750 /usr/local/bin/fix-vbox-perms
```

---

# ⚙️ Criar Serviço Systemd

Crie o arquivo:

```bash
sudo nano /etc/systemd/system/vbox-perms.service
```

Conteúdo:

```ini
[Unit]
Description=Fix VirtualBox permissions via inotify
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/fix-vbox-perms
Restart=always

[Install]
WantedBy=multi-user.target
```

---

# 🔁 Aplicar Sem Reiniciar

Recarregue o Systemd, habilite o serviço e inicie-o imediatamente:

```bash
sudo systemctl daemon-reload
sudo systemctl enable vbox-perms.service
sudo systemctl start vbox-perms.service
```

---

# 🧪 Verificar Status

Verifique se o serviço está em execução:

```bash
systemctl status vbox-perms.service
```

---

# 📋 Resultado Esperado

✅ Monitoramento contínuo da pasta `.virtual-vms`

✅ Reaplicação automática das permissões após alterações

✅ Compatibilidade com ambientes compartilhados entre usuários do grupo `vboxusers`

✅ Persistência das permissões sem necessidade de intervenção manual

✅ Inicialização automática após reinicialização do sistema
