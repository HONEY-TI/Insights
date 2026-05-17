#!/bin/bash

# Verifica se o diretório foi passado como argumento
if [ -z "$1" ]; then
  echo "Por favor, forneça o diretório contendo as partes."
  exit 1
fi

# Variáveis
PASTA="$1"
NOME_ARQUIVO=$(basename "$PASTA")
NOME_ARQUIVO_COMPLETO="$NOME_ARQUIVO.mp4"
ARQUIVOS=("$PASTA"/part_*.mp4)

# Verifica se o diretório existe e contém as partes
if [ ! -d "$PASTA" ]; then
  echo "Diretório não encontrado!"
  exit 1
fi

# Verifica se existem partes no diretório
if [ ${#ARQUIVOS[@]} -eq 0 ]; then
  echo "Nenhum arquivo de vídeo encontrado na pasta!"
  exit 1
fi

# Cria uma lista de arquivos para o ffmpeg
echo "Criando lista de arquivos para o ffmpeg..."
for arquivo in "${ARQUIVOS[@]}"; do
  echo "file '$arquivo'" >> lista.txt
done

# Combina os arquivos com o ffmpeg
echo "Combinando as partes do vídeo..."
ffmpeg -f concat -safe 0 -i lista.txt -c copy "$NOME_ARQUIVO_COMPLETO"

# Limpa o arquivo de lista
rm lista.txt

echo "Vídeo descompactado com sucesso: $NOME_ARQUIVO_COMPLETO"
