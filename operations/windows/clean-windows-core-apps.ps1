# ==========================================================
# WINDOWS CORE APPS CLEANER
# ==========================================================

# ==========================================================
# APPS
# ==========================================================

$appsToRemove = @(
    "Microsoft.ScreenSketch",
    "Microsoft.BingWeather",
    "Microsoft.RemoteDesktop",
    "Microsoft.549981C3F5F10",
    "microsoft.windowscommunicationsapps",
    "Microsoft.ZuneVideo",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.ZuneMusic",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Office.OneNote",
    "Microsoft.MSPaint",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.XboxApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.RemoteDesktop",
    "Microsoft.RemoteDesktop_8wekyb3d8bbwe"

)

# ==========================================================
# LOG
# ==========================================================

function Write-Info { param($m) Write-Host $m -ForegroundColor Cyan }
function Write-Success { param($m) Write-Host $m -ForegroundColor Green }
function Write-Warn { param($m) Write-Host $m -ForegroundColor Yellow }

# ==========================================================
# REMOVE APPX (USER CURRENT ONLY - CORRETO)
# ==========================================================

function Remove-App {

    param([string]$Name)

    try {

        Write-Info ""
        Write-Info "🔎 Removendo: $Name"

        $pkgs = Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue

        foreach ($p in $pkgs) {
            try {
                Remove-AppxPackage -Package $p.PackageFullName -ErrorAction SilentlyContinue
                Write-Success "✔ Removido: $($p.Name)"
            }
            catch {
                Write-Warn "⚠ Falha: $($p.Name)"
            }
        }

    }
    catch {
        Write-Warn "⚠ Erro geral: $Name"
    }
    finally {
        Write-Info "✔ Finalizado: $Name"
    }
}

# ==========================================================
# XBOX SERVICES (REAL FIX)
# ==========================================================

function Remove-XboxServices {

    Write-Info ""
    Write-Info "🎮 Desativando serviços Xbox..."

    $services = @(
        "XboxGipSvc",
        "XblAuthManager",
        "XblGameSave",
        "XboxNetApiSvc"
    )

    foreach ($s in $services) {

        try {

            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue

            if ($svc) {

                Stop-Service $s -Force -ErrorAction SilentlyContinue

                # fallback real (funciona mesmo quando Set-Service falha)
                sc.exe config $s start= disabled | Out-Null

                Write-Success "✔ Serviço desativado: $s"
            }
            else {
                Write-Warn "⚠ Não encontrado: $s"
            }

        }
        catch {
            Write-Warn "⚠ Falha: $s"
        }
    }
}

# ==========================================================
# OFFICE CLICK TO RUN
# ==========================================================

function Remove-OfficeClickToRun {

    Write-Info ""
    Write-Info "📦 Desativando Office Click-to-Run..."

    try {

        $s = Get-Service ClickToRunSvc -ErrorAction SilentlyContinue

        if ($s) {

            Stop-Service ClickToRunSvc -Force -ErrorAction SilentlyContinue
            sc.exe config ClickToRunSvc start= disabled | Out-Null

            Write-Success "✔ Office desativado"
        }
        else {
            Write-Warn "⚠ Serviço Office não encontrado"
        }

    }
    catch {
        Write-Warn "⚠ Falha Office Click-to-Run"
    }
}

# ==========================================================
# EXECUTION
# ==========================================================

Clear-Host

Write-Host ""
Write-Host "========================================="
Write-Host " WINDOWS CORE APPS CLEANER (FIXED)"
Write-Host "========================================="
Write-Host ""

foreach ($app in $appsToRemove) {
    Remove-App -Name $app
}

Remove-XboxServices
Remove-OfficeClickToRun

Write-Host ""
Write-Host "========================================="
Write-Host "✔ LIMPEZA FINALIZADA"
Write-Host "========================================="
Write-Host ""