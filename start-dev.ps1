# Script de demarrage rapide pour Halimou (Windows)
# Usage: .\start-dev.ps1

$Root = Split-Path -Parent $PSCommandPath

Write-Host "[Halimou] Demarrage de l'application" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

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
  
  if (Get-Command "py" -ErrorAction SilentlyContinue) {
    $version = py -3 --version 2>&1
    if ($version -match "Python 3") {
      return "py -3"
    }
  }
  
  if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $version = python --version 2>&1
    if ($version -match "Python 3") {
      return "python"
    }
  }
  
  return $null
}

# Verifier les prerequis
$pythonExe = Find-Python
$venvPython = "$Root\backend\.venv\Scripts\python.exe"

if (-not $pythonExe) {
    Write-Host "[ERREUR] Python introuvable." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $venvPython)) {
    Write-Host "[ERREUR] Environnement virtuel non trouve. Executez d'abord: .\install-and-start.ps1" -ForegroundColor Red
    exit 1
}

# Determiner le gestionnaire de paquets
$packageManager = $null
if (Get-Command "pnpm" -ErrorAction SilentlyContinue) {
    $packageManager = "pnpm"
} elseif (Get-Command "yarn" -ErrorAction SilentlyContinue) {
    $packageManager = "yarn"
} else {
    $packageManager = "npm"
}

# Preparer les scripts
$backendScript = @"
cd `"$Root\backend`"
`"$venvPython`" -m uvicorn server:app --host 0.0.0.0 --port 8001 --reload
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

# Creer les fichiers temporaires
$backendScriptPath = "$env:TEMP\halimou-backend-$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$frontendScriptPath = "$env:TEMP\halimou-frontend-$(Get-Date -Format 'yyyyMMddHHmmss').ps1"

$backendScript | Out-File -FilePath $backendScriptPath -Encoding UTF8
$frontendScript | Out-File -FilePath $frontendScriptPath -Encoding UTF8

Write-Host "[*] Demarrage du backend dans une nouvelle fenetre..." -ForegroundColor Yellow
$backendProcess = Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$backendScriptPath`"" -WindowStyle Normal -PassThru

Start-Sleep -Seconds 2

Write-Host "[*] Demarrage du frontend dans une nouvelle fenetre..." -ForegroundColor Yellow
$frontendProcess = Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$frontendScriptPath`"" -WindowStyle Normal -PassThru

Write-Host ""
Write-Host "[OK] Application demarree!" -ForegroundColor Green
Write-Host ""
Write-Host "[*] URLs:" -ForegroundColor Cyan
Write-Host "  - API Backend: http://localhost:8001" -ForegroundColor White
Write-Host "  - Frontend Web: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "[*] Les services tournent dans des fenetres PowerShell separees." -ForegroundColor Yellow
Write-Host "[*] Pour arreter, fermez les fenetres ou appuyez sur Ctrl+C dans chaque fenetre." -ForegroundColor Yellow
Write-Host ""
Write-Host "Appuyez sur une touche pour nettoyer les fichiers temporaires et quitter..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Nettoyer les fichiers temporaires
Remove-Item $backendScriptPath -ErrorAction SilentlyContinue
Remove-Item $frontendScriptPath -ErrorAction SilentlyContinue

