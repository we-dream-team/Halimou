# Script d'installation automatique des prérequis pour Halimou (Windows)
# Usage: 
#   En ligne: PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
#   Local: .\install-prerequisites.ps1
#   IMPORTANT: Exécutez en tant qu'administrateur pour installer les logiciels

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  Ce script nécessite des privilèges administrateur." -ForegroundColor Yellow
    Write-Host "   Veuillez exécuter PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "   Clic droit sur PowerShell > Exécuter en tant qu'administrateur" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Voulez-vous continuer quand même? (o/N)"
    if ($response -ne "o" -and $response -ne "O") {
        exit 1
    }
}

$ErrorActionPreference = "Continue"

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
    try {
      $result = winget install --id $PackageId --accept-package-agreements --accept-source-agreements --silent 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $PackageName installé avec succès via winget" -ForegroundColor Green
        return $true
      } else {
        Write-Host "⚠️  Installation via winget échouée (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "⚠️  Erreur lors de l'installation via winget: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Fonction pour installer avec Chocolatey
function Install-WithChoco {
  param([string]$PackageName, [string]$DisplayName)
  
  if (Test-Cmd -Name "choco") {
    Write-Host "📦 Installation de $DisplayName via Chocolatey..." -ForegroundColor Yellow
    try {
      choco install $PackageName -y --no-progress
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $DisplayName installé avec succès via Chocolatey" -ForegroundColor Green
        return $true
      } else {
        Write-Host "⚠️  Installation via Chocolatey échouée (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "⚠️  Erreur lors de l'installation via Chocolatey: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Fonction pour rafraîchir le PATH
function Refresh-Path {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  # Attendre un peu pour que les changements soient pris en compte
  Start-Sleep -Seconds 2
}

# Installer Chocolatey si nécessaire
if (-not (Test-Cmd -Name "choco")) {
  Write-Host "📦 Installation de Chocolatey..." -ForegroundColor Yellow
  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoInstallScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
    Invoke-Expression $chocoInstallScript
    
    # Rafraîchir l'environnement
    Refresh-Path
    
    # Vérifier que Chocolatey est installé
    if (Test-Cmd -Name "choco") {
      Write-Host "✅ Chocolatey installé avec succès" -ForegroundColor Green
    } else {
      Write-Host "⚠️  Chocolatey pourrait ne pas être dans le PATH. Redémarrez PowerShell et réessayez." -ForegroundColor Yellow
    }
  } catch {
    Write-Host "⚠️  Erreur lors de l'installation de Chocolatey: $_" -ForegroundColor Yellow
    Write-Host "   Vous pouvez l'installer manuellement: https://chocolatey.org/install" -ForegroundColor Yellow
  }
}

# Installer Git
if (-not (Test-Cmd -Name "git")) {
  Write-Host "📦 Installation de Git..." -ForegroundColor Yellow
  $gitInstalled = $false
  if (-not (Install-WithWinget -PackageId "Git.Git" -PackageName "Git")) {
    if (-not (Install-WithChoco -PackageName "git" -DisplayName "Git")) {
      Write-Host "❌ Impossible d'installer Git automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://git-scm.com/download/win" -ForegroundColor Yellow
      Write-Host "   Après installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
      $gitInstalled = $false
    } else {
      $gitInstalled = $true
    }
  } else {
    $gitInstalled = $true
  }
  
  if ($gitInstalled) {
    Refresh-Path
    # Vérifier que Git est maintenant disponible
    if (Test-Cmd -Name "git") {
      Write-Host "✅ Git installé et disponible" -ForegroundColor Green
    } else {
      Write-Host "⚠️  Git installé mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "✅ Git déjà installé: $(git --version 2>&1)" -ForegroundColor Green
}

# Installer Node.js
if (-not (Test-Cmd -Name "node")) {
  Write-Host "📦 Installation de Node.js..." -ForegroundColor Yellow
  $nodeInstalled = $false
  if (-not (Install-WithWinget -PackageId "OpenJS.NodeJS.LTS" -PackageName "Node.js")) {
    if (-not (Install-WithChoco -PackageName "nodejs-lts" -DisplayName "Node.js")) {
      Write-Host "❌ Impossible d'installer Node.js automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://nodejs.org/" -ForegroundColor Yellow
      Write-Host "   Après installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
      $nodeInstalled = $false
    } else {
      $nodeInstalled = $true
    }
  } else {
    $nodeInstalled = $true
  }
  
  if ($nodeInstalled) {
    Refresh-Path
    # Vérifier que Node.js est maintenant disponible
    if (Test-Cmd -Name "node") {
      Write-Host "✅ Node.js installé et disponible" -ForegroundColor Green
    } else {
      Write-Host "⚠️  Node.js installé mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "✅ Node.js déjà installé: $(node --version 2>&1)" -ForegroundColor Green
}

# Installer Python
if (-not (Test-Cmd -Name "python") -and -not (Test-Cmd -Name "py")) {
  Write-Host "📦 Installation de Python..." -ForegroundColor Yellow
  $pythonInstalled = $false
  if (-not (Install-WithWinget -PackageId "Python.Python.3.11" -PackageName "Python")) {
    if (-not (Install-WithChoco -PackageName "python311" -DisplayName "Python")) {
      Write-Host "❌ Impossible d'installer Python automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://www.python.org/downloads/" -ForegroundColor Yellow
      Write-Host "   IMPORTANT: Cochez 'Add Python to PATH' lors de l'installation!" -ForegroundColor Yellow
      Write-Host "   Après installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
      $pythonInstalled = $false
    } else {
      $pythonInstalled = $true
    }
  } else {
    $pythonInstalled = $true
  }
  
  if ($pythonInstalled) {
    Refresh-Path
    # Vérifier que Python est maintenant disponible
    if ((Test-Cmd -Name "python") -or (Test-Cmd -Name "py")) {
      $pythonVersion = if (Test-Cmd -Name "python") { python --version 2>&1 } else { py --version 2>&1 }
      Write-Host "✅ Python installé: $pythonVersion" -ForegroundColor Green
    } else {
      Write-Host "⚠️  Python installé mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  $pythonVersion = if (Test-Cmd -Name "python") { python --version 2>&1 } else { py --version 2>&1 }
  Write-Host "✅ Python déjà installé: $pythonVersion" -ForegroundColor Green
}

# Installer MongoDB
if (-not (Test-Cmd -Name "mongod")) {
  Write-Host "📦 Installation de MongoDB..." -ForegroundColor Yellow
  $mongoInstalled = $false
  if (-not (Install-WithWinget -PackageId "MongoDB.Server" -PackageName "MongoDB")) {
    if (-not (Install-WithChoco -PackageName "mongodb" -DisplayName "MongoDB")) {
      Write-Host "⚠️  Impossible d'installer MongoDB automatiquement." -ForegroundColor Yellow
      Write-Host "   Veuillez l'installer manuellement: https://www.mongodb.com/try/download/community" -ForegroundColor Yellow
      Write-Host "   Ou utilisez MongoDB Atlas (cloud gratuit): https://www.mongodb.com/cloud/atlas" -ForegroundColor Yellow
      $mongoInstalled = $false
    } else {
      $mongoInstalled = $true
    }
  } else {
    $mongoInstalled = $true
  }
  
  if ($mongoInstalled) {
    Refresh-Path
    Write-Host "⚠️  MongoDB installé. Pour démarrer MongoDB:" -ForegroundColor Yellow
    Write-Host "   net start MongoDB" -ForegroundColor Cyan
    Write-Host "   Ou via Services: services.msc > MongoDB" -ForegroundColor Cyan
  }
} else {
  Write-Host "✅ MongoDB déjà installé" -ForegroundColor Green
}

# Installer pnpm
if (-not (Test-Cmd -Name "pnpm")) {
  if (Test-Cmd -Name "node") {
    Write-Host "📦 Installation de pnpm..." -ForegroundColor Yellow
    try {
      npm install -g pnpm
      Refresh-Path
      if (Test-Cmd -Name "pnpm") {
        Write-Host "✅ pnpm installé: $(pnpm --version 2>&1)" -ForegroundColor Green
      } else {
        Write-Host "⚠️  pnpm installé mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
      }
    } catch {
      Write-Host "⚠️  Erreur lors de l'installation de pnpm: $_" -ForegroundColor Yellow
      Write-Host "   Vous pouvez l'installer manuellement: npm install -g pnpm" -ForegroundColor Yellow
    }
  } else {
    Write-Host "⚠️  Node.js n'est pas disponible. pnpm ne peut pas être installé." -ForegroundColor Yellow
  }
} else {
  Write-Host "✅ pnpm déjà installé: $(pnpm --version 2>&1)" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Installation terminée!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Vérification des versions installées:" -ForegroundColor Cyan
Write-Host ""

$allInstalled = $true

# Vérifier Git
if (Test-Cmd -Name "git") {
  try { 
    $gitVer = git --version 2>&1
    Write-Host "  ✅ Git: $gitVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  ⚠️  Git: Installé mais erreur lors de la vérification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  ❌ Git: Non installé" -ForegroundColor Red
  $allInstalled = $false
}

# Vérifier Node.js
if (Test-Cmd -Name "node") {
  try { 
    $nodeVer = node --version 2>&1
    Write-Host "  ✅ Node.js: $nodeVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  ⚠️  Node.js: Installé mais erreur lors de la vérification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  ❌ Node.js: Non installé" -ForegroundColor Red
  $allInstalled = $false
}

# Vérifier Python
if ((Test-Cmd -Name "python") -or (Test-Cmd -Name "py")) {
  try { 
    $pyVer = if (Test-Cmd -Name "python") { python --version 2>&1 } else { py --version 2>&1 }
    Write-Host "  ✅ Python: $pyVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  ⚠️  Python: Installé mais erreur lors de la vérification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  ❌ Python: Non installé" -ForegroundColor Red
  $allInstalled = $false
}

# Vérifier pnpm
if (Test-Cmd -Name "pnpm") {
  try { 
    $pnpmVer = pnpm --version 2>&1
    Write-Host "  ✅ pnpm: $pnpmVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  ⚠️  pnpm: Installé mais erreur lors de la vérification" -ForegroundColor Yellow
  }
} else {
  Write-Host "  ⚠️  pnpm: Non installé (optionnel, npm peut être utilisé)" -ForegroundColor Yellow
}

# Vérifier MongoDB
if (Test-Cmd -Name "mongod") {
  try { 
    $mongoVer = mongod --version 2>&1 | Select-Object -First 1
    Write-Host "  ✅ MongoDB: $mongoVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  ⚠️  MongoDB: Installé mais erreur lors de la vérification" -ForegroundColor Yellow
  }
} else {
  Write-Host "  ⚠️  MongoDB: Non installé (optionnel, peut utiliser MongoDB Atlas)" -ForegroundColor Yellow
}

Write-Host ""
if (-not $allInstalled) {
  Write-Host "⚠️  ATTENTION: Certains prérequis ne sont pas installés." -ForegroundColor Yellow
  Write-Host "   Fermez et rouvrez PowerShell en tant qu'administrateur, puis réessayez." -ForegroundColor Yellow
  Write-Host ""
}

Write-Host "🚀 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "  1. Fermez et rouvrez PowerShell (important pour que le PATH soit mis à jour)" -ForegroundColor White
Write-Host "  2. Cloner le projet: git clone https://github.com/we-dream-team/Halimou.git" -ForegroundColor White
Write-Host "  3. Aller dans le dossier: cd Halimou" -ForegroundColor White
Write-Host "  4. Lancer l'installation: .\install-and-start.ps1" -ForegroundColor White
Write-Host ""
Write-Host "💡 Astuce: Si des commandes ne sont pas reconnues après réouverture," -ForegroundColor Yellow
Write-Host "   redémarrez votre ordinateur pour que tous les changements de PATH soient appliqués." -ForegroundColor Yellow
Write-Host ""

