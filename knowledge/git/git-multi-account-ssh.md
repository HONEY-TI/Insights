---
name: git-multi-account-ssh
description: Padrão DevOps profissional para configuração e operação de múltiplas identidades Git via SSH, utilizando chaves SSH independentes, aliases definidos em ~/.ssh/config, known_hosts e múltiplos destinos de push para contas distintas do GitHub e GitLab, garantindo autenticação explícita, isolamento de identidades e sincronização reprodutível entre repositórios.
---

# 🔐 Git Multi-Account SSH & Multi-Remote Push

## 🎯 Objetivo

Configurar o Git para trabalhar simultaneamente com:

- 👤 Duas contas GitHub diferentes;
- 🦊 Uma conta GitLab;
- 🔑 Uma chave SSH independente para cada usuário;
- 🧩 Aliases SSH para selecionar a identidade correta;
- 🚀 Um único `git push` para múltiplos repositórios.

---

# 👥 1. Usuários utilizados na documentação

Esta documentação utiliza usuários fictícios.

## 🐙 GitHub — Usuário 1

```text
Usuário: alice-dev
E-mail: alice@example.com
Repositório: alice-dev/project.git
Chave SSH: ~/.ssh/id_ed25519_alice
Alias SSH: github-alice
```

---

## 🐙 GitHub — Usuário 2

```text
Usuário: bob-dev
E-mail: bob@example.com
Repositório: bob-dev/project.git
Chave SSH: ~/.ssh/id_ed25519_bob
Alias SSH: github-bob
```

---

## 🦊 GitLab — Usuário 3

```text
Usuário: charlie-dev
E-mail: charlie@example.com
Repositório: charlie-dev/project.git
Chave SSH: ~/.ssh/id_ed25519_charlie
Alias SSH: gitlab-charlie
```

---

# 🧭 2. Arquitetura da configuração

A configuração final será:

```text
                         💻 Máquina Local
                               │
                               ▼
                        📁 ~/.ssh/
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
      🔑 Alice              🔑 Bob              🔑 Charlie
          │                    │                    │
          ▼                    ▼                    ▼
   github-alice        github-bob          gitlab-charlie
          │                    │                    │
          ▼                    ▼                    ▼
      🐙 GitHub            🐙 GitHub            🦊 GitLab
          │                    │                    │
          ▼                    ▼                    ▼
    alice-dev/project   bob-dev/project   charlie-dev/project
```

---

# 📁 3. Estrutura do diretório SSH

O diretório SSH normalmente está localizado em:

```text
~/.ssh/
```

A estrutura final será:

```text
~/.ssh/
├── 🔑 id_ed25519_alice
├── 🔓 id_ed25519_alice.pub
│
├── 🔑 id_ed25519_bob
├── 🔓 id_ed25519_bob.pub
│
├── 🔑 id_ed25519_charlie
├── 🔓 id_ed25519_charlie.pub
│
├── ⚙️ config
└── 🧾 known_hosts
```

Cada usuário possui:

```text
🔐 Chave privada
        +
📤 Chave pública
        +
🧩 Alias SSH
```

---

# 🛠️ 4. Criar o diretório `.ssh`

Caso o diretório ainda não exista:

```bash
mkdir -p ~/.ssh
```

Aplicar permissões corretas:

```bash
chmod 700 ~/.ssh
```

---

# 🔑 5. Criar a chave SSH do usuário Alice

Execute:

```bash
ssh-keygen -t ed25519 \
    -C "alice@example.com" \
    -f ~/.ssh/id_ed25519_alice
```

O comando criará:

```text
~/.ssh/id_ed25519_alice
```

Chave privada:

```text
🔐 ~/.ssh/id_ed25519_alice
```

Chave pública:

```text
📤 ~/.ssh/id_ed25519_alice.pub
```

Aplicar permissões:

```bash
chmod 600 ~/.ssh/id_ed25519_alice
chmod 644 ~/.ssh/id_ed25519_alice.pub
```

---

# 🔑 6. Criar a chave SSH do usuário Bob

Execute:

```bash
ssh-keygen -t ed25519 \
    -C "bob@example.com" \
    -f ~/.ssh/id_ed25519_bob
```

Arquivos criados:

```text
🔐 ~/.ssh/id_ed25519_bob
📤 ~/.ssh/id_ed25519_bob.pub
```

Aplicar permissões:

```bash
chmod 600 ~/.ssh/id_ed25519_bob
chmod 644 ~/.ssh/id_ed25519_bob.pub
```

---

# 🔑 7. Criar a chave SSH do usuário Charlie

Execute:

```bash
ssh-keygen -t ed25519 \
    -C "charlie@example.com" \
    -f ~/.ssh/id_ed25519_charlie
```

Arquivos criados:

```text
🔐 ~/.ssh/id_ed25519_charlie
📤 ~/.ssh/id_ed25519_charlie.pub
```

Aplicar permissões:

```bash
chmod 600 ~/.ssh/id_ed25519_charlie
chmod 644 ~/.ssh/id_ed25519_charlie.pub
```

---

# 📋 8. Verificar as chaves criadas

Execute:

```bash
ls -la ~/.ssh
```

Resultado esperado:

```text
~/.ssh/
├── id_ed25519_alice
├── id_ed25519_alice.pub
├── id_ed25519_bob
├── id_ed25519_bob.pub
├── id_ed25519_charlie
└── id_ed25519_charlie.pub
```

---

# 📤 9. Obter as chaves públicas

As chaves públicas devem ser adicionadas às respectivas contas.

## 👤 Alice

```bash
cat ~/.ssh/id_ed25519_alice.pub
```

Adicionar a chave pública à conta:

```text
🐙 GitHub
└── alice-dev
```

---

## 👤 Bob

```bash
cat ~/.ssh/id_ed25519_bob.pub
```

Adicionar a chave pública à conta:

```text
🐙 GitHub
└── bob-dev
```

---

## 👤 Charlie

```bash
cat ~/.ssh/id_ed25519_charlie.pub
```

Adicionar a chave pública à conta:

```text
🦊 GitLab
└── charlie-dev
```

---

# ⚙️ 10. Configurar o SSH Agent

Iniciar o SSH Agent:

```bash
eval "$(ssh-agent -s)"
```

Adicionar a chave da Alice:

```bash
ssh-add ~/.ssh/id_ed25519_alice
```

Adicionar a chave do Bob:

```bash
ssh-add ~/.ssh/id_ed25519_bob
```

Adicionar a chave do Charlie:

```bash
ssh-add ~/.ssh/id_ed25519_charlie
```

Verificar as chaves carregadas:

```bash
ssh-add -l
```

Resultado esperado:

```text
🔑 id_ed25519_alice
👤 alice-dev

🔑 id_ed25519_bob
👤 bob-dev

🔑 id_ed25519_charlie
👤 charlie-dev
```

---

# 🧩 11. Criar o arquivo `~/.ssh/config`

O arquivo:

```text
~/.ssh/config
```

é responsável por associar:

```text
🧩 Alias SSH
      ↓
🌐 Host real
      ↓
🔑 Chave privada
```

Criar ou editar:

```bash
nano ~/.ssh/config
```

---

# 📄 12. Arquivo completo `~/.ssh/config`

O arquivo final deverá ser:

```ssh
# 🐙 GitHub - Alice
Host github-alice
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_alice
    IdentitiesOnly yes


# 🐙 GitHub - Bob
Host github-bob
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_bob
    IdentitiesOnly yes


# 🦊 GitLab - Charlie
Host gitlab-charlie
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_charlie
    IdentitiesOnly yes
```

Aplicar permissão:

```bash
chmod 600 ~/.ssh/config
```
Essa configuração significa:

```text
                        📁 ~/.ssh/
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
      🔑 Alice              🔑 Bob              🔑 Charlie
          │                    │                    │
          ▼                    ▼                    ▼
   id_ed25519_alice     id_ed25519_bob     id_ed25519_charlie
          │                    │                    │
          ▼                    ▼                    ▼
    👤 alice-dev         👤 charlie-dev        👤 bob-dev
          │                    │                    │
          ▼                    ▼                    ▼
      🐙 GitHub            🐙 GitHub            🦊 GitLab


```

---


# 🧾 13. Arquivo `known_hosts`

O arquivo:

```text
~/.ssh/known_hosts
```

armazena as chaves públicas dos servidores SSH conhecidos.

Exemplo:

```text
~/.ssh/known_hosts
```

Quando você executa pela primeira vez:

```bash
ssh -T git@github-alice
```

o SSH pode perguntar:

```text
The authenticity of host 'github.com' can't be established.
Are you sure you want to continue connecting?
```

Após confirmar:

```text
yes
```

o host será salvo em:

```text
~/.ssh/known_hosts
```

---

# 🔍 14. Verificar o arquivo `known_hosts`

Execute:

```bash
cat ~/.ssh/known_hosts
```

O arquivo poderá conter entradas para:

```text
github.com
gitlab.com
```

Os aliases:

```text
github-alice
github-bob
gitlab-charlie
```

continuam apontando para os hosts reais:

```text
github.com
gitlab.com
```

---

# 🧪 15 Testar a conta GitHub da Alice

Execute:

```bash
ssh -T git@github-alice
```

Resultado esperado:

```text
Hi alice-dev! You've successfully authenticated,
but GitHub does not provide shell access.
```

---

# 🧪 16. Testar a conta GitHub do Bob

Execute:

```bash
ssh -T git@github-bob
```

Resultado esperado:

```text
Hi bob-dev! You've successfully authenticated,
but GitHub does not provide shell access.
```

---

# 🧪 17. Testar a conta GitLab do Charlie

Execute:

```bash
ssh -T git@gitlab-charlie
```

Resultado esperado semelhante a:

```text
Welcome to GitLab, @charlie-dev!
```

---

# 🔗 18. Configurar o Git Remote

O ponto mais importante é:

> O Git Remote precisa usar o alias SSH correto.

---

## 🐙 Repositório da Alice

❌ Incorreto:

```text
git@github.com:alice-dev/project.git
```

✅ Correto:

```text
git@github-alice:alice-dev/project.git
```

---

## 🐙 Repositório do Bob

❌ Incorreto:

```text
git@github.com:bob-dev/project.git
```

✅ Correto:

```text
git@github-bob:bob-dev/project.git
```

---

## 🦊 Repositório do Charlie

❌ Incorreto:

```text
git@gitlab.com:charlie-dev/project.git
```

✅ Correto:

```text
git@gitlab-charlie:charlie-dev/project.git
```

---

# 🚀 19. Configurar múltiplos destinos de push

É possível utilizar um único remote:

```text
origin
```

com múltiplas URLs de push.

Exemplo:

```text
origin
├── 🐙 GitHub - Alice
├── 🐙 GitHub - Bob
└── 🦊 GitLab - Charlie
```

---

# 🧹 20. Remover o `origin` existente

Caso o remote esteja configurado incorretamente:

```bash
git remote remove origin
```

---

# 🔗 21. Adicionar o primeiro repositório

Adicionar o repositório da Alice como URL principal:

```bash
git remote add origin \
git@github-alice:alice-dev/project.git
```

Essa URL será utilizada como:

```text
📥 Fetch
```

e também como:

```text
📤 Push principal
```

---

# 🐙 22. Adicionar o repositório do Bob como destino de push

```bash
git remote set-url --add --push origin \
git@github-bob:bob-dev/project.git
```

---

# 🦊 23. Adicionar o repositório do Charlie como destino de push

```bash
git remote set-url --add --push origin \
git@gitlab-charlie:charlie-dev/project.git
```

---

# 🔍 24. Validar os remotes

Execute:

```bash
git remote -v
```

Resultado esperado:

```text
origin  git@github-alice:alice-dev/project.git (fetch)

origin  git@github-alice:alice-dev/project.git (push)

origin  git@github-bob:bob-dev/project.git (push)

origin  git@gitlab-charlie:charlie-dev/project.git (push)
```

---

# 🚀 25. Fazer push para os três repositórios

Execute:

```bash
git push
```

O Git enviará o conteúdo para:

```text
🚀 GitHub
└── 👤 alice-dev
    └── 📦 project

🚀 GitHub
└── 👤 bob-dev
    └── 📦 project

🚀 GitLab
└── 👤 charlie-dev
    └── 📦 project
```

Fluxo:

```text
                         💻 Workspace
                              │
                              ▼
                           git push
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
        🐙 GitHub       🐙 GitHub        🦊 GitLab
              │               │               │
              ▼               ▼               ▼
          👤 Alice         👤 Bob        👤 Charlie
              │               │               │
              ▼               ▼               ▼
           project         project         project
```

---

# 🌿 26. Configurar o upstream da branch

Para configurar a branch:

```bash
git push --set-upstream origin main
```

Ou:

```bash
git push -u origin main
```

Depois disso, o comando:

```bash
git push
```

poderá ser utilizado normalmente.

---

# ❌ 27. Diagnóstico de erro de permissão

## Erro

```text
ERROR: Permission to alice-dev/project.git denied to bob-dev.
```

---

## 🔎 Causa

O Git está utilizando a identidade errada.

Exemplo:

```text
🔗 Remote
    │
    ▼
git@github.com
    │
    ▼
🔑 Chave padrão
    │
    ▼
👤 bob-dev
    │
    ▼
❌ Tentativa de acessar o repositório de Alice
```

---

## ✅ Solução

O remote precisa usar o alias correto:

```text
git@github-alice:alice-dev/project.git
```

Fluxo:

```text
🔗 Git Remote
      │
      ▼
🧩 github-alice
      │
      ▼
🔑 id_ed25519_alice
      │
      ▼
👤 alice-dev
      │
      ▼
📦 alice-dev/project
      │
      ▼
✅ Acesso permitido
```

---

# 🔍 28. Diagnóstico detalhado do SSH

Para verificar qual chave está sendo utilizada:

```bash
ssh -vT git@github-alice
```

Procure por:

```text
Offering public key:
```

Exemplo:

```text
Offering public key:
~/.ssh/id_ed25519_alice
```

E:

```text
Server accepts key:
```

Isso confirma:

```text
🔑 Chave utilizada
        ↓
👤 Usuário autenticado
        ↓
📦 Repositório acessado
```

---

# 🧪 29. Diagnóstico detalhado do Git

Execute:

```bash
GIT_TRACE=1 \
GIT_SSH_COMMAND="ssh -v" \
git push
```

Esse comando permite visualizar:

```text
🔗 Remote utilizado
        ↓
🧩 Host SSH utilizado
        ↓
🔑 Chave oferecida
        ↓
👤 Usuário autenticado
```

---

# 🧰 30. Comandos úteis

## 📁 Listar arquivos SSH

```bash
ls -la ~/.ssh
```

---

## 🔑 Listar chaves carregadas

```bash
ssh-add -l
```

---

## 🧪 Testar Alice

```bash
ssh -T git@github-alice
```

---

## 🧪 Testar Bob

```bash
ssh -T git@github-bob
```

---

## 🧪 Testar Charlie

```bash
ssh -T git@gitlab-charlie
```

---

## 🌐 Ver os remotes

```bash
git remote -v
```

---

## 📤 Ver URLs de push

```bash
git config --get-all remote.origin.pushurl
```

---

## 📥 Ver a URL de fetch

```bash
git config --get remote.origin.url
```

---

## 🧾 Ver hosts conhecidos

```bash
cat ~/.ssh/known_hosts
```

---

# 🔄 31. Recriar toda a configuração

Caso a configuração fique inconsistente:

```bash
git remote remove origin
```

Adicionar Alice:

```bash
git remote add origin \
git@github-alice:alice-dev/project.git
```

Adicionar Bob:

```bash
git remote set-url --add --push origin \
git@github-bob:bob-dev/project.git
```

Adicionar Charlie:

```bash
git remote set-url --add --push origin \
git@gitlab-charlie:charlie-dev/project.git
```

Validar:

```bash
git remote -v
```

Depois:

```bash
git push
```

---

# 🧭 32. Fluxo completo de autenticação

```text
┌───────────────────────────────┐
│ 📦 Git Repository              │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 🔗 Git Remote                  │
│ git@github-alice:...           │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 🧩 SSH Alias                  │
│ github-alice                  │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ ⚙️ ~/.ssh/config               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 🔑 IdentityFile                │
│ id_ed25519_alice               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 🔐 Private Key                 │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 👤 GitHub Account              │
│ alice-dev                      │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ ✅ Repository Access           │
└───────────────────────────────┘
```

---

# 🧠 33. Regra principal

Para utilizar múltiplas contas SSH no mesmo computador:

```text
🔑 Chave SSH
      +
🧩 Alias SSH
      +
⚙️ ~/.ssh/config
      +
🔗 Git Remote usando o alias
```

Exemplo:

```text
🔑 Chave:

~/.ssh/id_ed25519_alice


        │
        ▼


🧩 Alias:

github-alice


        │
        ▼


⚙️ Configuração:

IdentityFile ~/.ssh/id_ed25519_alice


        │
        ▼


🔗 Remote:

git@github-alice:alice-dev/project.git


        │
        ▼


👤 Usuário:

alice-dev


        │
        ▼


✅ Acesso ao repositório
```

---

# ⚠️ 34. Regra de ouro

Criar uma chave SSH não é suficiente.

O fluxo completo é:

```text
🔑 Criar chave
      │
      ▼
📤 Adicionar chave pública à conta correta
      │
      ▼
⚙️ Configurar ~/.ssh/config
      │
      ▼
🧩 Criar alias SSH
      │
      ▼
🔗 Usar o alias no Git Remote
      │
      ▼
🧾 Registrar o host em known_hosts
      │
      ▼
🧪 Testar a autenticação
      │
      ▼
🚀 Executar git push
```

---

# ✅ Configuração final

## 👥 Usuários

```text
🐙 GitHub
└── alice-dev

🐙 GitHub
└── bob-dev

🦊 GitLab
└── charlie-dev
```

---

## 🔑 Chaves

```text
~/.ssh/id_ed25519_alice
└── 👤 alice-dev

~/.ssh/id_ed25519_bob
└── 👤 bob-dev

~/.ssh/id_ed25519_charlie
└── 👤 charlie-dev
```

---

## 🧩 Aliases

```text
github-alice
└── 🔑 id_ed25519_alice

github-bob
└── 🔑 id_ed25519_bob

gitlab-charlie
└── 🔑 id_ed25519_charlie
```

---

## 🔗 Git Remotes

```text
🐙 GitHub Alice:

git@github-alice:alice-dev/project.git
```

```text
🐙 GitHub Bob:

git@github-bob:bob-dev/project.git
```

```text
🦊 GitLab Charlie:

git@gitlab-charlie:charlie-dev/project.git
```

---

## 🚀 Push múltiplo

```bash
git push
```

Resultado:

```text
💻 Workspace
      │
      ├── 🚀 GitHub
      │   └── 👤 alice-dev/project
      │
      ├── 🚀 GitHub
      │   └── 👤 bob-dev/project
      │
      └── 🚀 GitLab
          └── 👤 charlie-dev/project
```