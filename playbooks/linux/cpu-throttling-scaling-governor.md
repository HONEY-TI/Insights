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
- ondemand → ajuste automático por carga
- schedutil → moderno e dinâmico
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
sudo nano /etc/systemd/system/cpu-performance.service
```
---

## 🧠 CONTEÚDO DO SERVIÇO
```bash
[Unit]
Description=Set CPU governor to performance

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

[Install]
WantedBy=multi-user.target
```
---

## ▶️ ATIVAR SERVIÇO
```bash
sudo systemctl daemon-reload
sudo systemctl enable cpu-performance.service
sudo systemctl start cpu-performance.service
```
---

# 🧪 VERIFICAR STATUS
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
---

# ⚠️ OBSERVAÇÕES IMPORTANTES

- O modo performance mantém CPU em frequência máxima constante
- Aumenta consumo de energia e temperatura
- Recomendado para servidores, VMs e workloads intensivos
- Não recomendado para laptops em bateria
- Alguns sistemas modernos (intel_pstate / amd_pstate) podem ignorar cpufreq clássico