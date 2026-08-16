---

name: ubuntu-resource-monitor
description: Instala e configura o Resource Monitor do GNOME Shell para exibir CPU, memória, tráfego de rede e outros recursos diretamente na barra superior do Ubuntu, de forma semelhante ao monitor disponível no Kali Linux.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 📘 Playbook — Monitor de CPU e Rede na Barra do Ubuntu

# 🎯 Objetivo

Instalar um monitor de recursos no Ubuntu GNOME capaz de exibir diretamente na barra superior:

* uso de CPU
* memória RAM
* swap
* tráfego de rede
* download
* upload
* disco
* GPU
* temperatura, quando disponível

A extensão **Resource Monitor** fornece monitoramento em tempo real diretamente no painel do GNOME.

---

# 🔗 Relacionados

* [Resource Monitor — GNOME Shell Extensions](https://extensions.gnome.org/extension/1634/resource-monitor/?utm_source=chatgpt.com)
* [GNOME System Monitor](https://apps.gnome.org/SystemMonitor/?utm_source=chatgpt.com)
* [System Monitor — GNOME Shell Extensions](https://extensions.gnome.org/extension/120/system-monitor/?utm_source=chatgpt.com)

---

# 🚨 Quando usar

* visualizar CPU diretamente na barra
* acompanhar download e upload em tempo real
* monitorar RAM sem abrir aplicativos
* acompanhar utilização de GPU
* acompanhar temperatura do hardware
* substituir o monitor separado do sistema
* obter uma experiência semelhante ao Kali Linux

---

# 🧠 Diagnóstico inicial

Verificar a versão do Ubuntu:

```bash
lsb_release -a
```

Verificar a versão do GNOME:

```bash
gnome-shell --version
```

Verificar a sessão atual:

```bash
echo $XDG_CURRENT_DESKTOP
```

---

# 📦 Instalação das dependências

Atualizar os repositórios:

```bash
sudo apt update
```

Instalar suporte às extensões do GNOME:

```bash
sudo apt install gnome-shell-extension-manager gnome-browser-connector
```

Caso o pacote `gnome-browser-connector` não esteja disponível na sua versão do Ubuntu:

```bash
sudo apt install gnome-shell-extension-manager
```

---

# 🚀 Instalação recomendada

A forma mais segura é instalar a extensão diretamente pelo catálogo oficial do GNOME.

Abrir:

[Resource Monitor — GNOME Shell Extensions](https://extensions.gnome.org/extension/1634/resource-monitor/?utm_source=chatgpt.com)

Procurar por:

```text
Resource Monitor
```

Selecionar:

```text
Resource Monitor
by 0ry0n
```

Ativar:

```text
ON
```

A extensão atualmente oferece monitoramento de CPU, RAM, swap, disco, rede e GPU no painel superior.

---

# 🖥️ Instalação pelo Extension Manager

Também é possível utilizar o aplicativo gráfico:

```bash
gnome-extensions-app
```

Ou abrir o **Extension Manager**:

```bash
extension-manager
```

Pesquisar:

```text
Resource Monitor
```

Instalar e ativar.

---

# ⚙️ Configuração

Depois de instalar:

```text
Configurações
→ Extensões
→ Resource Monitor
→ Configurar
```

Ativar as métricas desejadas:

```text
CPU
RAM
Network
Disk
GPU
Temperature
```

Para o objetivo de monitorar internet, habilitar principalmente:

```text
Network
```

E configurar:

```text
Download
Upload
```

---

# 🌐 Monitoramento de entrada e saída

O objetivo é visualizar algo semelhante a:

```text
CPU 12% | RAM 4.8G | ↓ 2.4 MB/s | ↑ 180 KB/s
```

Onde:

```text
↓ = Download / entrada
↑ = Upload / saída
```

A extensão possui monitoramento de rede em tempo real junto com CPU, RAM, disco e GPU.

---

# 🔄 Reiniciar a extensão

Caso a informação não apareça imediatamente:

```bash
gnome-extensions list
```

Localizar o identificador do Resource Monitor e executar:

```bash
gnome-extensions disable <ID_DA_EXTENSAO>
gnome-extensions enable <ID_DA_EXTENSAO>
```

---

# 🧪 Validação

Verificar as extensões instaladas:

```bash
gnome-extensions list
```

Verificar se a extensão está habilitada:

```bash
gnome-extensions info <ID_DA_EXTENSAO>
```

Também é possível verificar o consumo de rede pelo monitor do sistema:

```bash
gnome-system-monitor
```

O GNOME System Monitor possui gráficos para CPU, memória e utilização de rede.

---

# 🔥 Alternativa — somente velocidade da internet

Se você quiser somente:

```text
↓ Download
↑ Upload
```

uma alternativa mais simples é a extensão **Net Speed**:

[Net Speed — GNOME Shell Extensions](https://extensions.gnome.org/extension/4478/net-speed/?utm_source=chatgpt.com)

Ela mostra a velocidade atual da rede diretamente no painel e permite configurar diferentes modos de exibição.

---

# 🔥 Alternativa — CPU + RAM + Swap

Para mostrar principalmente recursos do sistema:

[System Monitor Tray — GNOME Shell Extensions](https://extensions.gnome.org/extension/9080/system-monitor-tray/?utm_source=chatgpt.com)

Ela exibe CPU, memória, swap e load em tempo real no painel superior.

---

# ⚠️ Observação

Não é necessário instalar o antigo `gnome-shell-system-monitor-applet` para um Ubuntu moderno.

A extensão antiga `system-monitor` possui versões ativas apenas até GNOME 40, portanto não é a opção recomendada para instalações atuais.

---

# 🧠 Resultado esperado

Depois da configuração, a barra superior do Ubuntu deverá apresentar informações semelhantes a:

```text
CPU 8%   RAM 3.2G   ↓ 1.8 MB/s   ↑ 250 KB/s
```

Assim você consegue acompanhar **CPU + entrada de dados + saída de dados da internet** sem abrir o Monitor do Sistema.

---

# 🏁 Instalação rápida

```bash
sudo apt update && \
sudo apt install -y gnome-shell-extension-manager gnome-browser-connector
```

Depois abrir:

```bash
extension-manager
```

Pesquisar:

```text
Resource Monitor
```

Instalar → Ativar → Configurar CPU/RAM/Network.

---

# 🧹 Remoção

Remover o aplicativo de gerenciamento:

```bash
sudo apt remove gnome-shell-extension-manager gnome-browser-connector
```

A extensão instalada pelo GNOME deve ser removida pelo:

```text
Extension Manager
→ Resource Monitor
→ Remove
```

---

# 🧠 Resultado final

* CPU visível na barra
* RAM visível na barra
* Download visível na barra
* Upload visível na barra
* monitoramento em tempo real
* compatível com GNOME moderno
* configuração semelhante ao monitoramento utilizado no Kali Linux
