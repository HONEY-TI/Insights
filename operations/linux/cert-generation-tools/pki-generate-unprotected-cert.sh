#!/bin/bash
# gencert_public.sh
# Verifica se o número de argumentos passados é correto
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nome_do_arquivo>"
    exit 1
fi

arquivo_base=$1
chave_privada="${arquivo_base}.key"
certificado="${arquivo_base}.pem"
arquivo_pfx="${arquivo_base}.pfx"
cnf_file="Oem.cnf"

# Verifica se o arquivo de configuração Oem.cnf existe
if [ ! -f "$cnf_file" ]; then
    echo "Erro: Arquivo de configuração Oem.cnf não encontrado!"
    exit 1
fi

# Gera a chave privada sem senha se não existir
if [ ! -f "$chave_privada" ]; then
    echo "Gerando chave privada RSA sem senha..."
    openssl genpkey -algorithm RSA -out "$chave_privada" -pkeyopt rsa_keygen_bits:2048
    echo "Chave privada gerada: $chave_privada"
fi

# Gera o certificado autoassinado se não existir
if [ ! -f "$certificado" ]; then
    echo "Gerando certificado autoassinado usando Oem.cnf..."
    openssl req -x509 -new -key "$chave_privada" -out "$certificado" -days 365 -config "$cnf_file"
    echo "Certificado autoassinado gerado: $certificado"
fi

echo "Processo concluído."
