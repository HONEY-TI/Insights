# =========================
# 🔻 1. Remover OneDrive
# =========================

taskkill /f /im OneDrive.exe 2>$null

if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" "/uninstall" -Wait
}

if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
    Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait
}

# Limpar pastas residuais
Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue


# =========================
# 🔻 2. Remover Microsoft Office (Click-to-Run)
# =========================

$officeApps = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Office%'"

foreach ($app in $officeApps) {
    $app.Uninstall()
}