#!/bin/bash
# gencert_private
# Verifica se o número de argumentos passados é correto
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nome_do_arquivo>"
    exit 1
fi

arquivo_base=$1
chave_privada="${arquivo_base}_chave.pem"
certificado="${arquivo_base}_cert.pem"
arquivo_pfx="${arquivo_base}.pfx"

# Gera a chave privada se não existir
if [ ! -f "$chave_privada" ]; then
    echo "Gerando chave privada RSA..."
    openssl genpkey -algorithm RSA -out "$chave_privada" -aes256
    echo "Chave privada gerada: $chave_privada"
fi

# Gera o certificado autoassinado se não existir
if [ ! -f "$certificado" ]; then
    echo "Gerando certificado autoassinado..."
    openssl req -x509 -new -key "$chave_privada" -out "$certificado" -days 365
    echo "Certificado autoassinado gerado: $certificado"
fi

# Gera o arquivo PFX se a chave privada e o certificado existirem
if [ -f "$chave_privada" ] && [ -f "$certificado" ]; then
    echo "Gerando arquivo PFX..."
    openssl pkcs12 -export -out "$arquivo_pfx" -inkey "$chave_privada" -in "$certificado"
    echo "Arquivo PFX gerado: $arquivo_pfx"
else
    echo "Erro: Chave privada ou certificado não encontrados."
    exit 1
fi

echo "Processo concluído."
