✔ SOLUÇÃO CORRETA (robusta)
1. Base: grupo + setgid
sudo chgrp -R vboxusers /home/alexf/.virtual-vms
sudo chmod -R 2775 /home/alexf/.virtual-vms

2. Herança de permissão para o usuário alexf e grupo vboxusers
sudo setfacl -R -d -m u:alexf:rwx /home/alexf/.virtual-vms
sudo setfacl -R -d -m g:vboxusers:rwx /home/alexf/.virtual-vms
sudo setfacl -R -m g:vboxusers:rwx /home/alexf/.virtual-vms


3. Melhor (produção): systemd service

## Criar Scrit `/usr/local/bin/fix-vbox-perms`

```bash 
#!/bin/bash

DIR="/home/alexf/.virtual-vms"

run_fix() {

    # Logs
    find "$DIR" -type d -name "Logs" -exec chmod 774 {} \;

    # arquivos normais
    find "$DIR" -type f \
        ! -name "*.vdi" \
        ! -name "*.nvram" \
        ! -name "*.vbo*" \
        -exec chmod 660 {} \;

    # vdi / nvram / vbox
    find "$DIR" -type f \( \
        -name "*.vdi" -o \
        -name "*.nvram" -o \
        -name "*.vbo*" \
    \) -exec chmod 664 {} \;
}

# inotify dispara o "fix global"
inotifywait -m -r -q \
    -e create -e moved_to -e modify \
    "$DIR" | while read -r _ _; do

    # evita execução em loop pesado
    run_fix

done
```
## Permissões: `sudo chmod +x /usr/local/bin/fix-vbox-perms` 

## Criar `sudo nano /etc/systemd/system/vbox-perms.service`
```bash
[Unit]
Description=Fix VirtualBox permissions via inotify
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/fix-vbox-perms
Restart=always

[Install]
WantedBy=multi-user.target
```

## 🔁  Aplicar sem reiniciar
```bash
sudo systemctl daemon-reload
sudo systemctl enable vbox-perms
sudo systemctl start vbox-perms
```

## 🧪 Verifique: `systemctl status vbox-perms.service` 

---