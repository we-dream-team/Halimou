# Script d'installation des services Windows pour Halimou
# Usage: .\install-windows-services.ps1
# IMPORTANT: Executez en tant qu'administrateur

Param(
    [switch]$Uninstall
)

# Verifier les privileges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERREUR] Ce script necessite des privileges administrateur." -ForegroundColor Red
    Write-Host "   Executez PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

$Root = Split-Path -Parent $PSCommandPath
$NSSMPath = "$Root\nssm"
$NSSMExe = "$NSSMPath\nssm.exe"

Write-Host "[Halimou] Installation des services Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour tester si une commande existe
function Test-Cmd {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Fonction pour trouver Python
function Find-Python {
  $pythonPaths = @(
    "$env:LOCALAPPDATA\Programs\Python\Python3*\python.exe",
    "$env:ProgramFiles\Python3*\python.exe",
    "$env:ProgramFiles(x86)\Python3*\python.exe"
  )
  
  foreach ($pathPattern in $pythonPaths) {
    $found = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found -and (Test-Path $found.FullName)) {
      return $found.FullName
    }
  }
  
  if (Test-Cmd -Name "py") {
    $version = py -3 --version 2>&1
    if ($version -match "Python 3") {
      return "py -3"
    }
  }
  
  if (Test-Cmd -Name "python") {
    $version = python --version 2>&1
    if ($version -match "Python 3") {
      return "python"
    }
  }
  
  return $null
}

# Fonction pour trouver Node.js
function Find-Node {
  if (Test-Cmd -Name "node") {
    return "node"
  }
  
  $nodePaths = @(
    "$env:ProgramFiles\nodejs\node.exe",
    "$env:ProgramFiles(x86)\nodejs\node.exe"
  )
  
  foreach ($path in $nodePaths) {
    if (Test-Path $path) {
      return $path
    }
  }
  
  return $null
}

# Telecharger et installer NSSM si necessaire
if (-not (Test-Path $NSSMExe)) {
    Write-Host "[*] Telechargement de NSSM..." -ForegroundColor Yellow
    
    if (-not (Test-Path $NSSMPath)) {
        New-Item -ItemType Directory -Path $NSSMPath -Force | Out-Null
    }
    
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    $nssmZip = "$NSSMPath\nssm.zip"
    
    try {
        Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip -UseBasicParsing
        
        # Extraire NSSM
        Expand-Archive -Path $nssmZip -DestinationPath $NSSMPath -Force
        
        # Trouver le bon dossier (peut etre nssm-2.24/win64 ou nssm-2.24/win32)
        $nssmFolders = Get-ChildItem -Path $NSSMPath -Directory | Where-Object { $_.Name -match "nssm" }
        if ($nssmFolders) {
            $arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
            $nssmArchPath = Join-Path $nssmFolders[0].FullName $arch
            
            if (Test-Path $nssmArchPath) {
                Copy-Item "$nssmArchPath\nssm.exe" -Destination $NSSMExe -Force
            } else {
                # Essayer de trouver nssm.exe directement
                $nssmExeFound = Get-ChildItem -Path $nssmFolders[0].FullName -Recurse -Filter "nssm.exe" | Select-Object -First 1
                if ($nssmExeFound) {
                    Copy-Item $nssmExeFound.FullName -Destination $NSSMExe -Force
                }
            }
        }
        
        Remove-Item $nssmZip -Force -ErrorAction SilentlyContinue
        
        if (Test-Path $NSSMExe) {
            Write-Host "[OK] NSSM installe" -ForegroundColor Green
        } else {
            throw "NSSM.exe non trouve apres extraction"
        }
    } catch {
        Write-Host "[ERREUR] Impossible de telecharger NSSM: $_" -ForegroundColor Red
        Write-Host "   Telechargez manuellement depuis: https://nssm.cc/download" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "[OK] NSSM deja installe" -ForegroundColor Green
}

# Desinstaller les services si demande
if ($Uninstall) {
    Write-Host ""
    Write-Host "[*] Desinstallation des services..." -ForegroundColor Yellow
    
    $services = @("HalimouBackend", "HalimouFrontend")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name $serviceName -Force
            }
            & $NSSMExe remove $serviceName confirm
            Write-Host "[OK] Service $serviceName desinstalle" -ForegroundColor Green
        } else {
            Write-Host "[*] Service $serviceName n'existe pas" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "[OK] Desinstallation terminee" -ForegroundColor Green
    exit 0
}

# Verifier les prerequis
$pythonExe = Find-Python
$nodeExe = Find-Node

if (-not $pythonExe) {
    Write-Host "[ERREUR] Python introuvable. Installez Python 3 d'abord." -ForegroundColor Red
    exit 1
}

if (-not $nodeExe) {
    Write-Host "[ERREUR] Node.js introuvable. Installez Node.js d'abord." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Python trouve: $pythonExe" -ForegroundColor Green
Write-Host "[OK] Node.js trouve: $nodeExe" -ForegroundColor Green
Write-Host ""

# Verifier que l'environnement virtuel existe
$venvPython = "$Root\backend\.venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Host "[ERREUR] Environnement virtuel Python non trouve." -ForegroundColor Red
    Write-Host "   Executez d'abord: .\install-and-start.ps1" -ForegroundColor Yellow
    exit 1
}

# Verifier que le frontend est construit
$frontendBuild = "$Root\frontend\.next"
if (-not (Test-Path $frontendBuild)) {
    Write-Host "[*] Construction du frontend..." -ForegroundColor Yellow
    Set-Location "$Root\frontend"
    if (Test-Cmd -Name "pnpm") {
        & pnpm build
    } elseif (Test-Cmd -Name "yarn") {
        & yarn build
    } else {
        & npm run build
    }
    Set-Location $Root
    
    if (-not (Test-Path $frontendBuild)) {
        Write-Host "[ERREUR] Echec de la construction du frontend." -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Frontend construit" -ForegroundColor Green
}

Write-Host ""
Write-Host "[*] Installation des services Windows..." -ForegroundColor Yellow
Write-Host ""

# Service Backend
$backendServiceName = "HalimouBackend"
$backendApp = $venvPython
$backendAppDir = "$Root\backend"
$backendArgs = "-m uvicorn server:app --host 0.0.0.0 --port 8001"

Write-Host "[*] Installation du service Backend..." -ForegroundColor Yellow

# Supprimer le service s'il existe deja
$existingService = Get-Service -Name $backendServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    if ($existingService.Status -eq "Running") {
        Stop-Service -Name $backendServiceName -Force
    }
    & $NSSMExe remove $backendServiceName confirm
}

# Creer le service
& $NSSMExe install $backendServiceName $backendApp $backendArgs
& $NSSMExe set $backendServiceName AppDirectory $backendAppDir
& $NSSMExe set $backendServiceName DisplayName "Halimou Backend API"
& $NSSMExe set $backendServiceName Description "Service API Backend pour l'application Halimou"
& $NSSMExe set $backendServiceName Start SERVICE_AUTO_START
& $NSSMExe set $backendServiceName AppStdout "$Root\logs\backend.log"
& $NSSMExe set $backendServiceName AppStderr "$Root\logs\backend-error.log"
& $NSSMExe set $backendServiceName AppRotateFiles 1
& $NSSMExe set $backendServiceName AppRotateOnline 1
& $NSSMExe set $backendServiceName AppRotateSeconds 86400
& $NSSMExe set $backendServiceName AppRotateBytes 10485760

# Creer le dossier logs si necessaire
$logsDir = "$Root\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

Write-Host "[OK] Service Backend installe" -ForegroundColor Green

# Service Frontend
$frontendServiceName = "HalimouFrontend"
$frontendApp = $nodeExe
$frontendAppDir = "$Root\frontend"
$frontendArgs = "$Root\frontend\node_modules\.bin\next start -p 3000"

# Verifier que next est installe
$nextBin = "$Root\frontend\node_modules\.bin\next.cmd"
if (-not (Test-Path $nextBin)) {
    Write-Host "[*] Installation des dependances frontend..." -ForegroundColor Yellow
    Set-Location "$Root\frontend"
    if (Test-Cmd -Name "pnpm") {
        & pnpm install
    } elseif (Test-Cmd -Name "yarn") {
        & yarn install
    } else {
        & npm install
    }
    Set-Location $Root
}

Write-Host "[*] Installation du service Frontend..." -ForegroundColor Yellow

# Supprimer le service s'il existe deja
$existingService = Get-Service -Name $frontendServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    if ($existingService.Status -eq "Running") {
        Stop-Service -Name $frontendServiceName -Force
    }
    & $NSSMExe remove $frontendServiceName confirm
}

# Utiliser node directement avec le chemin complet de next
$nextPath = if (Test-Path "$Root\frontend\node_modules\.bin\next.cmd") {
    "$Root\frontend\node_modules\.bin\next.cmd"
} else {
    "$Root\frontend\node_modules\next\dist\bin\next"
}

$frontendArgs = "`"$nextPath`" start -p 3000"

# Creer le service
& $NSSMExe install $frontendServiceName $frontendApp $frontendArgs
& $NSSMExe set $frontendServiceName AppDirectory $frontendAppDir
& $NSSMExe set $frontendServiceName DisplayName "Halimou Frontend Web"
& $NSSMExe set $frontendServiceName Description "Service Frontend Web pour l'application Halimou"
& $NSSMExe set $frontendServiceName Start SERVICE_AUTO_START
& $NSSMExe set $frontendServiceName AppStdout "$Root\logs\frontend.log"
& $NSSMExe set $frontendServiceName AppStderr "$Root\logs\frontend-error.log"
& $NSSMExe set $frontendServiceName AppRotateFiles 1
& $NSSMExe set $frontendServiceName AppRotateOnline 1
& $NSSMExe set $frontendServiceName AppRotateSeconds 86400
& $NSSMExe set $frontendServiceName AppRotateBytes 10485760

Write-Host "[OK] Service Frontend installe" -ForegroundColor Green

Write-Host ""
Write-Host "[OK] Installation terminee!" -ForegroundColor Green
Write-Host ""
Write-Host "[*] Services crees:" -ForegroundColor Cyan
Write-Host "  - HalimouBackend (Port 8001)" -ForegroundColor White
Write-Host "  - HalimouFrontend (Port 3000)" -ForegroundColor White
Write-Host ""
Write-Host "[*] Commandes utiles:" -ForegroundColor Cyan
Write-Host "  Demarrer les services:" -ForegroundColor Yellow
Write-Host "    Start-Service HalimouBackend" -ForegroundColor White
Write-Host "    Start-Service HalimouFrontend" -ForegroundColor White
Write-Host ""
Write-Host "  Arreter les services:" -ForegroundColor Yellow
Write-Host "    Stop-Service HalimouBackend" -ForegroundColor White
Write-Host "    Stop-Service HalimouFrontend" -ForegroundColor White
Write-Host ""
Write-Host "  Voir le statut:" -ForegroundColor Yellow
Write-Host "    Get-Service Halimou*" -ForegroundColor White
Write-Host ""
Write-Host "  Desinstaller:" -ForegroundColor Yellow
Write-Host "    .\install-windows-services.ps1 -Uninstall" -ForegroundColor White
Write-Host ""
Write-Host "[*] Les services demarreront automatiquement au demarrage de Windows." -ForegroundColor Green
Write-Host ""

