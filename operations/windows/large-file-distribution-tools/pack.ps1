# Caminho do WinRAR — altere se necessário
$winrarPath = "C:\Program Files\WinRAR\WinRAR.exe"

# Verifica se o WinRAR existe
if (-not (Test-Path $winrarPath)) {
    Write-Host "❌ WinRAR não encontrado em: $winrarPath"
    Write-Host "Baixe em: https://www.rarlab.com/download.htm"
    exit
}

# Caminho da pasta onde o script está sendo executado (pasta raiz)
$folderPath = Get-Location

# Filtra os arquivos de vídeo no diretório (extensões .mp4, .mkv, .avi, .wmv)
$videoFiles = Get-ChildItem -Path $folderPath -Recurse | Where-Object { 
    $_.Extension -match '\.mp4$|\.mkv$|\.avi$|\.wmv$' -and $_.PSIsContainer -eq $false
}

# Verifica se há arquivos de vídeo no diretório
if ($videoFiles.Count -eq 0) {
    Write-Host "❌ Nenhum arquivo de vídeo encontrado na pasta atual!"
    exit
}

# Loop para compactar e dividir cada arquivo de vídeo
foreach ($file in $videoFiles) {
    # Cria a pasta de destino com o nome do arquivo (sem extensão)
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $destFolder = Join-Path $folderPath $fileName

    # Cria a pasta de destino, se não existir
    if (-not (Test-Path $destFolder)) {
        New-Item -ItemType Directory -Force -Path $destFolder | Out-Null
    }

    # Caminho para o arquivo RAR
    $rarPath = Join-Path $destFolder "$fileName.rar"

    Write-Host "📦 Criando arquivo RAR para '$($file.Name)'..."

    # Cria o arquivo RAR e o divide em partes de 99MB
    # O parâmetro -ep1 evita a inclusão da estrutura de diretórios
    & $winrarPath a -v99m -ep1 $rarPath $file.FullName

    Write-Host "✅ Processo concluído para '$($file.Name)'!"
    Write-Host "📁 Arquivos divididos estão em: $destFolder"
}

Write-Host "🔚 Todos os arquivos foram processados!"
