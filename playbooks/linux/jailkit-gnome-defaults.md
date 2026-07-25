---
name: jailkit-gnome-defaults
description: Documentação do script `create-jail-user` e da configuração de defaults do GNOME (dconf) aplicados automaticamente a todo novo usuário jailado.
---

# JailKit + GNOME Defaults — Documentação

---
## 🔗 Relacionados

* [Configurações de Workspace Compartilhado](./foldres-ownership-enforcer.md)
* [create-jail-user](../../operations/linux/jail/create-jail-user.sh)
* [remove-jail-user](../../operations/linux/jail/remove-jail-user.sh)
* [jail-configurations](jail-configurations.md)
* [jail-container-linux-configurartions](jail-container-linux-configurartions.md)

---

## 1. 🧭 Visão geral

- **Objetivo:** criar usuários restritos a uma jail (via Jailkit), com home dentro de `/home/jail`, e fazer com que o ambiente gráfico GNOME (tela, dock, aparência, data/hora, monitores) já venha configurado igual a um "usuário modelo", sem trabalho manual.
- **Componentes envolvidos:**
  - `useradd` — cria o usuário e já posiciona o home dentro da jail via `/./`
  - `jk_jailuser` — associa o usuário à jail (shell restrito, `<jail>/etc/passwd`)
  - `dconf` — banco de configurações do GNOME, usado para aplicar defaults globais do sistema
  - `monitors.xml` — arquivo de configuração de monitores do GNOME (não usa dconf)

---

## 2. 📁 Estrutura de diretórios

```
/home/jail/                     ← raiz da jail
├── etc/
│   ├── passwd                  ← passwd interno da jail
│   └── jail-users.list         ← lista de usuários jailados criados
├── home/
│   └── <usuario>/               ← home de cada usuário jailado
├── Documentos/                 ← pasta compartilhada (bindfs)
└── workspace/                  ← pasta compartilhada (bindfs)

/etc/jailkit/
└── skel/
    └── monitors.xml            ← template de config de monitores (não depende de usuário)

/etc/dconf/
├── profile/
│   └── user                    ← aponta pro banco "local"
└── db/
    └── local.d/
        └── 00-jail-defaults    ← defaults globais do GNOME (dconf)
```

---

## 3. 🔄 Fluxo do script `create-jail-user`

Ordem de execução em `main()`:

1. `validate_root` — exige root
2. `validate_username` — exige argumento de usuário
3. `ensure_group_exists` — cria grupo `jailusers` se não existir
4. `remove_existing_user` — remove e recria se usuário já existir (confirmação interativa)
5. `create_user` — `useradd` com home já em `/home/jail/./home/<user>` (o `/./` já marca a raiz da jail)
6. `configure_gh_auth_manual` — cria `~/.config/gh/hosts.yml` (placeholder de token)
7. `configure_jailkit` — `jk_jailuser -j <jail> <user>` (associa o usuário à jail)
8. `configure_home` — cria `.profile`, `.bashrc`, `.Xauthority`, ajusta permissões
9. `configure_dconf_defaults` — aplica defaults do GNOME (host, global, não por-usuário)
10. `create_shared_folder` (Documentos, workspace) — monta pastas compartilhadas via `bindfs`
11. `add_jail_user_to_list_persist_bind_mount` — registra usuário na lista de persistência de mount
12. `configure_monitors` — copia `monitors.xml` template pro home do usuário
13. `usermod -aG docker` + `usermod -s /bin/bash`

---

## 4. 🐛 Erros corrigidos ao longo do processo

| Problema | Causa | Correção |
|---|---|---|
| `unexpected EOF` / função aninhada | `configure_jailkit()` não fechava `}` antes de `configure_home()` começar | Fechar a chave corretamente |
| `$DISPLAY` expandido errado no `.profile` | Heredoc sem aspas expandia a variável na hora de **criar** o arquivo (valor do root), não no login do usuário | Usar `\$DISPLAY` (escapado) no heredoc |
| Defaults do dconf não aplicavam | Script só criava `00-jail-defaults` **se o arquivo não existisse** — updates seguintes eram ignorados | Trocar para sempre sobrescrever (`cat > arquivo <<EOF`, sem `if [[ ! -f ]]`) |
| Configs de desktop não refletiam no novo usuário | Testes feitos em usuário que **já tinha logado antes** — chaves alteradas manualmente pelo usuário sempre têm prioridade sobre o default do `local.d` | Testar sempre com usuário novo, ou `dconf reset -f /` no usuário de teste |
| `home directory ... is already inside the jail` | `configure_jailkit()` usava `jk_jailuser -m ...` (flag `--move`), mas o home já tinha sido criado com `/./` pelo `useradd` — não havia nada para mover | Remover a flag `-m` de `configure_jailkit()` |
| `aborted, no username specified` | `$USERNAME` chegando vazio na chamada do `jk_jailuser` (script desatualizado em `/usr/local/sbin`, ou variável não propagada) | Confirmar que o script instalado é o mesmo editado (`cat $(which create-jail-user)`), adicionar debug temporário se necessário |

---

## 5. 🔒 Configuração `configure_jailkit()` (versão corrigida)

```bash
configure_jailkit() {
    jk_jailuser \
        -j "$JAIL_PATH" \
        "$USERNAME"
}
```

> Sem a flag `-m`/`--move`, já que o home é criado diretamente dentro da jail pelo `useradd` (via `/./` no path).

---

## 6. 🎨 `configure_dconf_defaults()` — defaults globais do GNOME

Aplica-se a **todos os usuários do sistema** (não é por-usuário) — é um banco global lido pelo dconf antes das preferências pessoais de cada um. Só não tem efeito em chaves que o usuário já alterou manualmente antes.

```bash
configure_dconf_defaults() {

    if [[ ! -f "$DCONF_PROFILE_FILE" ]]; then
        mkdir -p "$(dirname "$DCONF_PROFILE_FILE")"
        cat > "$DCONF_PROFILE_FILE" <<'EOF'
user-db:user
system-db:local
EOF
    fi

    mkdir -p "$(dirname "$DCONF_DEFAULTS_FILE")"

    cat > "$DCONF_DEFAULTS_FILE" <<'EOF'
[org/gnome/desktop/interface]
clock-format='24h'
clock-show-weekday=true
clock-show-date=true
clock-show-seconds=true
clock-show-weekday-numbers=false
color-scheme='prefer-dark'
cursor-blink-time=1200
gtk-theme='Yaru-dark'
icon-theme='Yaru-dark'

[org/gnome/desktop/datetime]
automatic-timezone=true

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell/overrides]
dynamic-workspaces=false
edge-tiling=false

[org/gnome/mutter/keybindings]
toggle-tiled-left=@as []
toggle-tiled-right=@as []

[org/gnome/shell]
favorite-apps=['google-chrome.desktop', 'code.desktop', 'antigravity.desktop', 'org.gnome.Ptyxis.desktop', 'firefox_firefox.desktop', 'org.gnome.Nautilus.desktop', 'snap-store_snap-store.desktop', 'libreoffice-calc.desktop']
last-selected-power-profile='performance'
welcome-dialog-last-shown-version='50.1'

[org/gnome/shell/app-switcher]
current-workspace-only=true

[org/gnome/shell/extensions/dash-to-dock]
isolate-monitors=false
isolate-workspaces=true
dash-max-icon-size=32

[org/gnome/shell/extensions/ding]
check-x11wayland=true
keep-arranged=true

[org/gnome/shell/extensions/tiling-assistant]
focus-hint-color='rgb(211,70,21)'
last-version-installed=54
tiling-popup-all-workspace=false
EOF

    dconf update
}
```

### O que cada bloco cobre

| Seção | O que controla |
|---|---|
| `desktop/interface` | Formato de hora, tema (dark), ícones, cursor, itens visíveis no relógio da barra superior |
| `desktop/datetime` | Fuso horário automático |
| `desktop/wm/preferences` | Layout dos botões da janela (minimizar/maximizar/fechar) |
| `shell/overrides` | Workspaces fixos (não dinâmicos), edge-tiling desabilitado |
| `mutter/keybindings` | Atalhos de tiling desabilitados (vazios) |
| `shell` | Favoritos do dock, perfil de energia, versão do diálogo de boas-vindas já vista |
| `shell/app-switcher` | Alt+Tab restrito ao workspace atual |
| `shell/extensions/dash-to-dock` | Isolamento por monitor/workspace, tamanho dos ícones do dock |
| `shell/extensions/ding` | Comportamento dos ícones da área de trabalho (desktop icons) |
| `shell/extensions/tiling-assistant` | Cor de destaque do tiling, versão instalada |

### Chaves deliberadamente **não** replicadas

- `app-picker-layout` — depende de apps específicos instalados na máquina modelo; pode gerar posições vazias se o app não existir no destino
- `overridden-settings` (tiling-assistant) — é estado interno de runtime da extensão, não preferência do usuário
- `session/application-children` — janelas abertas no momento do dump, não é preferência
- `notifications`, `privacy`, `locale` — vieram vazios no dump (nada customizado a replicar)

---

## 7. 🖥️ `configure_monitors()` — layout de telas

Diferente do resto, **configuração de monitor não fica no dconf** — fica em `~/.config/monitors.xml`, vinculado ao hardware físico detectado (EDID/conector).

```bash
configure_monitors() {

    if [[ ! -f "$MONITORS_TEMPLATE" ]]; then
        echo "⚠️  $MONITORS_TEMPLATE não encontrado, pulando config de monitores."
        return 0
    fi

    cp "$MONITORS_TEMPLATE" "$USER_HOME/.config/monitors.xml"
}
```

Template usado (`/etc/jailkit/skel/monitors.xml`):

```xml
<monitors version="2">
  <configuration>
    <layoutmode>logical</layoutmode>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>1</scale>
      <primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>HDMI-1</connector>
          <vendor>GSM</vendor>
          <product>LG ULTRAWIDE</product>
          <serial>0x0002e196</serial>
        </monitorspec>
        <mode>
          <width>2560</width>
          <height>1080</height>
          <rate>59.978</rate>
        </mode>
      </monitor>
    </logicalmonitor>
    <logicalmonitor>
      <x>2560</x>
      <y>312</y>
      <scale>1</scale>
      <monitor>
        <monitorspec>
          <connector>eDP-1</connector>
          <vendor>CMN</vendor>
          <product>0x15dc</product>
          <serial>0x00000000</serial>
        </monitorspec>
        <mode>
          <width>1366</width>
          <height>768</height>
          <rate>60.003</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
```

> ⚠️ Só faz sentido copiar isso se os usuários logarem na **mesma máquina física**, com os mesmos monitores conectados. Se o hardware for diferente, o GNOME ignora o arquivo (valida contra o EDID) e cai no auto-detect.

Setup inicial (uma vez só):
```bash
sudo mkdir -p /etc/jailkit/skel
sudo cp /home/<usuario-modelo>/.config/monitors.xml /etc/jailkit/skel/monitors.xml
```

---

## 8. 💻 Comandos úteis de referência

### Extrair configs de um usuário modelo (rodar logado como ele, sessão gráfica ativa)
```bash
dconf dump /org/gnome/desktop/interface/
dconf dump /org/gnome/desktop/datetime/
dconf dump /org/gnome/desktop/wm/preferences/
dconf dump /org/gnome/shell/
dconf dump /org/gnome/shell/overrides/
dconf dump /org/gnome/mutter/
dconf dump /org/gnome/shell/extensions/dash-to-dock/
dconf dump /org/gnome/shell/extensions/ding/
dconf dump /org/gnome/shell/extensions/tiling-assistant/
cat ~/.config/monitors.xml
```

### Ler um valor específico
```bash
gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size
```

### Aplicar mudanças após editar `00-jail-defaults`
```bash
sudo dconf update
```

### Testar um valor num usuário específico
```bash
sudo -u <usuario> dconf read /org/gnome/shell/favorite-apps
```

### Resetar preferências pessoais de um usuário de teste (para o default do sistema valer)
```bash
sudo -u <usuario> dconf reset -f /
```
⚠️ Apaga TODAS as configs pessoais do usuário no dconf — usar só em ambiente de teste.

### Debug de variáveis vazias no script
```bash
configure_jailkit() {
    echo "DEBUG: JAIL_PATH='$JAIL_PATH' USERNAME='$USERNAME'"
    jk_jailuser -j "$JAIL_PATH" "$USERNAME"
}
```

---

## 9. ✅ Pendências / próximos passos

- [ ] Confirmar valor real de `dash-max-icon-size` no usuário modelo (`gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size`) e ajustar em `00-jail-defaults` se necessário (atualmente `32`)
- [ ] Investigar por que `configure_jailkit()` retornou `aborted, no username specified` — confirmar se o script instalado em `/usr/local/sbin/create-jail-user` é a versão mais recente editada:
  ```bash
  which create-jail-user
  cat "$(which create-jail-user)" | grep -A5 "configure_jailkit()"
  ```
- [ ] Revisar se `remove-jail-user` (dependência externa do script) não interfere em variáveis do processo pai
- [ ] Considerar mover `sudo systemctl start cpu-governor.service` (se ainda presente em alguma versão do `.bashrc`) para um serviço de boot do host, não no shell de login do usuário

---

## 📚 Referências

- 🔒 [jk_jailuser(8) — Ubuntu Manpage](https://manpages.ubuntu.com/manpages/noble/man8/jk_jailuser.8.html) — comando usado para associar o usuário à jail
- 🔒 [jk_jailuser(8) — Linux man page (die.net)](https://linux.die.net/man/8/jk_jailuser) — versão espelhada da manpage acima
- ⚠️ [jk_addjailuser(8) — Linux man page (deprecated)](https://linux.die.net/man/8/jk_addjailuser) — utilitário antigo, descontinuado, citado por ter suporte a skeleton dir
- 🐚 [jk_chrootsh(8) — Linux man page](https://linux.die.net/man/8/jk_chrootsh) — shell usado para executar o chroot do usuário jailado
- 📦 [jailkit(8) — utilities for jailing user/process](https://linux.die.net/man/8/jailkit) — visão geral de todos os utilitários do Jailkit
- 🗄️ [dconf(1) — Manual page (GNOME)](https://manpages.ubuntu.com/manpages/noble/man1/dconf.1.html) — comando usado para ler/exportar/aplicar configurações do GNOME
- ⚙️ [GNOME — Documentação de configuração via dconf/gsettings](https://help.gnome.org/admin/system-admin-guide/stable/dconf-keyfiles.html.en) — como definir defaults e locks do sistema
- 🖥️ [Ubuntu Dash to Dock (extensão GNOME Shell)](https://extensions.gnome.org/extension/307/dash-to-dock/) — extensão responsável pela barra de tarefas/dock