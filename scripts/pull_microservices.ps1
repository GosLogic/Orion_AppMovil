# Actualiza los 6 microservicios Orion con git pull.
# Uso:
#   .\scripts\pull_microservices.ps1
#   .\scripts\pull_microservices.ps1 -Branch develop
#   .\scripts\pull_microservices.ps1 -Stash

param(
    [string] $ServicesRoot = "",
    [string] $Branch = "",
    [switch] $Rebase,
    [switch] $Stash
)

$Microservices = @(
    "orion-iam-service",
    "orion-dispatch-service",
    "orion-fleet-service",
    "orion-maintenance-service",
    "orion-telemetry-service",
    "orion-notification-service"
)

if ([string]::IsNullOrWhiteSpace($ServicesRoot)) {
    $ServicesRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

if (-not (Test-Path $ServicesRoot)) {
    Write-Error "No existe la carpeta de servicios: $ServicesRoot"
}

Write-Host "=== Orion - git pull de microservicios ===" -ForegroundColor Cyan
Write-Host "Raiz: $ServicesRoot"
if ($Branch) { Write-Host "Rama objetivo: $Branch" }
Write-Host ""

$ok = 0
$failed = @()

foreach ($name in $Microservices) {
    $repoPath = Join-Path $ServicesRoot $name
    Write-Host "[$name]" -ForegroundColor Yellow

    if (-not (Test-Path $repoPath)) {
        Write-Host "  SKIP - carpeta no encontrada: $repoPath" -ForegroundColor DarkYellow
        $failed += "$name (no existe)"
        continue
    }

    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Host "  SKIP - no es un repositorio git" -ForegroundColor DarkYellow
        $failed += "$name (sin .git)"
        continue
    }

    Push-Location $repoPath
    try {
        $currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
        Write-Host "  Rama actual: $currentBranch"

        if ($Branch -and $Branch -ne $currentBranch) {
            git checkout $Branch
            if ($LASTEXITCODE -ne 0) { throw "checkout fallo" }
        }

        if ($Stash) {
            $dirty = git status --porcelain
            if ($dirty) {
                git stash push -m "pull_microservices.ps1 auto-stash"
                if ($LASTEXITCODE -ne 0) { throw "git stash fallo" }
            }
        }

        if ($Rebase) {
            git pull --rebase
        } else {
            git pull
        }
        if ($LASTEXITCODE -ne 0) { throw "git pull fallo" }

        if ($Stash) {
            git stash pop 2>$null
        }

        $short = (git rev-parse --short HEAD 2>$null).Trim()
        Write-Host "  OK - commit $short" -ForegroundColor Green
        $ok++
    }
    catch {
        Write-Host "  ERROR - $($_.Exception.Message)" -ForegroundColor Red
        $failed += $name
    }
    finally {
        Pop-Location
    }

    Write-Host ""
}

Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host "Exitosos: $ok / $($Microservices.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Fallidos: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "Todos los microservicios actualizados." -ForegroundColor Green
exit 0
