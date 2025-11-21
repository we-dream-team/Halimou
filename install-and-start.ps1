Param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Function Test-Cmd {
  param([Parameter(Mandatory=$true)][string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "[Halimou] OS détecté: Windows"
$Root = Split-Path -Parent $PSCommandPath
Write-Host "[Halimou] Dossier projet: $Root"

Write-Host "[Halimou] Vérification des dépendances (Python3, Node.js)"
if (-not (Test-Cmd -Name "python")) {
  if (-not (Test-Cmd -Name "py")) {
    Write-Warning "Python introuvable. Installez Python 3 puis relancez."
    exit 1
  }
}
if (-not (Test-Cmd -Name "node")) {
  Write-Warning "Node.js introuvable. Installez Node.js puis relancez."
  exit 1
}

# Backend
Write-Host "[Halimou] Installation backend..."
Set-Location "$Root\backend"
if (-not (Test-Path ".venv")) {
  if (Test-Cmd -Name "py") {
    py -3 -m venv .venv
  } else {
    python -m venv .venv
  }
}
& "$Root\backend\.venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip
pip install -r requirements.txt

if (Test-Path ".env") {
  Get-Content ".env" | ForEach-Object {
    if ($_ -match "^\s*#") { return }
    if ($_ -match "^\s*$") { return }
    $parts = $_.Split("=",2)
    if ($parts.Count -eq 2) {
      [System.Environment]::SetEnvironmentVariable($parts[0], $parts[1])
    }
  }
}
if (-not $env:MONGO_URL) { $env:MONGO_URL = "mongodb://localhost:27017" }
if (-not $env:DB_NAME) { $env:DB_NAME = "halimou" }

Write-Host "[Halimou] Initialisation des index MongoDB..."
try { python init_db.py } catch { Write-Warning "init_db.py: $($_.Exception.Message)" }
deactivate

# Frontend
Write-Host "[Halimou] Installation frontend..."
Set-Location "$Root\frontend"
if (Test-Cmd -Name "pnpm") {
  pnpm install
} elseif (Test-Cmd -Name "yarn") {
  yarn install
} else {
  npm install
}

Write-Host "[Halimou] Lancement de l'application (backend + frontend)..."
Set-Location "$Root"
if (Test-Cmd -Name "bash") {
  bash "./start-dev.sh"
} elseif (Test-Cmd -Name "zsh") {
  zsh "./start-dev.sh"
} else {
  Write-Host "Démarrez manuellement: backend (uvicorn) et frontend (npm run dev)"
}


