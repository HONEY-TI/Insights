#!/bin/bash
set -euo pipefail

files=$(git status --porcelain=v1 -uall | awk '{print $2}' | sort -u)

if [ -z "${files}" ]; then
  echo "Nenhuma alteração encontrada."
  exit 0
fi

for file in $files; do
  status=$(git status --porcelain "$file" | awk '{print $1}' | head -1 || true)

  diff_content=$(git diff "$file" 2>/dev/null || git diff --cached "$file" 2>/dev/null || true)

  case "$status" in
    A|"??") tipo="feat";    acao="adicionar" ;;
    M)      tipo="fix";     acao="atualizar" ;;
    D)      tipo="chore";   acao="remover"   ;;
    *)      tipo="chore";   acao="atualizar" ;;
  esac

  if echo "$diff_content" | grep -qiE "\.test\.|\.spec\.|describe\(|it\(|test\("; then
    tipo="test"
    acao="atualizar testes em"
  elif echo "$diff_content" | grep -qiE "README|\.md$|\/docs\/|documentation"; then
    tipo="docs"
    acao="atualizar documentação em"
  elif echo "$diff_content" | grep -qiE "package\.json|\.env|\.config\.|tsconfig|webpack|vite|eslint|prettier"; then
    tipo="chore"
    acao="atualizar configuração de"
  elif echo "$diff_content" | grep -qiE "function |const .* = \(|=> {|def "; then
    if [[ "${status}" == "A" || "${status}" == "??" ]]; then
      tipo="feat"
      acao="adicionar função em"
    else
      tipo="refactor"
      acao="refatorar função em"
    fi
  elif echo "$diff_content" | grep -qiE "class |interface |type "; then
    tipo="refactor"
    acao="atualizar estrutura de"
  elif echo "$diff_content" | grep -qiE "fix|bug|erro|error|correct|corrig"; then
    tipo="fix"
    acao="corrigir problema em"
  fi

  nome_arquivo=$(basename "$file")
  nome_sem_ext="${nome_arquivo%.*}"

  mensagem="$tipo: $acao $nome_sem_ext"

  git add "$file" || true
  git commit -m "$mensagem" || true

  echo "✅ Commit criado → [$mensagem]"
done

echo ""
echo "🎉 Todos os commits foram criados com sucesso!"
