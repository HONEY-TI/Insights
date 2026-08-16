---
name: jail-skel-configurations
description: Instalar JailKit e compartilhar Jail com novos usuário adicionados a JailKit.
---

# 🧱 Arquitetura de usuários e /etc/skel da JailKit

---
## 🔗 Relacionados

* [create-jail-skel.sh](../../operations/linux/jail/skel-user/create-jail-skel.sh)
* [create-jail-su-user](../../operations/linux/jail/create-jail-su-user.sh)
* [remove-jail-user](../../operations/linux/jail/create-jail-user.sh)
* [jail-configurations](jail-configurations.md)
* [jail-container-linux-configurartions](jail-container-linux-configurartions.md)


## 🎯 1. Objetivo

A criação de usuários da JailKit separa claramente:

- 👤 configuração inicial do usuário
- 🏛️ configuração global da jail
- 🔗 recursos compartilhados (SSH, Flatpak, extensões GNOME, perfil de terminal)
- 📦 instalações específicas do usuário
- ⚙️ configurações dinâmicas (sudo, rede, autenticação)

O `/etc/skel` é usado como **molde de criação**.

Os arquivos copiados do skel tornam-se **independentes** após a criação do usuário. Alterar ou apagar um arquivo em `/home/jail/etc/skel` não altera usuários já existentes.

A exceção é o `.ssh`, deliberadamente **compartilhado** por todos os usuários da jail. Extensões GNOME, perfil de terminal e Flatpak também são compartilhados — mas via **caminhos system-wide**, não via SKEL (ver seção 5).

---

## 🗂️ 2. Estrutura

```
/home/jail/
├── etc/
│   ├── skel/
│   │   ├── .bashrc
│   │   ├── .bash_logout
│   │   ├── .profile
│   │   ├── .zshrc
│   │   ├── .zsh_aliases
│   │   ├── .virtual-vms/
│   │   ├── .config/
│   │   │   └── Code/
│   │   │       └── User/
│   │   │           ├── keybindings.json
│   │   │           ├── settings.json
│   │   │           └── snippets/
│   │   ├── .local/
│   │   │   ├── bin/
│   │   │   └── share/
│   │   └── .ssh -> /ssh
│   │
│   ├── sudoers.d/
│   │   └── 90-<usuario>          # regra individual por usuário
│   │
│   ├── dconf/
│   │   ├── profile/user
│   │   └── db/
│   │       ├── local.d/
│   │       │   ├── 00-extensions       # 🧩 enabled-extensions
│   │       │   └── 01-terminal-profile # 🖥️ perfil Ptyxis
│   │       └── locks/
│   │
│   ├── jailkit/
│   │   └── github_token           # 🔑 token gh (600, root)
│   │
│   ├── jail-users.list            # 📋 lista de persistência de bind mounts
│   │
│   ├── resolv.conf                # 🌐 DNS
│   ├── hosts
│   ├── ssl/certs/ca-certificates.crt  # 🔐 TLS
│   │
│   ├── passwd
│   ├── group
│   └── ...
│
├── ssh/
│   ├── id_ed25519_github
│   ├── id_ed25519_github.pub
│   ├── id_ed25519_gitlab
│   └── id_ed25519_gitlab.pub
│
├── usr/
│   ├── bin/
│   │   ├── sudo, zsh, gum, gh, flatpak   # copiados via jk_cp
│   └── share/
│       └── gnome-shell/extensions/
│           └── Resource_Monitor@Ory0n    # 🧩 instalado system-wide
│
├── var/lib/flatpak -> /var/lib/flatpak   # 📦 symlink compartilhado com o HOST
│
└── home/
    ├── usuario1/
    │   ├── Documentos -> bindfs   # 📁 compartilhado
    │   └── workspace -> bindfs    # 📁 compartilhado
    └── usuario2/
```

> ℹ️ Fora da jail, no **HOST real**, os mesmos caminhos `/usr/share/gnome-shell/extensions/` e `/etc/dconf/db/` também recebem a extensão e o perfil de terminal — necessário porque sessões gráficas GNOME via GDM rodam no filesystem do host, **não** dentro do chroot. Veja seção 5.

---

## 📄 3. O que pertence ao `/etc/skel`

### 🐚 Arquivos de shell
```
.bashrc
.bash_logout
.profile
.zshrc
.zsh_aliases
```
Copiados individualmente para cada novo usuário (independentes após a cópia).

### 📁 Estrutura inicial
```
.virtual-vms/
.local/bin/
.local/share/
```
Copiados com conteúdo (não apenas criados vazios) quando existentes no usuário modelo.

### 💻 Configurações pessoais padrão (VS Code)
```
.config/Code/User/keybindings.json
.config/Code/User/settings.json
.config/Code/User/snippets/
```
Desde que representem configuração **inicial**, não estado específico de uma máquina.

### 🔗 SSH (link, não cópia)
```
.ssh -> /ssh
```
Ver seção 5 — o SKEL nunca copia chaves, apenas recria o symlink.

---

## 🚫 4. O que NÃO pertence ao `/etc/skel`

```
.Xauthority
.cache/*
monitors.xml
VS Code completo
tokens / credenciais
estado de aplicações
sudoers
passwd
group
nsswitch.conf
ld.so.cache
dconf global
bind mounts
shared folders
extensões GNOME (~/.local/share/gnome-shell/extensions)
```

Esses elementos são tratados pelas respectivas **funções dinâmicas** do criador de usuários (`configure_*`, `ensure_*`), não pelo SKEL — porque ou dependem do ambiente em tempo de criação (rede, sessão gráfica), ou são intencionalmente compartilhados system-wide em vez de copiados por usuário.

---

## 🔑 5. Recursos compartilhados (system-wide, fora do SKEL)

Diferente do SKEL (cópia independente por usuário), os recursos abaixo são **deliberadamente globais** — uma alteração afeta todos os usuários, atuais e futuros.

### 🔐 5.1 SSH compartilhado

```
/home/jail/ssh
```

Dentro do chroot, isso corresponde a:

```
/ssh
```

O HOME de cada usuário possui:

```
.ssh -> /ssh
```

**Por que não `/home/jail/ssh` direto no symlink?**
Porque dentro do chroot o processo não enxerga `/home/jail/ssh` como o mesmo caminho do host. O caminho correto *de dentro* da jail é `/ssh`.

```
/home/jail/home/alex/.ssh
        ↓
       /ssh
        ↓
/home/jail/ssh
```

Alterar `/home/jail/ssh/id_ed25519_github` afeta **todos** os usuários. Isso é intencional.

---

### 🧩 5.2 Extensão GNOME (Resource Monitor) — HOST + JAIL

A extensão é lida do usuário modelo (via `gnome-extensions list --enabled`, com D-Bus/`XDG_RUNTIME_DIR` da sessão ativa) e instalada em **dois caminhos**:

```
/usr/share/gnome-shell/extensions/<uuid>              ← HOST real (sessões gráficas GDM)
/home/jail/usr/share/gnome-shell/extensions/<uuid>     ← JAIL (processos chrootados via SSH/JailKit)
```

⚠️ **Ponto crítico de arquitetura:** login gráfico (GDM) roda no filesystem real do HOST, não dentro do chroot da jail. Por isso a extensão precisa existir nos dois lugares — instalar apenas dentro da jail não teria efeito nenhum em sessões gráficas.

A chave `enabled-extensions` é forçada via `/etc/dconf/db/local.d/00-extensions`, compilada com `dconf update` (host) e `dconf update <jail>/etc/dconf/db` (jail), sem depender de `chroot` nem de binário `dconf` dentro da jail.

---

### 🖥️ 5.3 Perfil de Terminal (Ptyxis) — HOST + JAIL

O perfil configurado no usuário modelo (`dconf dump /org/gnome/Ptyxis/`) é exportado, reescrito para caminho absoluto (`org/gnome/Ptyxis/...`) e gravado em:

```
/etc/dconf/db/local.d/01-terminal-profile              ← HOST
/home/jail/etc/dconf/db/local.d/01-terminal-profile     ← JAIL
```

Assim, cores, paleta, atalhos e configuração de proxy do terminal já vêm prontos para qualquer novo usuário, sem configuração manual.

---

### 📦 5.4 Flatpak — repositório compartilhado

```
/home/jail/var/lib/flatpak -> /var/lib/flatpak   (symlink JAIL → HOST)
```

O binário `flatpak` é copiado para dentro da jail via `jk_cp`; o **repositório de pacotes** em si nunca é duplicado — é sempre o mesmo do host, referenciado por symlink.

---

## 🏗️ 6. Construção do SKEL (`build-jail-skel`)

Fluxo real (`main()`):

```
build-jail-skel <usuario-modelo>
        │
        ├── ✅ valida root / argumentos / usuário modelo
        ├── ⚠️  confirma substituição do SKEL existente
        ├── 🧹 prepara SKEL (limpa e recria)
        │
        ├── 🐚 copia configuração de shell
        ├── 📁 copia estrutura inicial (.virtual-vms, .local/bin, .local/share)
        ├── 💻 copia configuração inicial do VS Code
        │
        ├── 🔗 configura SSH compartilhado (.ssh -> /ssh)
        ├── 🎨 gera template GNOME (dconf dump completo do usuário modelo)
        ├── 📦 garante Flatpak compartilhado na jail
        │
        ├── 🧩 instala extensão GNOME system-wide (HOST + JAIL)
        ├── ⚙️  aplica enabled-extensions via dconf (HOST + JAIL)
        ├── 🖥️  persiste perfil de terminal Ptyxis (HOST + JAIL)
        │
        ├── 🗑️  remove conteúdo indesejado (.cache, .Xauthority)
        │
        ├── 🔐 configura permissões (root:root, 644/755)
        ├── 🔎 valida resultado (arquivos obrigatórios + symlink SSH)
        └── 📋 exibe resumo
```

O usuário modelo pode ser qualquer usuário do host já configurado como referência (ex: `sadmin`), **desde que esteja com sessão gráfica ativa** — as etapas de extensão GNOME e perfil de terminal dependem do barramento D-Bus da sessão (`/run/user/<uid>/bus`) para consultar configurações em tempo real.

---

## 👤 7. Criação de novo usuário (`create-jail-su-user`)

Fluxo real (`main()`):

```
create-jail-su-user <usuario>
        │
        ├── ✅ valida root / nome de usuário / existência do SKEL
        ├── 👥 garante grupos (jailusers + docker, users, gitssh)
        ├── ♻️  remove usuário existente (se confirmado)
        ├── 👤 cria usuário (useradd -k SKEL, shell zsh)
        ├── 🔒 configura JailKit (jk_jailuser)
        ├── 🔐 endurece /home da jail (711, root:root)
        │
        ├── 🛡️  garante sudo dentro da jail (jk_cp)
        ├── 🐚 garante zsh dentro da jail (jk_cp)
        ├── ✨ garante gum instalado (host + jail)
        │
        ├── 🛡️  configura sudoers da jail (NOPASSWD somente dentro da jail)
        ├── 🏠 configura HOME (.config, .cache, .local, permissões restritas)
        │
        ├── 🐙 garante gh (GitHub CLI) dentro da jail (jk_cp)
        ├── 🌐 garante DNS/TLS dentro da jail (resolv.conf, ca-certificates, hosts)
        ├── 🔑 autentica gh via token protegido (/etc/jailkit/github_token, 600)
        │
        ├── 📁 cria pasta compartilhada Documentos (bindfs)
        ├── 📁 cria pasta compartilhada workspace (bindfs)
        ├── 🔗 aplica bind mounts persistentes (jail-mounts.sh)
        │
        ├── 📋 adiciona usuário à lista de persistência
        ├── 🖥️  copia configuração de monitores (monitors.xml)
        ├── ⌨️  configura atalhos do VS Code
        └── 📋 exibe resumo
```

**O usuário NÃO recebe sudo no HOST** — apenas dentro da jail, via regra individual em `/home/jail/etc/sudoers.d/90-<usuario>`.

---

## 🔐 8. Rede, TLS e autenticação `gh` dentro da jail

`chroot` isola **filesystem**, não rede — mas sem os arquivos certos dentro da jail, DNS e TLS falham silenciosamente:

| Arquivo | Função |
|---|---|
| `$JAIL_PATH/etc/resolv.conf` | 🌐 resolução DNS |
| `$JAIL_PATH/etc/ssl/certs/ca-certificates.crt` | 🔐 validação TLS (HTTPS) |
| `$JAIL_PATH/etc/hosts` | 🗺️ resolução de nomes locais |

O token do GitHub **nunca** fica hardcoded no script nem em variável de ambiente. Ele é lido de:

```
/etc/jailkit/github_token   (permissão 600, root:root)
```

A função `configure_gh_auth` valida a permissão antes de usar, e autentica via:

```bash
echo "$token" | HOME="/home/$USERNAME" chroot --userspec="$USERNAME:$USERNAME" "$JAIL_PATH" gh auth login --with-token
```

> ⚠️ `chroot --userspec` é usado em vez de `runuser`/`su`/`env` porque **nenhum desses binários existe dentro da jail** — apenas `gh` é copiado via `jk_cp`. `--userspec` troca de usuário como parte do próprio `chroot`, sem dependências extras.

---

## 🛡️ 9. Sudo — modelo de segurança

O sudo dentro da jail hoje é `NOPASSWD:ALL` por usuário. Isso é conveniente, mas **não impede** virar root via comandos que abrem shell (`sudo vim`, `sudo find -exec bash`, `sudo python3 -c "os.system('bash')"`, etc.) — bloquear `sudo -i`/`sudo -s`/`su` isoladamente é apenas cosmético nesse modelo.

**Recomendação estrutural** (whitelist, não blocklist):

```bash
Cmnd_Alias SAFE_CMDS = /usr/bin/apt update, /usr/bin/apt upgrade, \
                        /usr/bin/systemctl *, /usr/bin/dconf update, \
                        /usr/bin/flatpak *

$USERNAME ALL=(ALL) NOPASSWD: SAFE_CMDS
```

Isso torna estruturalmente impossível abrir shell root via `sudo`, porque nenhum comando da lista abre shell — em vez de tentar enumerar e bloquear cada binário capaz de shell-escape (abordagem que nunca é exaustiva).

---

## ✅ 10. Benefícios

A principal vantagem é **eliminar código repetitivo** e centralizar decisões de compartilhamento.

**Antes:**
```
configure_home()
    ├── cat .profile
    ├── cat .zsh_aliases
    ├── cat .zshrc
    ├── cat .bashrc
    ├── touch .bash_logout
    ├── mkdir .config
    ├── mkdir .cache
    └── mkdir .local
```

**Depois:**
```
configure_home()
    └── cp -a /etc/skel/. "$USER_HOME/"
```

A configuração padrão passa a existir em um único lugar (`/home/jail/etc/skel/`), enquanto recursos verdadeiramente globais (SSH, extensão GNOME, perfil de terminal, Flatpak) vivem em caminhos system-wide, não em cópias por usuário.

---

## 🔄 11. Atualização do SKEL e dos recursos compartilhados

```
usuário modelo
      ↓
build-jail-skel
      ↓
/home/jail/etc/skel/            (SKEL — afeta só NOVOS usuários)
/usr/share/gnome-shell/...      (system-wide — afeta TODOS, imediatamente)
/etc/dconf/db/local.d/...       (system-wide — afeta TODOS, imediatamente)
```

⚠️ **Diferença importante:** alterações no SKEL não afetam usuários existentes (cópia independente). Alterações nos recursos **system-wide** (extensão GNOME, perfil de terminal) afetam **todos os usuários imediatamente**, inclusive os já existentes, na próxima vez que a sessão/shell for recarregada.

Para atualizar dotfiles de um usuário existente, isso deve ser uma operação **explícita e separada** — nunca implícita ao rodar `build-jail-skel` novamente.

---

## 📐 12. Regra arquitetural

| Caminho | Significado |
|---|---|
| 🧩 `/etc/skel` | configuração inicial **independente** por usuário |
| 🏛️ `/etc` | configuração global da jail |
| 🔗 `/ssh` | recurso deliberadamente **compartilhado** |
| 🧩 `/usr/share/gnome-shell/extensions` (HOST + JAIL) | recurso deliberadamente **compartilhado**, system-wide |
| ⚙️ `/etc/dconf/db/local.d` (HOST + JAIL) | padrões **compartilhados** que sobrepõem preferências individuais não travadas |
| 📦 `/var/lib/flatpak` | repositório **compartilhado** via symlink |
| 👤 `/home/<usuario>` | estado/configuração **individual** |
| ⚙️ `configure_*` / `ensure_*` | configuração **dinâmica** ou dependente do ambiente (rede, sessão gráfica, tokens) |

Essa separação evita tanto duplicação de código quanto dependências acidentais entre usuários — e deixa explícito, caminho por caminho, o que é individual e o que é intencionalmente global.