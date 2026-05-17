---
name: core-linux-architecture
description: Arquitetura base do sistema Linux Debian/Ubuntu dentro do ecossistema Insights pessoal, definindo máquina principal, estrutura multiusuário e camadas operacionais.
---

# 🖥️ Máquina principal

- 🧩 Core-Primary (Ambiente em produção)
   * Dual Boot Winwods e Linux 
- 🧩 InsightCore-LinuxHost(Ambiente em Teste) - Será utilizado como Orquestrador de todo ecosistema 
  * Boot Único Linux com Windows virtualizado dentro de uma Virtual Machine
  * Ambiente Principal configurado para Desenvolvimento e progamação tendo um usuário especifico sem acesso direto ao root apenas para propagar configurações padrões aos usuários dentro da Jail.
  * Ambiente  para execução de jogos deve possuir e montagem de HD especifico com Jogos e permissinamentos restritos apenas a configurações pertinentes para o funcionamento dos jogos.
  

## 📌 Objetivo:

- Host principal Linux
  * Execução de automações e scripts do ecossistema Insights
  * Central de integração entre knowledge, operations, systems, etc..

---

# ⚙️ operations (🔧 execução)

Responsável por:
- scripts operacionais
- automações locais
- manutenção do sistema

/operations
├── linux/
└── windows/

---

# 📜 playbooks (📖 procedimentos)

Responsável por:
- guias passo a passo
- processos repetíveis
- setup de sistemas

/playbooks
├── linux/
└── windows/

---

# 📦 projects (🧪 desenvolvimento isolado dentro de Jails compartilhadas )

/projects
├── project-a/
└── project-b/

Responsável por:
- projetos compartilhados 
- testes e experimentos separados por necessidade afim de não interferir ou causar erros no ambiente HOST
- versionamento compartilhado mais com segurança não permitindo criação nem exclusão de pastas ou arquivos apenas leitura e edição. No máximo execução de alguns execútaveis 

---

# 🧩 systems (🖥️ infraestrutura)

/systems
├── linux/
└── windows/

Responsável por:
- configuração do sistema operacional
- drivers e dependências
- integração hardware/OS

---

# 👥 modelo de usuários Linux

## Superusuário
- root (admin do sistema)

--
## Usuário template paar Jail
- skell-user (usuário principal para criação de novos usuários em Jails)

---


# 🎮 compatibilidade Windows / Gaming

## Stack

- Steam + Proton → jogos Windows
- Wine → aplicações gerais Windows

---

# 🔵 Bluetooth

Objetivo:
- baixa latência
- reconexão automática

Stack:
- bluez
- pipewire
- blueman (opcional)

---

# 🔊 Dual Audio

Objetivo:
- saída simultânea em múltiplos dispositivos

Stack:
- PipeWire ou PulseAudio
- loopback sinks

---

# 🖥️ VirtualBox

Componentes:
- VirtualBox
- Extension Pack
- Guest Additions

Requisitos:
- kernel headers
- DKMS

---

# 💾 Recuperação de partição

Ferramentas:
- gparted
- testdisk
- ddrescue

Casos:
- pen drive corrompido
- recuperação de disco
- partições perdidas

---

# 👤 usuário Ubuntu padrão

Estrutura:
- usuário criado na instalação do SO
- pertence ao grupo primário

Regra:
- Configurar e serar usuário com permissões root do real usuário root 

Fix recomendado:
sudo chown -R insight-user:insight-user /Insights

---

# 🧭 visão geral do sistema

CoreNode-Primary (Linux)
│
├── knowledge
├── operations
├── playbooks
├── projects
└── systems