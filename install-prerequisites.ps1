# Script d'installation automatique des prérequis pour Halimou (Windows)
# Usage: 
#   En ligne: PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/VOTRE_REPO/Halimou/main/install-prerequisites.ps1'))"
#   Local: .\install-prerequisites.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 Installation des prérequis pour Halimou" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour vérifier si une commande existe
function Test-Cmd {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Fonction pour installer avec winget
function Install-WithWinget {
  param([string]$PackageId, [string]$PackageName)
  
  if (Test-Cmd -Name "winget") {
    Write-Host "📦 Installation de $PackageName via winget..." -ForegroundColor Yellow
    winget install --id $PackageId --accept-package-agreements --accept-source-agreements --silent
    return $true
  }
  return $false
}

# Fonction pour installer avec Chocolatey
function Install-WithChoco {
  param([string]$PackageName, [string]$DisplayName)
  
  if (Test-Cmd -Name "choco") {
    Write-Host "📦 Installation de $DisplayName via Chocolatey..." -ForegroundColor Yellow
    choco install $PackageName -y
    return $true
  }
  return $false
}

# Installer Chocolatey si nécessaire
if (-not (Test-Cmd -Name "choco")) {
  Write-Host "📦 Installation de Chocolatey..." -ForegroundColor Yellow
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  
  # Rafraîchir l'environnement
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Installer Git
if (-not (Test-Cmd -Name "git")) {
  Write-Host "📦 Installation de Git..." -ForegroundColor Yellow
  if (-not (Install-WithWinget -PackageId "Git.Git" -PackageName "Git")) {
    if (-not (Install-WithChoco -PackageName "git" -DisplayName "Git")) {
      Write-Host "❌ Impossible d'installer Git automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://git-scm.com/download/win" -ForegroundColor Yellow
      exit 1
    }
  }
  # Rafraîchir le PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
  Write-Host "✅ Git déjà installé: $(git --version)" -ForegroundColor Green
}

# Installer Node.js
if (-not (Test-Cmd -Name "node")) {
  Write-Host "📦 Installation de Node.js..." -ForegroundColor Yellow
  if (-not (Install-WithWinget -PackageId "OpenJS.NodeJS.LTS" -PackageName "Node.js")) {
    if (-not (Install-WithChoco -PackageName "nodejs-lts" -DisplayName "Node.js")) {
      Write-Host "❌ Impossible d'installer Node.js automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://nodejs.org/" -ForegroundColor Yellow
      exit 1
    }
  }
  # Rafraîchir le PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
  Write-Host "✅ Node.js déjà installé: $(node --version)" -ForegroundColor Green
}

# Installer Python
if (-not (Test-Cmd -Name "python") -and -not (Test-Cmd -Name "py")) {
  Write-Host "📦 Installation de Python..." -ForegroundColor Yellow
  if (-not (Install-WithWinget -PackageId "Python.Python.3.11" -PackageName "Python")) {
    if (-not (Install-WithChoco -PackageName "python311" -DisplayName "Python")) {
      Write-Host "❌ Impossible d'installer Python automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://www.python.org/downloads/" -ForegroundColor Yellow
      exit 1
    }
  }
  # Rafraîchir le PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
  $pythonVersion = if (Test-Cmd -Name "python") { python --version } else { py --version }
  Write-Host "✅ Python déjà installé: $pythonVersion" -ForegroundColor Green
}

# Installer MongoDB
if (-not (Test-Cmd -Name "mongod")) {
  Write-Host "📦 Installation de MongoDB..." -ForegroundColor Yellow
  if (-not (Install-WithWinget -PackageId "MongoDB.Server" -PackageName "MongoDB")) {
    if (-not (Install-WithChoco -PackageName "mongodb" -DisplayName "MongoDB")) {
      Write-Host "⚠️  Impossible d'installer MongoDB automatiquement." -ForegroundColor Yellow
      Write-Host "   Veuillez l'installer manuellement: https://www.mongodb.com/try/download/community" -ForegroundColor Yellow
      Write-Host "   Ou utilisez MongoDB Atlas (cloud): https://www.mongodb.com/cloud/atlas" -ForegroundColor Yellow
    }
  }
  Write-Host "⚠️  MongoDB installé. Pour démarrer MongoDB:" -ForegroundColor Yellow
  Write-Host "   net start MongoDB" -ForegroundColor Cyan
} else {
  Write-Host "✅ MongoDB déjà installé" -ForegroundColor Green
}

# Installer pnpm
if (-not (Test-Cmd -Name "pnpm")) {
  Write-Host "📦 Installation de pnpm..." -ForegroundColor Yellow
  npm install -g pnpm
} else {
  Write-Host "✅ pnpm déjà installé: $(pnpm --version)" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Installation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Vérification des versions installées:" -ForegroundColor Cyan
try { Write-Host "  Git: $(git --version)" -ForegroundColor Green } catch { Write-Host "  Git: ❌ Non installé" -ForegroundColor Red }
try { Write-Host "  Node.js: $(node --version)" -ForegroundColor Green } catch { Write-Host "  Node.js: ❌ Non installé" -ForegroundColor Red }
try { 
  $pyVer = if (Test-Cmd -Name "python") { python --version } else { py --version }
  Write-Host "  Python: $pyVer" -ForegroundColor Green 
} catch { Write-Host "  Python: ❌ Non installé" -ForegroundColor Red }
try { Write-Host "  pnpm: $(pnpm --version)" -ForegroundColor Green } catch { Write-Host "  pnpm: ❌ Non installé" -ForegroundColor Red }
try { Write-Host "  MongoDB: $(mongod --version | Select-Object -First 1)" -ForegroundColor Green } catch { Write-Host "  MongoDB: ❌ Non installé" -ForegroundColor Yellow }
Write-Host ""
Write-Host "🚀 Vous pouvez maintenant:" -ForegroundColor Cyan
Write-Host "  1. Cloner le projet: git clone <URL_DU_REPO>" -ForegroundColor White
Write-Host "  2. Lancer l'installation: .\install-and-start.ps1" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: Si certaines commandes ne sont pas reconnues, fermez et rouvrez votre terminal." -ForegroundColor Yellow
Write-Host ""

