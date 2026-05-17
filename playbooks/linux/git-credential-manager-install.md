# 🔐 Instalar Git Credential Manager + Login GitHub para Todos os Usuários

## 🎯 Objetivo

Instalar globalmente:

- Git
- Git Credential Manager (GCM)
- Integração com GitHub CLI (`gh`)
- Suporte para autenticação persistente HTTPS
- Disponível para todos os usuários do sistema e também dentro da JailKit

---

# 🧱 1. Instalar Dependências

```bash
sudo apt update

sudo apt install -y \
    git \
    gh \
    curl \
    gpg \
    pass


🧱 2. Instalar Git Credential Manager (GCM)
Baixar última versão Linux
VERSION=2.6.1

wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v${VERSION}/gcm-linux_amd64.${VERSION}.deb
Instalar
sudo dpkg -i gcm-linux_amd64.${VERSION}.deb
Corrigir dependências se necessário
sudo apt --fix-broken install -y
🧱 3. Configurar GCM Globalmente
Configurar como helper padrão do Git
sudo git config --system credential.helper manager
Configurar provider GitHub
sudo git config --system credential.credentialStore secretservice
🧱 4. Verificar Instalação
git credential-manager version
🧱 5. Login GitHub para Cada Usuário

O login é individual por usuário.

Cada usuário deve executar:

gh auth login

ou:

git credential-manager github login
🧱 6. Disponibilizar Dentro da JailKit

Copiar binários necessários:

Git
sudo jk_cp -j /home/jail $(which git)
Git Credential Manager
sudo jk_cp -j /home/jail $(which git-credential-manager)
GitHub CLI
sudo jk_cp -j /home/jail $(which gh)
🧱 7. Copiar Dependências Extras do GCM

O GCM usa bibliotecas .NET e dependências adicionais.

Copiar automaticamente:

sudo ldd $(which git-credential-manager)

Se faltar alguma dentro da jail:

sudo jk_cp -j /home/jail /caminho/da/lib.so
🧱 8. Inicializar Configuração Git no Skeleton
Criar configuração global padrão
sudo mkdir -p /home/skel-jail/.config/git
Configurar helper padrão
sudo git config --file /home/skel-jail/.gitconfig credential.helper manager
🧱 9. Testar

Dentro da jail:

git clone https://github.com/usuario/repositorio.git

O GCM deverá abrir autenticação automaticamente.    