Param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Function Test-Cmd {
  param([Parameter(Mandatory=$true)][string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "[Halimou] OS détecté: Windows"
$Root = Split-Path -Parent $PSCommandPath
Write-Host "[Halimou] Dossier projet: $Root"

Write-Host "[Halimou] Vérification des dépendances (Python3, Node.js)"
$pythonCmd = $null
if (Test-Cmd -Name "python") {
  $pythonCmd = "python"
} elseif (Test-Cmd -Name "py") {
  $pythonCmd = "py"
} else {
  Write-Host "❌ Python introuvable. Installez Python 3 puis relancez." -ForegroundColor Red
  Write-Host "   Exécutez d'abord: .\install-prerequisites.ps1" -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Cmd -Name "node")) {
  Write-Host "❌ Node.js introuvable. Installez Node.js puis relancez." -ForegroundColor Red
  Write-Host "   Exécutez d'abord: .\install-prerequisites.ps1" -ForegroundColor Yellow
  exit 1
}

Write-Host "✅ Python trouvé: $pythonCmd" -ForegroundColor Green
Write-Host "✅ Node.js trouvé: $(node --version)" -ForegroundColor Green

# Backend
Write-Host "[Halimou] Installation backend..." -ForegroundColor Cyan
Set-Location "$Root\backend"

if (-not (Test-Path ".venv")) {
  Write-Host "  Création de l'environnement virtuel Python..." -ForegroundColor Yellow
  try {
    if ($pythonCmd -eq "py") {
      & py -3 -m venv .venv
    } else {
      & python -m venv .venv
    }
    if (-not (Test-Path ".venv")) {
      throw "Échec de la création de l'environnement virtuel"
    }
    Write-Host "  ✅ Environnement virtuel créé" -ForegroundColor Green
  } catch {
    Write-Host "  ❌ Erreur lors de la création de l'environnement virtuel: $_" -ForegroundColor Red
    exit 1
  }
} else {
  Write-Host "  ✅ Environnement virtuel existant trouvé" -ForegroundColor Green
}

$activateScript = "$Root\backend\.venv\Scripts\Activate.ps1"
if (-not (Test-Path $activateScript)) {
  Write-Host "  ❌ Script d'activation introuvable: $activateScript" -ForegroundColor Red
  exit 1
}

Write-Host "  Activation de l'environnement virtuel..." -ForegroundColor Yellow
try {
  & $activateScript
} catch {
  Write-Host "  ⚠️  Erreur lors de l'activation (peut être normal): $_" -ForegroundColor Yellow
}

Write-Host "  Mise à jour de pip..." -ForegroundColor Yellow
try {
  & python -m pip install --upgrade pip --quiet
  Write-Host "  ✅ pip mis à jour" -ForegroundColor Green
} catch {
  Write-Host "  ⚠️  Erreur lors de la mise à jour de pip: $_" -ForegroundColor Yellow
}

Write-Host "  Installation des dépendances Python..." -ForegroundColor Yellow
try {
  & pip install -r requirements.txt
  Write-Host "  ✅ Dépendances Python installées" -ForegroundColor Green
} catch {
  Write-Host "  ❌ Erreur lors de l'installation des dépendances: $_" -ForegroundColor Red
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
  Write-Host "  ⚠️  Fichier .env non trouvé, utilisation des valeurs par défaut" -ForegroundColor Yellow
}

if (-not $env:MONGO_URL) { $env:MONGO_URL = "mongodb://localhost:27017" }
if (-not $env:DB_NAME) { $env:DB_NAME = "halimou" }

Write-Host "  MongoDB URL: $env:MONGO_URL" -ForegroundColor Cyan
Write-Host "  Database: $env:DB_NAME" -ForegroundColor Cyan

Write-Host "  Initialisation des index MongoDB..." -ForegroundColor Yellow
try { 
  & python init_db.py
  Write-Host "  ✅ Index MongoDB initialisés" -ForegroundColor Green
} catch { 
  Write-Host "  ⚠️  Erreur lors de l'initialisation MongoDB: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "     Assurez-vous que MongoDB est démarré" -ForegroundColor Yellow
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
  Write-Host "  ✅ Dépendances frontend installées" -ForegroundColor Green
} catch {
  Write-Host "  ❌ Erreur lors de l'installation des dépendances frontend: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "[Halimou] Lancement de l'application (backend + frontend)..." -ForegroundColor Cyan
Write-Host ""

Set-Location "$Root"

# Sur Windows, on ne peut pas utiliser bash/zsh facilement, donc on lance directement
Write-Host "⚠️  Sur Windows, vous devez lancer le backend et le frontend dans deux terminaux séparés:" -ForegroundColor Yellow
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
Write-Host "Ou utilisez le script start-dev.sh si vous avez Git Bash ou WSL installé." -ForegroundColor Yellow
Write-Host ""


