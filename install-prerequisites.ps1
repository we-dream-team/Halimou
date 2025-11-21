# Script d'installation automatique des prerequis pour Halimou (Windows)
# Usage: 
#   En ligne: PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
#   Local: .\install-prerequisites.ps1
#   IMPORTANT: Executez en tant qu'administrateur pour installer les logiciels

# Verifier si le script est execute en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] Ce script necessite des privileges administrateur." -ForegroundColor Yellow
    Write-Host "   Veuillez executer PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "   Clic droit sur PowerShell > Executer en tant qu'administrateur" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Voulez-vous continuer quand meme? (o/N)"
    if ($response -ne "o" -and $response -ne "O") {
        exit 1
    }
}

$ErrorActionPreference = "Continue"

Write-Host "[Halimou] Installation des prerequis pour Halimou" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour verifier si une commande existe
function Test-Cmd {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Fonction pour installer avec winget
function Install-WithWinget {
  param([string]$PackageId, [string]$PackageName)
  
  if (Test-Cmd -Name "winget") {
    Write-Host "[*] Installation de $PackageName via winget..." -ForegroundColor Yellow
    try {
      $result = winget install --id $PackageId --accept-package-agreements --accept-source-agreements --silent 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $PackageName installe avec succes via winget" -ForegroundColor Green
        return $true
      } else {
        Write-Host "[!] Installation via winget echouee (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "[!] Erreur lors de l'installation via winget: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Fonction pour installer avec Chocolatey
function Install-WithChoco {
  param([string]$PackageName, [string]$DisplayName)
  
  if (Test-Cmd -Name "choco") {
    Write-Host "[*] Installation de $DisplayName via Chocolatey..." -ForegroundColor Yellow
    try {
      choco install $PackageName -y --no-progress
      if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $DisplayName installe avec succes via Chocolatey" -ForegroundColor Green
        return $true
      } else {
        Write-Host "[!] Installation via Chocolatey echouee (code: $LASTEXITCODE)" -ForegroundColor Yellow
        return $false
      }
    } catch {
      Write-Host "[!] Erreur lors de l'installation via Chocolatey: $_" -ForegroundColor Yellow
      return $false
    }
  }
  return $false
}

# Fonction pour rafraichir le PATH
function Refresh-Path {
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = $machinePath + ";" + $userPath
  # Attendre un peu pour que les changements soient pris en compte
  Start-Sleep -Seconds 2
}

# Installer Chocolatey si necessaire
if (-not (Test-Cmd -Name "choco")) {
  Write-Host "[*] Installation de Chocolatey..." -ForegroundColor Yellow
  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoInstallScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
    Invoke-Expression $chocoInstallScript
    
    # Rafraichir l'environnement
    Refresh-Path
    
    # Verifier que Chocolatey est installe
    if (Test-Cmd -Name "choco") {
      Write-Host "[OK] Chocolatey installe avec succes" -ForegroundColor Green
    } else {
      Write-Host "[!] Chocolatey pourrait ne pas etre dans le PATH. Redemarrez PowerShell et reessayez." -ForegroundColor Yellow
    }
  } catch {
    Write-Host "[!] Erreur lors de l'installation de Chocolatey: $_" -ForegroundColor Yellow
    Write-Host "   Vous pouvez l'installer manuellement: https://chocolatey.org/install" -ForegroundColor Yellow
  }
}

# Installer Git
if (-not (Test-Cmd -Name "git")) {
  Write-Host "[*] Installation de Git..." -ForegroundColor Yellow
  $gitInstalled = $false
  if (-not (Install-WithWinget -PackageId "Git.Git" -PackageName "Git")) {
    if (-not (Install-WithChoco -PackageName "git" -DisplayName "Git")) {
      Write-Host "[ERREUR] Impossible d'installer Git automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://git-scm.com/download/win" -ForegroundColor Yellow
      Write-Host "   Apres installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
      $gitInstalled = $false
    } else {
      $gitInstalled = $true
    }
  } else {
    $gitInstalled = $true
  }
  
  if ($gitInstalled) {
    Refresh-Path
    # Verifier que Git est maintenant disponible
    if (Test-Cmd -Name "git") {
      Write-Host "[OK] Git installe et disponible" -ForegroundColor Green
    } else {
      Write-Host "[!] Git installe mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "[OK] Git deja installe: $(git --version 2>&1)" -ForegroundColor Green
}

# Installer Node.js
if (-not (Test-Cmd -Name "node")) {
  Write-Host "[*] Installation de Node.js..." -ForegroundColor Yellow
  $nodeInstalled = $false
  if (-not (Install-WithWinget -PackageId "OpenJS.NodeJS.LTS" -PackageName "Node.js")) {
    if (-not (Install-WithChoco -PackageName "nodejs-lts" -DisplayName "Node.js")) {
      Write-Host "[ERREUR] Impossible d'installer Node.js automatiquement." -ForegroundColor Red
      Write-Host "   Veuillez l'installer manuellement: https://nodejs.org/" -ForegroundColor Yellow
      Write-Host "   Apres installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
      $nodeInstalled = $false
    } else {
      $nodeInstalled = $true
    }
  } else {
    $nodeInstalled = $true
  }
  
  if ($nodeInstalled) {
    Refresh-Path
    # Verifier que Node.js est maintenant disponible
    if (Test-Cmd -Name "node") {
      Write-Host "[OK] Node.js installe et disponible" -ForegroundColor Green
    } else {
      Write-Host "[!] Node.js installe mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "[OK] Node.js deja installe: $(node --version 2>&1)" -ForegroundColor Green
}

# Installer Python (installation manuelle recommandee)
if (-not (Test-Cmd -Name "python") -and -not (Test-Cmd -Name "py")) {
  Write-Host "[*] Installation de Python..." -ForegroundColor Yellow
  Write-Host "[!] Python doit etre installe manuellement pour une meilleure compatibilite." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "   Instructions:" -ForegroundColor Cyan
  Write-Host "   1. Telechargez Python depuis: https://www.python.org/downloads/" -ForegroundColor White
  Write-Host "   2. Lancez l'installateur" -ForegroundColor White
  Write-Host "   3. IMPORTANT: Cochez 'Add Python to PATH' lors de l'installation!" -ForegroundColor Yellow
  Write-Host "   4. Cliquez sur 'Install Now'" -ForegroundColor White
  Write-Host "   5. Apres installation, fermez et rouvrez PowerShell" -ForegroundColor White
  Write-Host ""
  
  $response = Read-Host "Voulez-vous ouvrir la page de telechargement de Python maintenant? (o/N)"
  if ($response -eq "o" -or $response -eq "O") {
    Start-Process "https://www.python.org/downloads/"
  }
  
  Write-Host ""
  Write-Host "[!] Apres avoir installe Python, relancez ce script." -ForegroundColor Yellow
  Write-Host ""
  exit 1
} else {
  $pythonVersion = if (Test-Cmd -Name "python") { python --version 2>&1 } else { py --version 2>&1 }
  Write-Host "[OK] Python deja installe: $pythonVersion" -ForegroundColor Green
}

# Installer jq
if (-not (Test-Cmd -Name "jq")) {
  Write-Host "[*] Installation de jq..." -ForegroundColor Yellow
  $jqInstalled = $false
  if (Test-Cmd -Name "winget") {
    Write-Host "  Installation via winget..." -ForegroundColor Gray
    try {
      winget install --id jqlang.jq --accept-package-agreements --accept-source-agreements --silent
      if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] jq installe avec succes via winget" -ForegroundColor Green
        $jqInstalled = $true
      } else {
        Write-Host "[!] Installation via winget echouee (code: $LASTEXITCODE)" -ForegroundColor Yellow
      }
    } catch {
      Write-Host "[!] Erreur lors de l'installation via winget: $_" -ForegroundColor Yellow
    }
  }
  
  if (-not $jqInstalled) {
    Write-Host "[!] Impossible d'installer jq automatiquement." -ForegroundColor Yellow
    Write-Host "   Installez manuellement: winget install jqlang.jq" -ForegroundColor Yellow
  } else {
    Refresh-Path
    if (Test-Cmd -Name "jq") {
      Write-Host "[OK] jq installe et disponible" -ForegroundColor Green
    } else {
      Write-Host "[!] jq installe mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "[OK] jq deja installe: $(jq --version 2>&1)" -ForegroundColor Green
}

# Installer MongoDB
if (-not (Test-Cmd -Name "mongod")) {
  Write-Host "[*] Installation de MongoDB..." -ForegroundColor Yellow
  $mongoInstalled = $false
  if (-not (Install-WithWinget -PackageId "MongoDB.Server" -PackageName "MongoDB")) {
    if (-not (Install-WithChoco -PackageName "mongodb" -DisplayName "MongoDB")) {
      Write-Host "[!] Impossible d'installer MongoDB automatiquement." -ForegroundColor Yellow
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
    Write-Host "[!] MongoDB installe. Pour demarrer MongoDB:" -ForegroundColor Yellow
    Write-Host "   net start MongoDB" -ForegroundColor Cyan
    Write-Host "   Ou via Services: services.msc > MongoDB" -ForegroundColor Cyan
  }
} else {
  Write-Host "[OK] MongoDB deja installe" -ForegroundColor Green
}

# Installer pnpm
if (-not (Test-Cmd -Name "pnpm")) {
  if (Test-Cmd -Name "node") {
    Write-Host "[*] Installation de pnpm..." -ForegroundColor Yellow
    try {
      npm install -g pnpm
      Refresh-Path
      if (Test-Cmd -Name "pnpm") {
        Write-Host "[OK] pnpm installe: $(pnpm --version 2>&1)" -ForegroundColor Green
      } else {
        Write-Host "[!] pnpm installe mais pas encore dans le PATH. Fermez et rouvrez PowerShell." -ForegroundColor Yellow
      }
    } catch {
      Write-Host "[!] Erreur lors de l'installation de pnpm: $_" -ForegroundColor Yellow
      Write-Host "   Vous pouvez l'installer manuellement: npm install -g pnpm" -ForegroundColor Yellow
    }
  } else {
    Write-Host "[!] Node.js n'est pas disponible. pnpm ne peut pas etre installe." -ForegroundColor Yellow
  }
} else {
  Write-Host "[OK] pnpm deja installe: $(pnpm --version 2>&1)" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[OK] Installation terminee!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Verification des versions installees:" -ForegroundColor Cyan
Write-Host ""

$allInstalled = $true

# Verifier Git
if (Test-Cmd -Name "git") {
  try { 
    $gitVer = git --version 2>&1
    Write-Host "  [OK] Git: $gitVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] Git: Installe mais erreur lors de la verification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  [ERREUR] Git: Non installe" -ForegroundColor Red
  $allInstalled = $false
}

# Verifier Node.js
if (Test-Cmd -Name "node") {
  try { 
    $nodeVer = node --version 2>&1
    Write-Host "  [OK] Node.js: $nodeVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] Node.js: Installe mais erreur lors de la verification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  [ERREUR] Node.js: Non installe" -ForegroundColor Red
  $allInstalled = $false
}

# Verifier Python
if ((Test-Cmd -Name "python") -or (Test-Cmd -Name "py")) {
  try { 
    $pyVer = if (Test-Cmd -Name "python") { python --version 2>&1 } else { py --version 2>&1 }
    Write-Host "  [OK] Python: $pyVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] Python: Installe mais erreur lors de la verification" -ForegroundColor Yellow
    $allInstalled = $false
  }
} else {
  Write-Host "  [ERREUR] Python: Non installe" -ForegroundColor Red
  $allInstalled = $false
}

# Verifier jq
if (Test-Cmd -Name "jq") {
  try { 
    $jqVer = jq --version 2>&1
    Write-Host "  [OK] jq: $jqVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] jq: Installe mais erreur lors de la verification" -ForegroundColor Yellow
  }
} else {
  Write-Host "  [!] jq: Non installe (optionnel)" -ForegroundColor Yellow
}

# Verifier pnpm
if (Test-Cmd -Name "pnpm") {
  try { 
    $pnpmVer = pnpm --version 2>&1
    Write-Host "  [OK] pnpm: $pnpmVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] pnpm: Installe mais erreur lors de la verification" -ForegroundColor Yellow
  }
} else {
  Write-Host "  [!] pnpm: Non installe (optionnel, npm peut etre utilise)" -ForegroundColor Yellow
}

# Verifier MongoDB
if (Test-Cmd -Name "mongod") {
  try { 
    $mongoVer = mongod --version 2>&1 | Select-Object -First 1
    Write-Host "  [OK] MongoDB: $mongoVer" -ForegroundColor Green 
  } catch { 
    Write-Host "  [!] MongoDB: Installe mais erreur lors de la verification" -ForegroundColor Yellow
  }
} else {
  Write-Host "  [!] MongoDB: Non installe (optionnel, peut utiliser MongoDB Atlas)" -ForegroundColor Yellow
}

Write-Host ""
# Verifier les prerequis essentiels (Git, Node.js, Python)
$essentialInstalled = $true
if (-not (Test-Cmd -Name "git")) {
    $essentialInstalled = $false
}
if (-not (Test-Cmd -Name "node")) {
    $essentialInstalled = $false
}
if (-not ((Test-Cmd -Name "python") -or (Test-Cmd -Name "py"))) {
    $essentialInstalled = $false
}

if (-not $essentialInstalled) {
  Write-Host "[!] ATTENTION: Certains prerequis essentiels ne sont pas installes." -ForegroundColor Yellow
  Write-Host "   (Git, Node.js, Python sont requis)" -ForegroundColor Yellow
  Write-Host "   Fermez et rouvrez PowerShell en tant qu'administrateur, puis reessayez." -ForegroundColor Yellow
  Write-Host ""
}

Write-Host "[*] Prochaines etapes:" -ForegroundColor Cyan
Write-Host "  1. Fermez et rouvrez PowerShell (important pour que le PATH soit mis a jour)" -ForegroundColor White
Write-Host "  2. Cloner le projet: git clone https://github.com/we-dream-team/Halimou.git" -ForegroundColor White
Write-Host "  3. Aller dans le dossier: cd Halimou" -ForegroundColor White
Write-Host "  4. Lancer l'installation: .\install-and-start.ps1" -ForegroundColor White
Write-Host ""
Write-Host "[*] Astuce: Si des commandes ne sont pas reconnues apres reouverture," -ForegroundColor Yellow
Write-Host "   redemarrez votre ordinateur pour que tous les changements de PATH soient appliques." -ForegroundColor Yellow
Write-Host ""

# Proposer de cloner et demarrer automatiquement
# Utiliser essentialInstalled au lieu de allInstalled pour permettre de continuer sans MongoDB
if ($essentialInstalled) {
    Write-Host ""
    Write-Host "[*] Voulez-vous que je clone le projet et demarre l'application maintenant?" -ForegroundColor Cyan
    Write-Host "   (Le script va cloner le repo, installer les dependances et demarrer l'app)" -ForegroundColor Gray
    Write-Host "   Note: Si les commandes ne sont pas reconnues, fermez et rouvrez PowerShell d'abord." -ForegroundColor Yellow
    $response = Read-Host "Continuer? (o/N)"
    
    if ($response -eq "o" -or $response -eq "O") {
        Write-Host ""
        Write-Host "[*] Rafraichissement du PATH..." -ForegroundColor Yellow
        Refresh-Path
        
        # Verifier que Git est disponible
        if (-not (Test-Cmd -Name "git")) {
            Write-Host "[!] Git n'est pas encore dans le PATH." -ForegroundColor Yellow
            Write-Host "   Fermez et rouvrez PowerShell, puis relancez:" -ForegroundColor Yellow
            Write-Host "   git clone https://github.com/we-dream-team/Halimou.git" -ForegroundColor White
            Write-Host "   cd Halimou" -ForegroundColor White
            Write-Host "   .\install-and-start.ps1" -ForegroundColor White
            exit 0
        }
        
        Write-Host "[*] Clonage du projet..." -ForegroundColor Yellow
        
        # Determiner le dossier de destination
        $currentDir = Get-Location
        $projectDir = Join-Path $currentDir "Halimou"
        
        # Verifier si le dossier existe deja
        if (Test-Path $projectDir) {
            Write-Host "[!] Le dossier Halimou existe deja." -ForegroundColor Yellow
            $overwrite = Read-Host "Voulez-vous le supprimer et re-cloner? (o/N)"
            if ($overwrite -eq "o" -or $overwrite -eq "O") {
                Remove-Item -Path $projectDir -Recurse -Force
                Write-Host "[OK] Dossier supprime" -ForegroundColor Green
            } else {
                Write-Host "[*] Utilisation du dossier existant" -ForegroundColor Yellow
            }
        }
        
        # Cloner le projet si le dossier n'existe pas
        if (-not (Test-Path $projectDir)) {
            try {
                & git clone https://github.com/we-dream-team/Halimou.git $projectDir
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Projet clone avec succes" -ForegroundColor Green
                } else {
                    throw "Echec du clonage (code: $LASTEXITCODE)"
                }
            } catch {
                Write-Host "[ERREUR] Impossible de cloner le projet: $_" -ForegroundColor Red
                Write-Host "   Verifiez que Git est installe et dans le PATH." -ForegroundColor Yellow
                Write-Host "   Clonez manuellement: git clone https://github.com/we-dream-team/Halimou.git" -ForegroundColor Yellow
                exit 1
            }
        }
        
        # Aller dans le dossier du projet
        Set-Location $projectDir
        
        Write-Host ""
        Write-Host "[*] Installation et demarrage de l'application..." -ForegroundColor Yellow
        Write-Host ""
        
        # Lancer le script d'installation et demarrage
        if (Test-Path ".\install-and-start.ps1") {
            try {
                # Executer dans le contexte actuel pour garder le PATH rafraichi
                & ".\install-and-start.ps1"
            } catch {
                Write-Host "[ERREUR] Erreur lors du demarrage: $_" -ForegroundColor Red
                Write-Host "   Lancez manuellement: .\install-and-start.ps1" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERREUR] Script install-and-start.ps1 introuvable dans le projet clone." -ForegroundColor Red
            Write-Host "   Lancez manuellement: cd Halimou puis .\install-and-start.ps1" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "[*] Pour cloner et demarrer manuellement:" -ForegroundColor Cyan
        Write-Host "   git clone https://github.com/we-dream-team/Halimou.git" -ForegroundColor White
        Write-Host "   cd Halimou" -ForegroundColor White
        Write-Host "   .\install-and-start.ps1" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "[!] Certains prerequis ne sont pas installes. Installez-les d'abord." -ForegroundColor Yellow
    Write-Host "   Puis relancez ce script pour cloner et demarrer l'application." -ForegroundColor Yellow
    Write-Host ""
}
