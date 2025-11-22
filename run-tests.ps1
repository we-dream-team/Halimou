# Script PowerShell pour exécuter les tests

Write-Host "🧪 Exécution des tests pour Halimou" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que MongoDB est en cours d'exécution
$mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
if (-not $mongoProcess) {
    Write-Host "⚠️  MongoDB ne semble pas être en cours d'exécution" -ForegroundColor Yellow
    Write-Host "   Assurez-vous que MongoDB est démarré avant de lancer les tests" -ForegroundColor Yellow
    Write-Host ""
}

# Aller dans le dossier backend
$backendPath = Join-Path $PSScriptRoot "backend"
if (-not (Test-Path $backendPath)) {
    Write-Host "❌ Dossier backend introuvable" -ForegroundColor Red
    exit 1
}

Set-Location $backendPath

# Activer l'environnement virtuel si il existe
if (Test-Path ".venv\Scripts\Activate.ps1") {
    Write-Host "📦 Activation de l'environnement virtuel..." -ForegroundColor Gray
    & .venv\Scripts\Activate.ps1
}

# Installer les dépendances si nécessaire
Write-Host "📦 Vérification des dépendances..." -ForegroundColor Gray
pip install -q pytest pytest-asyncio httpx 2>&1 | Out-Null

# Options par défaut
$pytestOpts = "-v"

# Vérifier les arguments
if ($args[0] -eq "--coverage" -or $args[0] -eq "-c") {
    pip install -q pytest-cov 2>&1 | Out-Null
    $pytestOpts = "$pytestOpts --cov=server --cov-report=html --cov-report=term"
    Write-Host "📊 Mode couverture activé" -ForegroundColor Cyan
} elseif ($args[0] -eq "--verbose" -or $args[0] -eq "-v") {
    $pytestOpts = "$pytestOpts -s"
    Write-Host "🔍 Mode verbose activé" -ForegroundColor Cyan
}

# Exécuter pytest
Write-Host ""
Write-Host "🚀 Lancement des tests..." -ForegroundColor Green
Write-Host ""

$testsPath = Join-Path $PSScriptRoot "tests"
pytest $testsPath $pytestOpts.Split(" ")

# Afficher le rapport de couverture si activé
if ($args[0] -eq "--coverage" -or $args[0] -eq "-c") {
    Write-Host ""
    Write-Host "📊 Rapport de couverture généré dans: backend\htmlcov\index.html" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ Tests terminés" -ForegroundColor Green

