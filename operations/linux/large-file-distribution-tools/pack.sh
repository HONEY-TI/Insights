#!/bin/bash

# Checar se o arquivo foi passado como argumento
if [ -z "$1" ]; then
  echo "Por favor, forneça o caminho do primeiro arquivo .rar (ex: arquivo.rar.001)."
  exit 1
fi

# Variáveis
ARQUIVO="$1"
PASTA_DESTINO="./extraido"

# Verifica se o arquivo existe
if [ ! -f "$ARQUIVO" ]; then
  echo "Arquivo não encontrado!"
  exit 1
fi

# Cria a pasta de destino para extração
mkdir -p "$PASTA_DESTINO"

# Usa o comando `unrar` para descompactar os arquivos
# O `unrar` automaticamente irá buscar e juntar as partes .001, .002, etc.
unrar x "$ARQUIVO" "$PASTA_DESTINO/"

# Verifica se o comando foi bem-sucedido
if [ $? -eq 0 ]; then
  echo "✅ Descompactação concluída! Arquivos extraídos para: $PASTA_DESTINO"
else
  echo "❌ Ocorreu um erro durante a descompactação."
  exit 1
fi
