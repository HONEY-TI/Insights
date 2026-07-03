---
name: cpu-throttling-scaling-governor
description: Configuração completa para gerenciamento de performance de CPU em Linux usando cpufreq.
--- 

# 🎯 Objetivo
  Força o governor para modo performance e garante persistência via systemd service.


# ⚙️ CPU THROTTLING E PERFORMANCE MODE

O Linux utiliza o subsistema cpufreq para ajustar automaticamente a frequência da CPU
com base em carga e consumo de energia.

Principais governors:
- powersave → economia de energia
- performance → frequência máxima constante

---

# 🔎 VERIFICAR GOVERNOR ATUAL
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
---

# 🚀 FORÇAR MODO PERFORMANCE (TEMPORÁRIO)
```bash
sudo bash -c 'echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
```
✔ Aplica imediatamente  
❌ Não persiste após reboot

---

# 🔁 TORNAR PERMANENTE (SYSTEMD SERVICE)

## 📦 Criar serviço
```bash
sudo nano /etc/systemd/system/cpu-governor.service
```
---

## 🧠 CONTEÚDO DO SERVIÇO
```bash
[Unit]
Description=Set CPU governor to performance
After=power-profiles-daemon.service

[Service]
Type=idle
ExecStart=/bin/bash -c 'echo schedutil | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```
---

## ▶️ ATIVAR SERVIÇO
```bash
sudo systemctl daemon-reload
sudo systemctl enable cpu-governor.service 
sudo systemctl start cpu-governor.service 
```

## 🛠️ Persistir a configuração para todos os usuários
 Objetivo é permitir que qualquer usuário execute apenas o comando via sudo sem solicitar senha, persistendo a configuração ao fazer login.
 > Ciar um arquivo em `/etc/sudoers.d/` com uma regra específica.
 ```bash 
sudo visudo -f /etc/sudoers.d/cpu-governor
``` 
> Adicionar ao conteuodo do arquivo `cpu-governor`
``` bash
ALL ALL=(root) NOPASSWD: /usr/bin/systemctl start cpu-governor.service
```

> Adicionar ao arquivo `/etc/bash.bashrc`
```bash 
alias cpu='cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
sudo systemctl start cpu-governor.service 
```

# 🧪 VERIFICAR STATUS
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# ou 
cpu 
```
---

# ⚠️ OBSERVAÇÕES IMPORTANTES

- O modo performance mantém CPU em frequência máxima constante
- Aumenta consumo de energia e temperatura
- Recomendado para servidores, VMs e workloads intensivos
- Não recomendado para laptops em bateria
- Alguns sistemas modernos (intel_pstate / amd_pstate) podem ignorar cpufreq clássico