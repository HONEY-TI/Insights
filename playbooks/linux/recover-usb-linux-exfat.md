---
name: recover-usb-linux-exfat
description: Procedimento para recuperar, recriar partição GPT e formatar pendrive exFAT no Linux.
---

# 🔧 Recuperação e Formatação de Pendrive no Linux (exFAT)

## 🎯 Objetivo

Recuperar um pendrive que:
- não estava sendo reconhecido corretamente
- não montava no Linux
- apresentava erro de superbloco
- não possuía partição válida

---

# 🧩 1. Verificar Detecção do Dispositivo

Listar dispositivos conectados:

```bash
lsblk
````

Resultado esperado:

```text
sdc           8:32   1  57,8G  0 disk
└─sdc1        8:33   1  57,8G  0 part
```

Verificar detalhes do dispositivo:

```bash
sudo fdisk -l /dev/sdc
```

---

# 🚨 2. Problema Identificado

O sistema detectava apenas:

```text
/dev/sdc
```

Problemas encontrados:

* ausência de partição funcional
* `/dev/sdc1` inexistente
* falha de montagem
* erro de filesystem/superbloco

---

# 🏗️ 3. Recriar Tabela GPT

Abrir `fdisk`:

```bash
sudo fdisk /dev/sdc
```

## Criar tabela GPT

```text
g
```

## Criar partição

```text
n
```

Aceitar os valores padrão:

* número da partição
* primeiro setor
* último setor

Pressionar ENTER em todos.

## Salvar alterações

```text
w
```

---

# 🔍 4. Validar Partição Criada

Executar:

```bash
lsblk
```

Resultado esperado:

```text
sdc
└─sdc1
```

---

# 📦 5. Instalar Suporte exFAT

Atualizar repositórios:

```bash
sudo apt update
```

Instalar ferramentas:

```bash
sudo apt install exfatprogs
```

---

# 💽 6. Formatar o Pendrive

Formatar utilizando exFAT:

```bash
sudo mkfs.exfat /dev/sdc1
```

---

# 📁 7. Criar Diretório de Montagem

```bash
sudo mkdir -p /mnt/usb
```

---

# 🔗 8. Montar o Pendrive

```bash
sudo mount /dev/sdc1 /mnt/usb
```

---

# ✅ 9. Validar Montagem

Verificar:

```bash
df -h
```

ou:

```bash
ls /mnt/usb
```

---

# 🎉 Resultado Final

O pendrive:

* recebeu nova tabela GPT
* ganhou partição válida
* foi formatado em exFAT
* voltou a montar corretamente no Linux

---

# 📚 Observações Técnicas

## 📌 exFAT

Vantagens:

* compatível com Linux
* compatível com Windows
* compatível com Android
* suporta arquivos maiores que 4 GB

## 📌 GPT

Benefícios:

* mais moderno que MBR
* maior confiabilidade
* melhor compatibilidade com discos atuais

---

# 🧪 Comandos Utilizados

```bash
lsblk
sudo fdisk -l /dev/sdc
sudo fdisk /dev/sdc
sudo apt update
sudo apt install exfatprogs
sudo mkfs.exfat /dev/sdc1
sudo mkdir -p /mnt/usb
sudo mount /dev/sdc1 /mnt/usb
df -h
```
