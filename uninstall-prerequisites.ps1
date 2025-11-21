# Script de desinstallation des prerequis pour Halimou (Windows)
# Usage: .\uninstall-prerequisites.ps1
# IMPORTANT: Executez en tant qu'administrateur

Param(
    [switch]$All,
    [switch]$Git,
    [switch]$Node,
    [switch]$Python,
    [switch]$Jq,
    [switch]$MongoDB,
    [switch]$Pnpm,
    [switch]$Chocolatey
)

# Verifier les privileges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERREUR] Ce script necessite des privileges administrateur." -ForegroundColor Red
    Write-Host "   Executez PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

Write-Host "[Halimou] Desinstallation des prerequis" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour verifier si une commande existe
function Test-Cmd {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Fonction pour desinstaller avec winget
function Uninstall-WithWinget {
  param([string]$PackageId, [string]$PackageName)
  
  if (Test-Cmd -Name "winget") {
    Write-Host "[*] Desinstallation de $PackageName via winget..." -ForegroundColor Yellow
    try {
      winget uninstall --id $PackageId --silent --accept-source-agreements
      if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $PackageName desinstalle avec succes" -ForegroundColor Green
        return $true
      } else {
        Write-Host "[!] Desinstallation via winget echouee (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "[!] Erreur lors de la desinstallation via winget: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Fonction pour desinstaller avec Chocolatey
function Uninstall-WithChoco {
  param([string]$PackageName, [string]$DisplayName)
  
  if (Test-Cmd -Name "choco") {
    Write-Host "[*] Desinstallation de $DisplayName via Chocolatey..." -ForegroundColor Yellow
    try {
      choco uninstall $PackageName -y
      if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $DisplayName desinstalle avec succes" -ForegroundColor Green
        return $true
      } else {
        Write-Host "[!] Desinstallation via Chocolatey echouee (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "[!] Erreur lors de la desinstallation via Chocolatey: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Si aucune option specifique, demander confirmation
if (-not ($All -or $Git -or $Node -or $Python -or $Jq -or $MongoDB -or $Pnpm -or $Chocolatey)) {
    Write-Host "[!] Aucune option specifiee. Ce script va desinstaller tous les prerequis." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options disponibles:" -ForegroundColor Cyan
    Write-Host "  -All          : Desinstaller tout" -ForegroundColor White
    Write-Host "  -Git          : Desinstaller Git uniquement" -ForegroundColor White
    Write-Host "  -Node         : Desinstaller Node.js uniquement" -ForegroundColor White
    Write-Host "  -Python       : Desinstaller Python uniquement" -ForegroundColor White
    Write-Host "  -Jq           : Desinstaller jq uniquement" -ForegroundColor White
    Write-Host "  -MongoDB      : Desinstaller MongoDB uniquement" -ForegroundColor White
    Write-Host "  -Pnpm         : Desinstaller pnpm uniquement" -ForegroundColor White
    Write-Host "  -Chocolatey   : Desinstaller Chocolatey uniquement" -ForegroundColor White
    Write-Host ""
    $response = Read-Host "Voulez-vous desinstaller tous les prerequis? (o/N)"
    if ($response -eq "o" -or $response -eq "O") {
        $All = $true
    } else {
        Write-Host "[*] Operation annulee." -ForegroundColor Yellow
        exit 0
    }
}

if ($All) {
    $Git = $true
    $Node = $true
    $Python = $true
    $Jq = $true
    $MongoDB = $true
    $Pnpm = $true
}

# Desinstaller Git
if ($Git) {
    Write-Host ""
    Write-Host "[*] Desinstallation de Git..." -ForegroundColor Yellow
    $uninstalled = $false
    
    if (-not (Uninstall-WithWinget -PackageId "Git.Git" -PackageName "Git")) {
        if (-not (Uninstall-WithChoco -PackageName "git" -DisplayName "Git")) {
            Write-Host "[!] Impossible de desinstaller Git automatiquement." -ForegroundColor Yellow
            Write-Host "   Desinstallez manuellement depuis: Parametres > Applications" -ForegroundColor Yellow
        } else {
            $uninstalled = $true
        }
    } else {
        $uninstalled = $true
    }
    
    if ($uninstalled) {
        Write-Host "[OK] Git desinstalle" -ForegroundColor Green
    }
}

# Desinstaller Node.js
if ($Node) {
    Write-Host ""
    Write-Host "[*] Desinstallation de Node.js..." -ForegroundColor Yellow
    $uninstalled = $false
    
    if (-not (Uninstall-WithWinget -PackageId "OpenJS.NodeJS.LTS" -PackageName "Node.js")) {
        if (-not (Uninstall-WithChoco -PackageName "nodejs-lts" -DisplayName "Node.js")) {
            Write-Host "[!] Impossible de desinstaller Node.js automatiquement." -ForegroundColor Yellow
            Write-Host "   Desinstallez manuellement depuis: Parametres > Applications" -ForegroundColor Yellow
        } else {
            $uninstalled = $true
        }
    } else {
        $uninstalled = $true
    }
    
    if ($uninstalled) {
        Write-Host "[OK] Node.js desinstalle" -ForegroundColor Green
    }
}

# Desinstaller Python
if ($Python) {
    Write-Host ""
    Write-Host "[*] Desinstallation de Python..." -ForegroundColor Yellow
    Write-Host "[!] Python doit etre desinstalle manuellement." -ForegroundColor Yellow
    Write-Host "   Instructions:" -ForegroundColor Cyan
    Write-Host "   1. Ouvrez Parametres > Applications" -ForegroundColor White
    Write-Host "   2. Recherchez 'Python'" -ForegroundColor White
    Write-Host "   3. Desinstallez toutes les versions de Python" -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "Voulez-vous ouvrir les Parametres maintenant? (o/N)"
    if ($response -eq "o" -or $response -eq "O") {
        Start-Process "ms-settings:appsfeatures"
    }
}

# Desinstaller jq
if ($Jq) {
    Write-Host ""
    Write-Host "[*] Desinstallation de jq..." -ForegroundColor Yellow
    $uninstalled = $false
    
    if (Test-Cmd -Name "winget") {
        try {
            winget uninstall --id jqlang.jq --silent --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] jq desinstalle avec succes" -ForegroundColor Green
                $uninstalled = $true
            }
        } catch {
            Write-Host "[!] Erreur lors de la desinstallation de jq: $_" -ForegroundColor Yellow
        }
    }
    
    if (-not $uninstalled) {
        Write-Host "[!] Impossible de desinstaller jq automatiquement." -ForegroundColor Yellow
        Write-Host "   Desinstallez manuellement depuis: Parametres > Applications" -ForegroundColor Yellow
    }
}

# Desinstaller MongoDB
if ($MongoDB) {
    Write-Host ""
    Write-Host "[*] Desinstallation de MongoDB..." -ForegroundColor Yellow
    
    # Arreter le service MongoDB s'il est en cours d'execution
    $mongoService = Get-Service -Name "MongoDB*" -ErrorAction SilentlyContinue
    if ($mongoService) {
        Write-Host "[*] Arret du service MongoDB..." -ForegroundColor Yellow
        foreach ($service in $mongoService) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name $service.Name -Force
                Write-Host "[OK] Service $($service.Name) arrete" -ForegroundColor Green
            }
        }
    }
    
    $uninstalled = $false
    if (-not (Uninstall-WithWinget -PackageId "MongoDB.Server" -PackageName "MongoDB")) {
        if (-not (Uninstall-WithChoco -PackageName "mongodb" -DisplayName "MongoDB")) {
            Write-Host "[!] Impossible de desinstaller MongoDB automatiquement." -ForegroundColor Yellow
            Write-Host "   Desinstallez manuellement depuis: Parametres > Applications" -ForegroundColor Yellow
            Write-Host "   Ou utilisez le desinstalleur: C:\Program Files\MongoDB\Server\*\bin\uninstall.exe" -ForegroundColor Yellow
        } else {
            $uninstalled = $true
        }
    } else {
        $uninstalled = $true
    }
    
    if ($uninstalled) {
        Write-Host "[OK] MongoDB desinstalle" -ForegroundColor Green
    }
}

# Desinstaller pnpm
if ($Pnpm) {
    Write-Host ""
    Write-Host "[*] Desinstallation de pnpm..." -ForegroundColor Yellow
    
    if (Test-Cmd -Name "pnpm") {
        try {
            npm uninstall -g pnpm
            Write-Host "[OK] pnpm desinstalle" -ForegroundColor Green
        } catch {
            Write-Host "[!] Erreur lors de la desinstallation de pnpm: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[*] pnpm n'est pas installe" -ForegroundColor Gray
    }
}

# Desinstaller Chocolatey
if ($Chocolatey) {
    Write-Host ""
    Write-Host "[*] Desinstallation de Chocolatey..." -ForegroundColor Yellow
    
    if (Test-Cmd -Name "choco") {
        Write-Host "[!] Pour desinstaller Chocolatey completement:" -ForegroundColor Yellow
        Write-Host "   1. Supprimez le dossier: C:\ProgramData\chocolatey" -ForegroundColor White
        Write-Host "   2. Supprimez les variables d'environnement Chocolatey" -ForegroundColor White
        Write-Host "   3. Redemarrez votre ordinateur" -ForegroundColor White
        Write-Host ""
        Write-Host "   Documentation: https://chocolatey.org/docs/uninstallation" -ForegroundColor Cyan
    } else {
        Write-Host "[*] Chocolatey n'est pas installe" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "[OK] Desinstallation terminee!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Note: Certains elements peuvent necessiter un redemarrage pour etre completement supprimes." -ForegroundColor Yellow
Write-Host "[*] Pour verifier, fermez et rouvrez PowerShell, puis verifiez les commandes:" -ForegroundColor Yellow
Write-Host "   git --version" -ForegroundColor White
Write-Host "   node --version" -ForegroundColor White
Write-Host "   python --version" -ForegroundColor White
Write-Host "   jq --version" -ForegroundColor White
Write-Host ""

