#!/usr/bin/env bash
# Script d'installation automatique des prérequis pour Halimou
# Usage: 
#   En ligne: bash <(curl -sSL https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.sh)
#   Local: bash install-prerequisites.sh
# 
# Ce script installe les prérequis et propose automatiquement de cloner le projet
# et démarrer l'application.

set -euo pipefail

echo "🚀 Installation des prérequis pour Halimou"
echo "=========================================="
echo ""

OS="$(uname -s || echo unknown)"
ARCH="$(uname -m || echo unknown)"

echo "📋 Système détecté: $OS ($ARCH)"
echo ""

# Fonction pour vérifier si une commande existe
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Fonction pour installer sur macOS avec Homebrew
install_macos() {
  echo "🍎 Installation sur macOS..."
  
  # Installer Homebrew si nécessaire
  if ! command_exists brew; then
    echo "📦 Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Ajouter Homebrew au PATH pour Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  
  echo "📦 Mise à jour de Homebrew..."
  brew update
  
  # Installer Git
  if ! command_exists git; then
    echo "📦 Installation de Git..."
    brew install git
  else
    echo "✅ Git déjà installé: $(git --version)"
  fi
  
  # Installer Node.js
  if ! command_exists node; then
    echo "📦 Installation de Node.js..."
    brew install node
  else
    echo "✅ Node.js déjà installé: $(node --version)"
  fi
  
  # Installer Python
  if ! command_exists python3; then
    echo "📦 Installation de Python..."
    brew install python@3.11
  else
    echo "✅ Python déjà installé: $(python3 --version)"
  fi
  
  # Installer jq
  if ! command_exists jq; then
    echo "📦 Installation de jq..."
    brew install jq
  else
    echo "✅ jq déjà installé: $(jq --version)"
  fi
  
  # Installer MongoDB
  if ! command_exists mongod; then
    echo "📦 Installation de MongoDB..."
    brew tap mongodb/brew
    brew install mongodb-community
    echo "⚠️  MongoDB installé. Pour démarrer MongoDB:"
    echo "   brew services start mongodb-community"
  else
    echo "✅ MongoDB déjà installé: $(mongod --version | head -n1)"
  fi
  
  # Installer pnpm (recommandé)
  if ! command_exists pnpm; then
    echo "📦 Installation de pnpm..."
    npm install -g pnpm
  else
    echo "✅ pnpm déjà installé: $(pnpm --version)"
  fi
}

# Fonction pour installer sur Linux (Ubuntu/Debian)
install_linux() {
  echo "🐧 Installation sur Linux (Ubuntu/Debian)..."
  
  # Vérifier si on est root ou sudo
  if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "⚠️  Ce script nécessite des privilèges sudo. Veuillez exécuter:"
    echo "   sudo bash install-prerequisites.sh"
    exit 1
  fi
  
  SUDO=""
  if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
  fi
  
  echo "📦 Mise à jour des paquets..."
  $SUDO apt-get update -y
  
  # Installer Git
  if ! command_exists git; then
    echo "📦 Installation de Git..."
    $SUDO apt-get install -y git
  else
    echo "✅ Git déjà installé: $(git --version)"
  fi
  
  # Installer Node.js (via NodeSource)
  if ! command_exists node; then
    echo "📦 Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO bash -
    $SUDO apt-get install -y nodejs
  else
    echo "✅ Node.js déjà installé: $(node --version)"
  fi
  
  # Installer Python
  if ! command_exists python3; then
    echo "📦 Installation de Python..."
    $SUDO apt-get install -y python3 python3-pip python3-venv
  else
    echo "✅ Python déjà installé: $(python3 --version)"
  fi
  
  # Installer jq
  if ! command_exists jq; then
    echo "📦 Installation de jq..."
    $SUDO apt-get install -y jq
  else
    echo "✅ jq déjà installé: $(jq --version)"
  fi
  
  # Installer MongoDB (optionnel - peut utiliser MongoDB Atlas)
  if ! command_exists mongod; then
    echo "📦 Installation de MongoDB..."
    # Détecter la distribution
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      DISTRO=$ID
      VERSION_CODENAME=$VERSION_CODENAME
    else
      DISTRO="ubuntu"
      VERSION_CODENAME="jammy"
    fi
    
    # Installer MongoDB selon la distribution
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
      curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | $SUDO gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/$DISTRO ${VERSION_CODENAME:-jammy}/mongodb-org/7.0 multiverse" | $SUDO tee /etc/apt/sources.list.d/mongodb-org-7.0.list
      $SUDO apt-get update -y
      $SUDO apt-get install -y mongodb-org || {
        echo "⚠️  Installation MongoDB échouée. Vous pouvez:"
        echo "   1. Installer manuellement: https://www.mongodb.com/docs/manual/installation/"
        echo "   2. Utiliser MongoDB Atlas (cloud gratuit): https://www.mongodb.com/cloud/atlas"
      }
      if command_exists mongod; then
        echo "⚠️  MongoDB installé. Pour démarrer MongoDB:"
        echo "   sudo systemctl start mongod"
        echo "   sudo systemctl enable mongod"
      fi
    else
      echo "⚠️  Distribution non supportée pour l'installation automatique de MongoDB."
      echo "   Installez manuellement: https://www.mongodb.com/docs/manual/installation/"
      echo "   Ou utilisez MongoDB Atlas (cloud gratuit): https://www.mongodb.com/cloud/atlas"
    fi
  else
    echo "✅ MongoDB déjà installé: $(mongod --version | head -n1)"
  fi
  
  # Installer pnpm
  if ! command_exists pnpm; then
    echo "📦 Installation de pnpm..."
    npm install -g pnpm
  else
    echo "✅ pnpm déjà installé: $(pnpm --version)"
  fi
}

# Installation selon l'OS
case "$OS" in
  Darwin)
    install_macos
    ;;
  Linux)
    install_linux
    ;;
  *)
    echo "❌ Système d'exploitation non supporté: $OS"
    echo "Veuillez installer manuellement:"
    echo "  - Git: https://git-scm.com/downloads"
    echo "  - Node.js 18+: https://nodejs.org/"
    echo "  - Python 3.10+: https://www.python.org/downloads/"
    echo "  - MongoDB: https://www.mongodb.com/try/download/community"
    exit 1
    ;;
esac

echo ""
echo "✅ Installation terminée!"
echo ""

# Vérifier les prérequis essentiels
ESSENTIAL_INSTALLED=true
if ! command_exists git; then
  echo "❌ Git: Non installé"
  ESSENTIAL_INSTALLED=false
else
  echo "✅ Git: $(git --version)"
fi

if ! command_exists node; then
  echo "❌ Node.js: Non installé"
  ESSENTIAL_INSTALLED=false
else
  echo "✅ Node.js: $(node --version)"
fi

if ! command_exists python3; then
  echo "❌ Python: Non installé"
  ESSENTIAL_INSTALLED=false
else
  echo "✅ Python: $(python3 --version)"
fi

if command_exists jq; then
  echo "✅ jq: $(jq --version)"
else
  echo "⚠️  jq: Non installé (optionnel)"
fi

if command_exists pnpm; then
  echo "✅ pnpm: $(pnpm --version)"
else
  echo "⚠️  pnpm: Non installé (optionnel, npm peut être utilisé)"
fi

if command_exists mongod; then
  echo "✅ MongoDB: $(mongod --version 2>/dev/null | head -n1)"
else
  echo "⚠️  MongoDB: Non installé (optionnel, peut utiliser MongoDB Atlas)"
fi

echo ""

# Proposer de cloner et démarrer automatiquement
if [ "$ESSENTIAL_INSTALLED" = true ]; then
  echo "🚀 Voulez-vous que je clone le projet et démarre l'application maintenant?"
  echo "   (Le script va cloner le repo, installer les dépendances et démarrer l'app)"
  read -p "Continuer? (o/N) " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Oo]$ ]]; then
    echo ""
    echo "📦 Clonage du projet..."
    
    # Déterminer le dossier de destination
    CURRENT_DIR=$(pwd)
    PROJECT_DIR="$CURRENT_DIR/Halimou"
    
    # Vérifier si le dossier existe déjà
    if [ -d "$PROJECT_DIR" ]; then
      echo "⚠️  Le dossier Halimou existe déjà."
      read -p "Voulez-vous le supprimer et re-cloner? (o/N) " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Oo]$ ]]; then
        rm -rf "$PROJECT_DIR"
        echo "✅ Dossier supprimé"
      else
        echo "📁 Utilisation du dossier existant"
      fi
    fi
    
    # Cloner le projet si le dossier n'existe pas
    if [ ! -d "$PROJECT_DIR" ]; then
      if git clone https://github.com/we-dream-team/Halimou.git "$PROJECT_DIR"; then
        echo "✅ Projet cloné avec succès"
      else
        echo "❌ Impossible de cloner le projet"
        echo "   Clonez manuellement: git clone https://github.com/we-dream-team/Halimou.git"
        exit 1
      fi
    fi
    
    # Aller dans le dossier du projet
    cd "$PROJECT_DIR"
    
    echo ""
    echo "🚀 Installation et démarrage de l'application..."
    echo ""
    
    # Lancer le script d'installation et démarrage
    if [ -f "./install-and-start.sh" ]; then
      bash ./install-and-start.sh
    else
      echo "❌ Script install-and-start.sh introuvable dans le projet cloné."
      echo "   Lancez manuellement: cd Halimou puis bash install-and-start.sh"
    fi
  else
    echo ""
    echo "📝 Pour cloner et démarrer manuellement:"
    echo "   git clone https://github.com/we-dream-team/Halimou.git"
    echo "   cd Halimou"
    echo "   bash install-and-start.sh"
    echo ""
  fi
else
  echo ""
  echo "⚠️  Certains prérequis essentiels ne sont pas installés."
  echo "   Installez-les d'abord, puis relancez ce script pour cloner et démarrer l'application."
  echo ""
fi

