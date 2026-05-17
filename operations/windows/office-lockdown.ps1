<#

#🔒 Office Lockdown — Word, Excel e PowerPoint

## • Bloqueia internet do Word, Excel e PowerPoint
## • Desativa atualizações automáticas do Office
## • Impede login Microsoft no Office

## Script PowerShell para:
### - 🚫 Bloquear acesso à internet
### - ⛔ Desativar atualizações automáticas
### - 🔐 Impedir login com conta Microsoft

##  Aplicado para:
### - Microsoft Word
### - Microsoft Excel
### - Microsoft PowerPoint

## ✅ Resultado esperado
### - 🌐 Word sem acesso à internet
### - 📊 Excel sem acesso à internet
### - 📽️ PowerPoint sem acesso à internet
### - ⛔ Atualizações automáticas desativadas
### - 🔐 Login Microsoft bloqueado
### - ☁️ Recursos online do Office desabilitados


#>

# ==========================================================
# CONFIGURAÇÕES
# ==========================================================

$officeExecutables = @(
    "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE",
    "$env:ProgramFiles\Microsoft Office\root\Office16\EXCEL.EXE",
    "$env:ProgramFiles\Microsoft Office\root\Office16\POWERPNT.EXE",
    "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
    "$env:ProgramFiles\Microsoft Office\root\Office16\MSACCESS.EXE",

    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\WINWORD.EXE",
    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\EXCEL.EXE",
    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\POWERPNT.EXE",
    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\OUTLOOK.EXE",
    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\MSACCESS.EXE"
)

$officeUpdateRegistryPath =
    "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate"

$officeSignInRegistryPath =
    "HKCU:\Software\Microsoft\Office\16.0\Common\SignIn"


# ==========================================================
# FUNÇÕES
# ==========================================================

function Stop-ClickToRunSvc {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$UninstallOffice = $false,
        [switch]$RemoveService
    )

    $serviceName = "ClickToRunSvc"

    # ==========================================================
    # SRP: DEFINIÇÃO DE RESPONSABILIDADES SEPARADAS
    # ==========================================================

    $criticalProcesses = @(
        "OfficeClickToRun",
        "OfficeC2RClient"
    )

    $officeProcesses = @(
        "WINWORD",
        "EXCEL",
        "POWERPNT",
        "OUTLOOK",
        "MSACCESS",
        "ONENOTE",
        "setup"
    )

    # ==========================================================
    # FUNÇÃO LOCAL (REUTILIZAÇÃO / CLEAN CODE)
    # ==========================================================

    function Stop-Processes {
        param([string[]]$Processes)

        foreach ($proc in $Processes) {
            Get-Process -Name $proc -ErrorAction SilentlyContinue |
                Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }

    # ==========================================================
    # EXECUÇÃO - PROCESSOS
    # ==========================================================

    Write-Host "`nℹ️ [INFO] Encerrando processos críticos do Click-to-Run..." -ForegroundColor Cyan
    Stop-Processes -Processes $criticalProcesses

    Write-Host "ℹ️ [INFO] Encerrando aplicativos do Office..." -ForegroundColor Cyan
    Stop-Processes -Processes $officeProcesses

    # ==========================================================
    # EXECUÇÃO - SERVIÇO
    # ==========================================================

    Write-Host "ℹ️ [INFO] Parando serviço $serviceName..." -ForegroundColor Cyan

    $service = Get-Service $serviceName -ErrorAction SilentlyContinue

    if ($service) {

        try {
            Stop-Service $serviceName -Force -ErrorAction Stop
            Set-Service $serviceName -StartupType Disabled

            Write-Host "✅[OK] Serviço parado e desabilitado." -ForegroundColor Green
        }
        catch {
            Write-Warning "Falha ao parar/desabilitar o serviço: $_"
        }

        if ($RemoveService) {
            Write-Host "ℹ️ [INFO] Removendo serviço..." -ForegroundColor Yellow
            sc.exe delete $serviceName | Out-Null
        }
    }
    else {
        Write-Warning "⛔[ERRO] Serviço $serviceName não encontrado."
    }

    # ==========================================================
    # DESINSTALAÇÃO OPCIONAL (DESATIVADA POR PADRÃO)
    # ==========================================================

    if ($UninstallOffice) {

        Write-Host "ℹ️ [INFO] Procurando instalações do Office..." -ForegroundColor Cyan

        $officeProducts = Get-CimInstance Win32_Product |
            Where-Object {
                $_.Name -match "Office|Microsoft 365|Click-to-Run"
            }

        foreach ($product in $officeProducts) {

            Write-Host "ℹ️ [INFO] Desinstalando: $($product.Name)" -ForegroundColor Yellow

            try {
                Invoke-CimMethod -InputObject $product -MethodName Uninstall | Out-Null
                Write-Host "✅[OK] $($product.Name) removido." -ForegroundColor Green
            }
            catch {
                Write-Warning "⛔[ERRO]Erro ao desinstalar $($product.Name)"
            }
        }
    }

    Write-Host "`n✅[FINALIZADO]" -ForegroundColor Green
}

function Add-FirewallBlockRule {
    param (
        [string]$ApplicationPath
    )

    if (-not (Test-Path $ApplicationPath)) {
        return
    }

    $applicationName =
        [System.IO.Path]::GetFileName($ApplicationPath)

    $firewallRules = @(
        @{
            Name      = "BLOCK-IN-$applicationName"
            Direction = "Inbound"
        },
        @{
            Name      = "BLOCK-OUT-$applicationName"
            Direction = "Outbound"
        }
    )

    foreach ($rule in $firewallRules) {

        New-NetFirewallRule `
            -DisplayName $rule.Name `
            -Direction $rule.Direction `
            -Program $ApplicationPath `
            -Action Block `
            -Profile Any `
            -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "✅ Firewall bloqueado para $applicationName"
}

function Disable-OfficeUpdates {

    New-Item `
        -Path $officeUpdateRegistryPath `
        -Force | Out-Null

    Set-ItemProperty `
        -Path $officeUpdateRegistryPath `
        -Name "enableautomaticupdates" `
        -Value 0 `
        -Type DWord

    Set-ItemProperty `
        -Path $officeUpdateRegistryPath `
        -Name "hideenabledisableupdates" `
        -Value 1 `
        -Type DWord

    Write-Host "✅ Atualizações automáticas desativadas"
}

function Disable-OfficeSignIn {

    New-Item `
        -Path $officeSignInRegistryPath `
        -Force | Out-Null

    Set-ItemProperty `
        -Path $officeSignInRegistryPath `
        -Name "SignInOptions" `
        -Value 3 `
        -Type DWord

    Write-Host "✅ Login Microsoft bloqueado"
}

# ==========================================================
# EXECUÇÃO
# ==========================================================

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host ""
Write-Host "========================================"
Write-Host " OFFICE LOCKDOWN"
Write-Host "========================================"
Write-Host ""

Write-Info "ℹ️ [INFO] Encerrando processos críticos..."
Stop-ClickToRunSvc

Write-Info "ℹ️ [INFO] Configurando regras de bloqueio..."
$officeExecutables = Get-OfficeExecutables
foreach ($executable in $officeExecutables) {
    Add-FirewallBlockRule -ApplicationPath $executable
}

Write-Info "ℹ️ [INFO] Desativando atualizações automáticas..."
Disable-OfficeUpdates

Write-Info "ℹ️ [INFO] Desativando login Microsoft..."
Disable-OfficeSignIn

Write-Host ""
Write-Host "========================================"
Write-Host "✅ Configuração concluída com sucesso"
Write-Host "========================================"