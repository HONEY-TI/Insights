#!/usr/bin/env bash

# Normaliza nomes de arquivos (versão agressiva Linux-safe):
# - remove acentos
# - remove emojis e símbolos Unicode
# - remove caracteres invisíveis/control characters
# - converte para minúsculas
# - espaços e sequências viram hífen
# - mantém apenas: a-z 0-9 . _ -

excluir_tmp_arquivo() {
    [[ -f "$1" && "$(basename -- "$1")" == tmp* ]]
}

find . -depth | while IFS= read -r item; do
    dir=$(dirname -- "$item")
    base=$(basename -- "$item")

    # exclui APENAS arquivos tmp*
    if excluir_tmp_arquivo "$item"; then
        echo "❌ Removendo arquivo tmp:"
        echo "  $item"
        rm -f -- "$item"
        continue
    fi
    
    novo=$(echo "$base" \
        | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E '
            # remove emojis e símbolos estendidos (unicode não-ASCII)
            s/[^[:print:]]//g

            # remove caracteres invisíveis e de controle
            s/[\x00-\x1F\x7F]//g

            # substitui qualquer coisa fora do padrão seguro por -
            s/[^a-z0-9._-]+/-/g

            # colapsa múltiplos hífens
            s/-+/-/g

            # remove hífen no começo/fim
            s/^-+//g
            s/-+$//g

            # remove múltiplos pontos estranhos (evita "..")
            s/\.\.+/./g

            # remove espaços extras (caso iconv falhe)
            s/ +/-/g
        ')

    # fallback caso fique vazio
    if [[ -z "$novo" ]]; then
        novo="arquivo-sem-nome"
    fi

    if [[ "$base" != "$novo" ]]; then
        if [[ -e "$dir/$novo" ]]; then
            echo "Ignorado (já existe): $dir/$novo"
        else
            echo "Renomeando:"
            echo "  $item"
            echo "  -> $dir/$novo"
            mv -v -- "$item" "$dir/$novo"
        fi
    fi
done