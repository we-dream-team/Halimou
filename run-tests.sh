#!/bin/bash
# Script pour exécuter les tests

echo "🧪 Exécution des tests pour Halimou"
echo "=================================="
echo ""

# Vérifier que MongoDB est en cours d'exécution
if ! pgrep -x "mongod" > /dev/null; then
    echo "⚠️  MongoDB ne semble pas être en cours d'exécution"
    echo "   Assurez-vous que MongoDB est démarré avant de lancer les tests"
    echo ""
fi

# Aller dans le dossier backend
cd "$(dirname "$0")/backend" || exit 1

# Activer l'environnement virtuel si il existe
if [ -d ".venv" ]; then
    echo "📦 Activation de l'environnement virtuel..."
    source .venv/bin/activate
fi

# Installer les dépendances si nécessaire
echo "📦 Vérification des dépendances..."
pip install -q pytest pytest-asyncio httpx

# Exécuter les tests
echo ""
echo "🚀 Lancement des tests..."
echo ""

# Options par défaut
PYTEST_OPTS="-v"

# Vérifier les arguments
if [ "$1" == "--coverage" ] || [ "$1" == "-c" ]; then
    pip install -q pytest-cov
    PYTEST_OPTS="$PYTEST_OPTS --cov=server --cov-report=html --cov-report=term"
    echo "📊 Mode couverture activé"
elif [ "$1" == "--verbose" ] || [ "$1" == "-v" ]; then
    PYTEST_OPTS="$PYTEST_OPTS -s"
    echo "🔍 Mode verbose activé"
fi

# Exécuter pytest
pytest ../tests/ $PYTEST_OPTS

# Afficher le rapport de couverture si activé
if [ "$1" == "--coverage" ] || [ "$1" == "-c" ]; then
    echo ""
    echo "📊 Rapport de couverture généré dans: backend/htmlcov/index.html"
fi

echo ""
echo "✅ Tests terminés"

