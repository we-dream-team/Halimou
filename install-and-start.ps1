Param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Function Test-Cmd {
  param([Parameter(Mandatory=$true)][string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "[Halimou] OS detecte: Windows" -ForegroundColor Cyan
$Root = Split-Path -Parent $PSCommandPath
Write-Host "[Halimou] Dossier projet: $Root" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Halimou] Verification des dependances (Python3, Node.js)" -ForegroundColor Cyan

# Fonction pour tester si Python fonctionne vraiment
function Test-PythonWorks {
  param([string]$PythonCmd)
  
  try {
    # Nettoyer le chemin
    $cleanPath = $PythonCmd.Trim('"', "'")
    
    # Tester avec une commande simple
    $result = & $cleanPath -c "import sys; print(sys.version_info.major)" 2>&1
    if ($LASTEXITCODE -eq 0 -and $result -match "^3") {
      return $true
    }
  } catch {
    return $false
  }
  return $false
}

# Fonction pour trouver Python
function Find-Python {
  # Chercher d'abord dans les emplacements communs (plus fiable)
  $pythonPaths = @(
    "$env:LOCALAPPDATA\Programs\Python\Python3*\python.exe",
    "$env:ProgramFiles\Python3*\python.exe",
    "$env:ProgramFiles(x86)\Python3*\python.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python3*\python.exe"
  )
  
  foreach ($pathPattern in $pythonPaths) {
    $found = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found -and (Test-Path $found.FullName)) {
      $fullPath = $found.FullName
      if (Test-PythonWorks -PythonCmd "`"$fullPath`"") {
        return "`"$fullPath`""
      }
    }
  }
  
  # Essayer py -3 (launcher Windows)
  if (Test-Cmd -Name "py") {
    try {
      $version = py -3 --version 2>&1
      if ($version -match "Python 3" -and (Test-PythonWorks -PythonCmd "py -3")) {
        return "py -3"
      }
    } catch {
      # Ignorer les erreurs
    }
  }
  
  # Essayer python3
  if (Test-Cmd -Name "python3") {
    try {
      $version = python3 --version 2>&1
      if ($version -match "Python 3" -and (Test-PythonWorks -PythonCmd "python3")) {
        return "python3"
      }
    } catch {
      # Ignorer les erreurs
    }
  }
  
  # Essayer python (en dernier car souvent un alias vers Microsoft Store)
  if (Test-Cmd -Name "python") {
    try {
      # Vérifier que ce n'est pas juste un alias vers le Microsoft Store
      $version = python --version 2>&1
      if ($version -match "Python 3" -and -not ($version -match "Microsoft Store" -or $version -match "introuvable")) {
        if (Test-PythonWorks -PythonCmd "python") {
          return "python"
        }
      }
    } catch {
      # Ignorer les erreurs
    }
  }
  
  return $null
}

$pythonCmd = Find-Python

if (-not $pythonCmd) {
  Write-Host "[ERREUR] Python introuvable. Installez Python 3 puis relancez." -ForegroundColor Red
  Write-Host "   Executez d'abord: .\install-prerequisites.ps1" -ForegroundColor Yellow
  Write-Host "   Ou installez Python manuellement: https://www.python.org/downloads/" -ForegroundColor Yellow
  Write-Host "   IMPORTANT: Cochez 'Add Python to PATH' lors de l'installation!" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "   Apres installation, fermez et rouvrez PowerShell." -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Cmd -Name "node")) {
  Write-Host "[ERREUR] Node.js introuvable. Installez Node.js puis relancez." -ForegroundColor Red
  Write-Host "   Executez d'abord: .\install-prerequisites.ps1" -ForegroundColor Yellow
  exit 1
}

# Afficher les versions trouvees
try {
  $cleanPythonPath = $pythonCmd.Trim('"', "'")
  $pyVersion = & $cleanPythonPath --version 2>&1
  Write-Host "[OK] Python trouve: $pythonCmd ($pyVersion)" -ForegroundColor Green
} catch {
  Write-Host "[OK] Python trouve: $pythonCmd" -ForegroundColor Green
}
Write-Host "[OK] Node.js trouve: $(node --version)" -ForegroundColor Green
Write-Host ""

# Backend
Write-Host "[Halimou] Installation backend..." -ForegroundColor Cyan
Set-Location "$Root\backend"

if (-not (Test-Path ".venv")) {
  Write-Host "  Creation de l'environnement virtuel Python..." -ForegroundColor Yellow
  Write-Host "  Utilisation de: $pythonCmd" -ForegroundColor Gray
  
  # Tester d'abord que Python fonctionne
  try {
    $cleanPythonPath = $pythonCmd.Trim('"', "'")
    $testResult = & $cleanPythonPath -c "import sys; print('OK')" 2>&1
    if ($LASTEXITCODE -ne 0 -or $testResult -notmatch "OK") {
      throw "Python ne peut pas executer de commandes"
    }
  } catch {
    Write-Host "  [ERREUR] Python detecte mais ne fonctionne pas correctement." -ForegroundColor Red
    Write-Host "  Le message d'erreur indique que Python n'est pas vraiment installe." -ForegroundColor Yellow
    Write-Host "  Solutions:" -ForegroundColor Yellow
    Write-Host "  1. Installez Python depuis https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "  2. Cochez 'Add Python to PATH' lors de l'installation" -ForegroundColor White
    Write-Host "  3. Redemarrez PowerShell apres l'installation" -ForegroundColor White
    Write-Host "  4. Ou executez: .\install-prerequisites.ps1" -ForegroundColor White
    exit 1
  }
  
  try {
    # Nettoyer le chemin Python
    $cleanPythonPath = $pythonCmd.Trim('"', "'")
    
    # Creer l'environnement virtuel
    $result = & $cleanPythonPath -m venv .venv 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Code de retour: $LASTEXITCODE"
    }
    if (-not (Test-Path ".venv")) {
      throw "Le dossier .venv n'a pas ete cree"
    }
    Write-Host "  [OK] Environnement virtuel cree" -ForegroundColor Green
  } catch {
    Write-Host "  [ERREUR] Erreur lors de la creation de l'environnement virtuel: $_" -ForegroundColor Red
    Write-Host "  Commande utilisee: $pythonCmd -m venv .venv" -ForegroundColor Yellow
    if ($result) {
      Write-Host "  Sortie: $result" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  Solutions possibles:" -ForegroundColor Yellow
    Write-Host "  1. Reinstallez Python depuis https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "  2. Cochez 'Add Python to PATH' lors de l'installation" -ForegroundColor White
    Write-Host "  3. Redemarrez PowerShell" -ForegroundColor White
    exit 1
  }
} else {
  Write-Host "  [OK] Environnement virtuel existant trouve" -ForegroundColor Green
}

$activateScript = "$Root\backend\.venv\Scripts\Activate.ps1"
$pythonInVenv = "$Root\backend\.venv\Scripts\python.exe"

if (-not (Test-Path $activateScript)) {
  Write-Host "  [ERREUR] Script d'activation introuvable: $activateScript" -ForegroundColor Red
  exit 1
}

# Fonction pour executer Python correctement
function Invoke-Python {
  param(
    [string]$PythonPath,
    [string[]]$Arguments
  )
  
  # Nettoyer le chemin Python (enlever les guillemets si presents)
  $cleanPath = $PythonPath.Trim('"', "'")
  
  # Executer avec l'operateur &
  & $cleanPath $Arguments
}

# Utiliser Python de l'environnement virtuel si disponible
$pythonExe = $null
if (Test-Path $pythonInVenv) {
  $pythonExe = $pythonInVenv
  Write-Host "  [OK] Utilisation de Python de l'environnement virtuel" -ForegroundColor Green
} else {
  # Extraire le chemin sans guillemets de $pythonCmd
  if ($pythonCmd -match '^"(.+)"$') {
    $pythonExe = $matches[1]
  } elseif ($pythonCmd -match "^'(.+)'$") {
    $pythonExe = $matches[1]
  } else {
    $pythonExe = $pythonCmd
  }
}

Write-Host "  Activation de l'environnement virtuel..." -ForegroundColor Yellow
try {
  & $activateScript
} catch {
  Write-Host "  [!] Erreur lors de l'activation (peut etre normal): $_" -ForegroundColor Yellow
}

Write-Host "  Mise a jour de pip..." -ForegroundColor Yellow
try {
  Invoke-Python -PythonPath $pythonExe -Arguments @("-m", "pip", "install", "--upgrade", "pip", "--quiet")
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] pip mis a jour" -ForegroundColor Green
  } else {
    throw "Code de retour: $LASTEXITCODE"
  }
} catch {
  Write-Host "  [!] Erreur lors de la mise a jour de pip: $_" -ForegroundColor Yellow
  Write-Host "      (Ce n'est pas critique, on continue...)" -ForegroundColor Gray
}

Write-Host "  Installation des dependances Python..." -ForegroundColor Yellow
try {
  Invoke-Python -PythonPath $pythonExe -Arguments @("-m", "pip", "install", "-r", "requirements.txt")
  if ($LASTEXITCODE -ne 0) {
    throw "Code de retour: $LASTEXITCODE"
  }
  Write-Host "  [OK] Dependances Python installees" -ForegroundColor Green
} catch {
  Write-Host "  [ERREUR] Erreur lors de l'installation des dependances: $_" -ForegroundColor Red
  Write-Host "  Commande utilisee: $pythonExe -m pip install -r requirements.txt" -ForegroundColor Yellow
  exit 1
}

if (Test-Path ".env") {
  Write-Host "  Chargement des variables d'environnement depuis .env..." -ForegroundColor Yellow
  Get-Content ".env" | ForEach-Object {
    if ($_ -match "^\s*#") { return }
    if ($_ -match "^\s*$") { return }
    $parts = $_.Split("=",2)
    if ($parts.Count -eq 2) {
      [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
  }
} else {
  Write-Host "  [!] Fichier .env non trouve, utilisation des valeurs par defaut" -ForegroundColor Yellow
}

if (-not $env:MONGO_URL) { $env:MONGO_URL = "mongodb://localhost:27017" }
if (-not $env:DB_NAME) { $env:DB_NAME = "halimou" }

Write-Host "  MongoDB URL: $env:MONGO_URL" -ForegroundColor Cyan
Write-Host "  Database: $env:DB_NAME" -ForegroundColor Cyan

Write-Host "  Initialisation des index MongoDB..." -ForegroundColor Yellow
try { 
  Invoke-Python -PythonPath $pythonExe -Arguments @("init_db.py")
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Index MongoDB initialises" -ForegroundColor Green
  } else {
    throw "Code de retour: $LASTEXITCODE"
  }
} catch { 
  Write-Host "  [!] Erreur lors de l'initialisation MongoDB: $_" -ForegroundColor Yellow
  Write-Host "     Assurez-vous que MongoDB est demarre" -ForegroundColor Yellow
}

try {
  deactivate
} catch {
  # Ignorer les erreurs de deactivate
}

# Frontend
Write-Host "[Halimou] Installation frontend..." -ForegroundColor Cyan
Set-Location "$Root\frontend"

$packageManager = $null
if (Test-Cmd -Name "pnpm") {
  $packageManager = "pnpm"
  Write-Host "  Utilisation de pnpm..." -ForegroundColor Yellow
} elseif (Test-Cmd -Name "yarn") {
  $packageManager = "yarn"
  Write-Host "  Utilisation de yarn..." -ForegroundColor Yellow
} else {
  $packageManager = "npm"
  Write-Host "  Utilisation de npm..." -ForegroundColor Yellow
}

try {
  if ($packageManager -eq "pnpm") {
    & pnpm install
  } elseif ($packageManager -eq "yarn") {
    & yarn install
  } else {
    & npm install
  }
  Write-Host "  [OK] Dependances frontend installees" -ForegroundColor Green
} catch {
  Write-Host "  [ERREUR] Erreur lors de l'installation des dependances frontend: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "[Halimou] Lancement de l'application (backend + frontend)..." -ForegroundColor Cyan
Write-Host ""

Set-Location "$Root"

# Fonction pour nettoyer les processus en cas d'interruption
function Cleanup-Processes {
    Write-Host ""
    Write-Host "[Halimou] Arret en cours..." -ForegroundColor Yellow
    if ($backendProcess -and -not $backendProcess.HasExited) {
        Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($frontendProcess -and -not $frontendProcess.HasExited) {
        Stop-Process -Id $frontendProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[Halimou] Arret termine." -ForegroundColor Green
}

# Enregistrer le gestionnaire d'evenements pour Ctrl+C
[Console]::TreatControlCAsInput = $false
$null = Register-EngineEvent PowerShell.Exiting -Action { Cleanup-Processes }

# Demander a l'utilisateur comment lancer
Write-Host "[*] Choisissez comment lancer l'application:" -ForegroundColor Cyan
Write-Host "  1. Lancer dans des fenetres PowerShell separees (recommandé)" -ForegroundColor White
Write-Host "  2. Lancer en arriere-plan dans cette fenetre" -ForegroundColor White
Write-Host "  3. Afficher les instructions manuelles" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Votre choix (1/2/3)"

if ($choice -eq "3") {
    Write-Host ""
    Write-Host "[*] Instructions manuelles:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Terminal 1 - Backend:" -ForegroundColor Cyan
    Write-Host "  cd backend" -ForegroundColor White
    Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor White
    Write-Host "  python -m uvicorn server:app --host 0.0.0.0 --port 8001 --reload" -ForegroundColor White
    Write-Host ""
    Write-Host "Terminal 2 - Frontend:" -ForegroundColor Cyan
    Write-Host "  cd frontend" -ForegroundColor White
    if ($packageManager -eq "pnpm") {
        Write-Host "  pnpm dev" -ForegroundColor White
    } elseif ($packageManager -eq "yarn") {
        Write-Host "  yarn dev" -ForegroundColor White
    } else {
        Write-Host "  npm run dev" -ForegroundColor White
    }
    Write-Host ""
    exit 0
}

# Preparer les commandes
$backendScript = @"
cd `"$Root\backend`"
`"$pythonExe`" -m uvicorn server:app --host 0.0.0.0 --port 8001 --reload
pause
"@

$frontendScript = @"
cd `"$Root\frontend`"
"@

if ($packageManager -eq "pnpm") {
    $frontendScript += "`npnpm dev"
} elseif ($packageManager -eq "yarn") {
    $frontendScript += "`nyarn dev"
} else {
    $frontendScript += "`nnpm run dev"
}
$frontendScript += "`npause"

if ($choice -eq "1") {
    # Lancer dans des fenetres separees
    Write-Host ""
    Write-Host "[*] Demarrage du backend dans une nouvelle fenetre..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $backendScriptPath = "$env:TEMP\halimou-backend-$timestamp.ps1"
    $backendScript | Out-File -FilePath $backendScriptPath -Encoding UTF8
    
    $backendProcess = Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$backendScriptPath`"" -WindowStyle Normal -PassThru
    
    Start-Sleep -Seconds 2
    
    Write-Host "[*] Demarrage du frontend dans une nouvelle fenetre..." -ForegroundColor Yellow
    $frontendScriptPath = "$env:TEMP\halimou-frontend-$timestamp.ps1"
    $frontendScript | Out-File -FilePath $frontendScriptPath -Encoding UTF8
    
    $frontendProcess = Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$frontendScriptPath`"" -WindowStyle Normal -PassThru
    
    Write-Host ""
    Write-Host "[OK] Backend et Frontend demarres dans des fenetres separees!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[*] URLs:" -ForegroundColor Cyan
    Write-Host "  - API Backend: http://localhost:8001" -ForegroundColor White
    Write-Host "  - Frontend Web: http://localhost:3000" -ForegroundColor White
    Write-Host ""
    Write-Host "[*] Pour arreter, fermez les fenetres PowerShell ou appuyez sur Ctrl+C dans chaque fenetre." -ForegroundColor Yellow
    Write-Host "[*] Pour redemarrer rapidement, utilisez: .\start-dev.ps1" -ForegroundColor Yellow
    Write-Host ""
    
} elseif ($choice -eq "2") {
    # Lancer en arriere-plan
    Write-Host ""
    Write-Host "[*] Demarrage du backend en arriere-plan..." -ForegroundColor Yellow
    
    $backendJob = Start-Job -ScriptBlock {
        param($Root, $PythonExe)
        Set-Location "$Root\backend"
        & $PythonExe -m uvicorn server:app --host 0.0.0.0 --port 8001 --reload
    } -ArgumentList $Root, $pythonExe
    
    Start-Sleep -Seconds 3
    
    Write-Host "[*] Demarrage du frontend en arriere-plan..." -ForegroundColor Yellow
    
    $frontendCmd = if ($packageManager -eq "pnpm") {
        "pnpm dev"
    } elseif ($packageManager -eq "yarn") {
        "yarn dev"
    } else {
        "npm run dev"
    }
    
    $frontendJob = Start-Job -ScriptBlock {
        param($Root, $Cmd)
        Set-Location "$Root\frontend"
        Invoke-Expression $Cmd
    } -ArgumentList $Root, $frontendCmd
    
    Write-Host ""
    Write-Host "[OK] Backend et Frontend demarres en arriere-plan!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[*] URLs:" -ForegroundColor Cyan
    Write-Host "  - API Backend: http://localhost:8001" -ForegroundColor White
    Write-Host "  - Frontend Web: http://localhost:3000" -ForegroundColor White
    Write-Host ""
    Write-Host "[*] Jobs PowerShell:" -ForegroundColor Cyan
    Write-Host "  Backend Job ID: $($backendJob.Id)" -ForegroundColor White
    Write-Host "  Frontend Job ID: $($frontendJob.Id)" -ForegroundColor White
    Write-Host ""
    Write-Host "[*] Pour voir les logs:" -ForegroundColor Yellow
    Write-Host "  Receive-Job -Id $($backendJob.Id)" -ForegroundColor White
    Write-Host "  Receive-Job -Id $($frontendJob.Id)" -ForegroundColor White
    Write-Host ""
    Write-Host "[*] Pour arreter:" -ForegroundColor Yellow
    Write-Host "  Stop-Job -Id $($backendJob.Id), $($frontendJob.Id)" -ForegroundColor White
    Write-Host "  Remove-Job -Id $($backendJob.Id), $($frontendJob.Id)" -ForegroundColor White
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arreter les services..." -ForegroundColor Yellow
    
    try {
        # Attendre et afficher les logs
        while ($true) {
            $backendOutput = Receive-Job -Id $backendJob.Id -ErrorAction SilentlyContinue
            $frontendOutput = Receive-Job -Id $frontendJob.Id -ErrorAction SilentlyContinue
            
            if ($backendOutput) {
                Write-Host "[Backend] $backendOutput" -ForegroundColor Cyan
            }
            if ($frontendOutput) {
                Write-Host "[Frontend] $frontendOutput" -ForegroundColor Magenta
            }
            
            if ($backendJob.State -eq "Failed" -or $frontendJob.State -eq "Failed") {
                Write-Host "[ERREUR] Un des services a echoue." -ForegroundColor Red
                break
            }
            
            Start-Sleep -Seconds 1
        }
    } finally {
        Cleanup-Processes
        Stop-Job -Id $backendJob.Id, $frontendJob.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $backendJob.Id, $frontendJob.Id -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "[ERREUR] Choix invalide." -ForegroundColor Red
    exit 1
}


