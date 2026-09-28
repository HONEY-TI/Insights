# Diretórios principais do Linux

Este documento apresenta os principais diretórios encontrados na raiz (`/`) de um sistema Linux e suas respectivas finalidades.

## Estrutura básica

A raiz do sistema de arquivos Linux é representada por `/`.

Uma instalação típica pode apresentar uma estrutura semelhante:

```text
/
├── bin
├── boot
├── boot-sav
├── dev
├── etc
├── home
├── lib
├── lib64
├── lost+found
├── media
├── mnt
├── opt
├── proc
├── root
├── run
├── sbin
├── srv
├── sys
├── tmp
├── usr
├── var
├── initrd.img
├── initrd.img.old
├── vmlinuz
└── vmlinuz.old
```

---

## `/bin`

Contém programas e comandos essenciais do sistema.

Exemplos:

```text
ls
cp
mv
cat
bash
```

Em sistemas Linux modernos, `/bin` pode ser um link simbólico para `/usr/bin`, devido à organização conhecida como `usr-merge`.

Verifique:

```bash
ls -ld /bin
```

---

## `/boot`

Contém arquivos necessários para o processo de inicialização do sistema.

Pode conter:

```text
vmlinuz
initrd.img
grub/
config-*
System.map-*
```

O diretório também pode conter arquivos utilizados pelo GRUB, o bootloader normalmente utilizado para iniciar o Linux.

Verifique:

```bash
ls -lah /boot
```

---

## `/boot-sav`

Não é um diretório padrão obrigatório do Linux.

Pode aparecer em sistemas que possuem ferramentas de recuperação ou backup relacionadas ao processo de boot.

Para verificar:

```bash
ls -ld /boot-sav
```

Para descobrir qual pacote criou o diretório:

```bash
dpkg -S /boot-sav 2>/dev/null
```

---

## `/dev`

Contém representações dos dispositivos disponíveis no sistema.

O Linux representa muitos dispositivos como arquivos dentro de `/dev`.

Exemplos:

```text
/dev/sda
/dev/nvme0n1
/dev/tty
/dev/null
/dev/random
/dev/urandom
```

Pode representar:

- discos;
- partições;
- terminais;
- dispositivos USB;
- dispositivos de entrada;
- dispositivos virtuais;
- interfaces especiais fornecidas pelo kernel.

Verifique:

```bash
ls -lah /dev
```

---

## `/etc`

Contém arquivos de configuração do sistema e dos serviços.

Exemplos:

```text
/etc/passwd
/etc/hosts
/etc/fstab
/etc/ssh/
/etc/systemd/
/etc/network/
```

É um dos diretórios mais importantes para administração Linux.

Regra prática:

```text
/etc → configurações
```

Verifique:

```bash
ls -lah /etc
```

---

## `/home`

Contém os diretórios pessoais dos usuários comuns.

Exemplo:

```text
/home/
└── sadmin/
    ├── Desktop/
    ├── Documents/
    ├── Downloads/
    └── ...
```

Verifique:

```bash
ls -lah /home
```

Para visualizar o diretório pessoal do usuário atual:

```bash
echo "$HOME"
```

Regra prática:

```text
/home → usuários comuns
```

---

## `/lib`

Contém bibliotecas compartilhadas essenciais utilizadas pelos programas e pelo sistema.

Em sistemas modernos, `/lib` pode ser um link simbólico ou estar integrado à estrutura `/usr/lib`.

Verifique:

```bash
ls -ld /lib
```

---

## `/lib64`

Historicamente utilizado para bibliotecas compartilhadas específicas de sistemas 64-bit.

Em sistemas modernos com `usr-merge`, também pode ser um link simbólico relacionado à estrutura `/usr/lib`.

Verifique:

```bash
ls -ld /lib64
```

---

## `/lost+found`

Pode existir em filesystems como `ext4`.

É utilizado pelo sistema de arquivos para armazenar arquivos ou fragmentos recuperados durante operações de verificação e recuperação, por exemplo, através do `fsck`.

Verifique:

```bash
ls -lah /lost+found
```

Se estiver vazio, isso é normal.

---

## `/media`

É utilizado como ponto de montagem para mídias removíveis.

Exemplos:

```text
USB
CD/DVD
discos removíveis
```

Verifique:

```bash
ls -lah /media
```

---

## `/mnt`

É um diretório tradicionalmente utilizado para montagens temporárias ou manuais.

Exemplo:

```bash
sudo mount /dev/sdb1 /mnt
```

Depois:

```bash
ls -lah /mnt
```

Regra prática:

```text
/mnt → montagens manuais ou temporárias
```

---

## `/opt`

Destinado a softwares adicionais que não fazem necessariamente parte da instalação padrão da distribuição.

Uma aplicação de terceiros pode utilizar:

```text
/opt/aplicacao/
```

Verifique:

```bash
ls -lah /opt
```

Regra prática:

```text
/opt → software adicional
```

---

## `/proc`

É um filesystem virtual fornecido pelo kernel Linux.

Apresenta informações sobre:

- processos;
- CPU;
- memória;
- kernel;
- dispositivos;
- parâmetros do sistema.

Exemplos:

```text
/proc/cpuinfo
/proc/meminfo
/proc/version
/proc/1/
```

Exemplo:

```bash
cat /proc/meminfo
```

Ou:

```bash
cat /proc/cpuinfo
```

Os arquivos de `/proc` não devem ser entendidos como arquivos normais armazenados no disco. Grande parte dessas informações é produzida dinamicamente pelo kernel.

Regra prática:

```text
/proc → processos e informações do kernel
```

---

## `/root`

É o diretório pessoal do usuário `root`.

Não deve ser confundido com `/`.

```text
/      → raiz do filesystem
/root  → home do usuário root
```

Verifique:

```bash
sudo ls -lah /root
```

---

## `/run`

Contém informações temporárias relacionadas ao estado atual do sistema em execução.

Pode conter:

```text
/run/systemd/
/run/user/
/run/lock/
/run/udev/
```

Também podem existir:

```text
PID
sockets
sessões
serviços
locks
estado de processos
```

Em muitas distribuições modernas, `/run` utiliza `tmpfs`.

Verifique:

```bash
findmnt /run
```

E:

```bash
df -h /run
```

Regra prática:

```text
/run → estado temporário do sistema em execução
```

---

## `/sbin`

Tradicionalmente contém comandos utilizados principalmente para administração do sistema.

Em sistemas modernos, `/sbin` pode ser um link para `/usr/sbin`.

Verifique:

```bash
ls -ld /sbin
```

Regra prática:

```text
/sbin → ferramentas administrativas
```

---

## `/srv`

Destinado a dados fornecidos por serviços do sistema.

Exemplos conceituais:

```text
/srv/www/
/srv/ftp/
```

O uso específico depende da aplicação e da configuração do administrador.

Regra prática:

```text
/srv → dados disponibilizados por serviços
```

---

## `/sys`

É outro filesystem virtual fornecido pelo kernel Linux.

O `sysfs` apresenta informações sobre:

- hardware;
- dispositivos;
- drivers;
- barramentos;
- subsistemas;
- parâmetros relacionados aos dispositivos.

Pode conter:

```text
/sys/block
/sys/class
/sys/devices
/sys/firmware
/sys/kernel
```

Verifique:

```bash
ls /sys
```

Regra prática:

```text
/sys → hardware, dispositivos e kernel
```

---

## `/tmp`

Destinado a arquivos temporários.

Programas e usuários podem criar arquivos temporários nesse diretório.

Verifique:

```bash
ls -lah /tmp
```

Arquivos em `/tmp` não devem ser considerados armazenamento permanente.

Dependendo da configuração do sistema, seu conteúdo pode ser removido durante a inicialização ou por mecanismos de limpeza do sistema.

Regra prática:

```text
/tmp → arquivos temporários
```

---

## `/usr`

Contém grande parte dos programas, bibliotecas e recursos utilizados pelo sistema.

Diretórios importantes:

```text
/usr/bin
/usr/sbin
/usr/lib
/usr/share
/usr/include
```

Exemplo:

```bash
ls /usr/bin
```

Ou:

```bash
ls /usr/share
```

Regra prática:

```text
/usr → programas e recursos do sistema
```

Em sistemas modernos com `usr-merge`, vários diretórios tradicionais da raiz, como `/bin`, `/sbin` e `/lib`, podem apontar para locais dentro de `/usr`.

---

## `/var`

Contém dados que variam durante a operação do sistema.

Exemplos:

```text
/var/log/
/var/cache/
/var/lib/
/var/tmp/
/var/spool/
```

### `/var/log`

Contém muitos dos logs do sistema e dos serviços.

```bash
ls -lah /var/log
```

### `/var/cache`

Contém caches utilizados por programas e serviços.

### `/var/lib`

Contém dados persistentes utilizados por aplicações e serviços.

### `/var/spool`

Pode conter filas de processamento, impressão, e-mail e outros mecanismos semelhantes.

Regra prática:

```text
/var → dados que mudam durante a operação do sistema
```

---

# Arquivos de inicialização

Além dos diretórios, o sistema pode apresentar alguns arquivos diretamente na raiz.

## `/initrd.img`

Normalmente é um link simbólico para uma imagem `initramfs` utilizada durante o processo de inicialização.

Verifique:

```bash
ls -l /initrd.img
```

---

## `/initrd.img.old`

Normalmente representa ou aponta para uma versão anterior da imagem `initramfs`.

Verifique:

```bash
ls -l /initrd.img.old
```

---

## `/vmlinuz`

Normalmente é um link simbólico para o kernel Linux utilizado no boot.

Verifique:

```bash
ls -l /vmlinuz
```

O arquivo apontado normalmente estará relacionado a um kernel dentro de:

```text
/boot/
```

---

## `/vmlinuz.old`

Normalmente aponta para uma versão anterior do kernel Linux.

Verifique:

```bash
ls -l /vmlinuz.old
```

A disponibilidade depende dos kernels instalados e da configuração do sistema.

---

# Resumo

## Configuração

```text
/etc
```

```text
/etc → configurações do sistema e dos serviços
```

## Usuários

```text
/home
/root
```

```text
/home → usuários comuns
/root → usuário root
```

## Programas

```text
/bin
/sbin
/usr/bin
/usr/sbin
/usr/lib
```

```text
/usr → programas e recursos do sistema
```

## Kernel e hardware

```text
/dev
/proc
/sys
```

```text
/dev  → dispositivos
/proc → processos e kernel
/sys  → hardware e kernel
```

## Estado temporário

```text
/run
/tmp
```

```text
/run → estado atual do sistema
/tmp → arquivos temporários
```

## Dados variáveis

```text
/var
```

```text
/var → logs, cache, dados de serviços e filas
```

## Inicialização

```text
/boot
```

```text
/boot → arquivos necessários para iniciar o sistema
```

## Montagens

```text
/media
/mnt
```

```text
/media → mídias removíveis
/mnt   → montagens manuais ou temporárias
```

## Software adicional

```text
/opt
```

```text
/opt → aplicações adicionais
```

## Serviços

```text
/srv
```

```text
/srv → dados disponibilizados por serviços
```

---

# Comandos úteis para estudar

Ver todos os diretórios da raiz:

```bash
ls -lah /
```

Descobrir se algo é um link simbólico:

```bash
ls -ld /bin /sbin /lib /lib64
```

Ver os filesystems montados:

```bash
findmnt
```

Ver espaço utilizado:

```bash
df -h
```

Ver o tamanho dos diretórios da raiz:

```bash
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h
```

Restringir a análise ao filesystem raiz:

```bash
sudo du -xhx --max-depth=1 / 2>/dev/null | sort -h
```

Ver somente os diretórios diretamente abaixo de `/`:

```bash
find / -maxdepth 1 -type d -print
```

---

# Regra mental final

```text
/boot   → inicialização
/bin    → comandos
/dev    → dispositivos
/etc    → configurações
/home   → usuários
/lib    → bibliotecas
/media  → mídias
/mnt    → montagens
/opt    → software adicional
/proc   → processos/kernel
/root   → home do root
/run    → estado/runtime
/sbin   → administração
/srv    → dados de serviços
/sys    → hardware/kernel
/tmp    → temporários
/usr    → programas/recursos
/var    → dados variáveis
```

> **Observação:** a estrutura e o conteúdo podem variar entre distribuições Linux e configurações. Em sistemas com `usr-merge`, `/bin`, `/sbin` e `/lib*` podem ser links simbólicos ou estar integrados à estrutura `/usr`.