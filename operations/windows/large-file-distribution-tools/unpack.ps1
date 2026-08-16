param (
    [Parameter(Mandatory = $true)]
    [string]$filePath  # Caminho do primeiro arquivo RAR (ex: arquivo.rar.001)
)

# Caminho do WinRAR — altere se necessário
$winrarPath = "C:\Program Files\WinRAR\WinRAR.exe"

# Verifica se o WinRAR existe
if (-not (Test-Path $winrarPath)) {
    Write-Host "❌ WinRAR não encontrado em: $winrarPath"
    Write-Host "Baixe em: https://www.rarlab.com/download.htm"
    exit
}

# Verifica se o arquivo existe
if (-not (Test-Path $filePath)) {
    Write-Host "❌ Arquivo não encontrado!"
    exit
}

# Obtém o diretório onde estão as partes do RAR
$folderPath = Split-Path $filePath -Parent

# Cria a pasta de destino para extração (pode ser a mesma pasta ou uma nova)
$destFolder = Join-Path $folderPath "Extraído"
New-Item -ItemType Directory -Force -Path $destFolder | Out-Null

Write-Host "📦 Descompactando arquivos RAR..."

# Extraí o arquivo RAR (WinRAR irá automaticamente buscar as partes subsequentes, como .001, .002, etc.)
& $winrarPath x $filePath $destFolder

Write-Host "✅ Descompactação concluída!"
Write-Host "📁 Arquivos extraídos estão em: $destFolder"
