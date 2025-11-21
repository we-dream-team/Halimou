#!/usr/bin/env bash
# Script de desinstallation des prerequis pour Halimou (macOS/Linux)
# Usage: bash uninstall-prerequisites.sh

set -euo pipefail

OS="$(uname -s || echo unknown)"
echo "[Halimou] Desinstallation des prerequis sur $OS"
echo "=============================================="
echo ""

# Fonction pour verifier si une commande existe
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Fonction pour desinstaller sur macOS
uninstall_macos() {
  echo "[*] Desinstallation sur macOS..."
  
  if command_exists brew; then
    echo "[*] Utilisation de Homebrew pour la desinstallation..."
    
    # Git
    if command_exists git; then
      echo "[*] Desinstallation de Git..."
      brew uninstall git --ignore-dependencies || true
    fi
    
    # Node.js
    if command_exists node; then
      echo "[*] Desinstallation de Node.js..."
      brew uninstall node --ignore-dependencies || true
    fi
    
    # Python
    if command_exists python3; then
      echo "[*] Desinstallation de Python..."
      brew uninstall python@3.11 python@3.12 python3 --ignore-dependencies || true
    fi
    
    # jq
    if command_exists jq; then
      echo "[*] Desinstallation de jq..."
      brew uninstall jq --ignore-dependencies || true
    fi
    
    # MongoDB
    if command_exists mongod; then
      echo "[*] Arret et desinstallation de MongoDB..."
      brew services stop mongodb-community || true
      brew uninstall mongodb-community --ignore-dependencies || true
    fi
    
    # pnpm
    if command_exists pnpm; then
      echo "[*] Desinstallation de pnpm..."
      npm uninstall -g pnpm || true
    fi
    
    echo "[OK] Desinstallation terminee"
  else
    echo "[!] Homebrew n'est pas installe. Desinstallez manuellement:"
    echo "   - Git: depuis le site officiel"
    echo "   - Node.js: depuis le site officiel"
    echo "   - Python: depuis le site officiel"
    echo "   - MongoDB: depuis le site officiel"
  fi
}

# Fonction pour desinstaller sur Linux
uninstall_linux() {
  echo "[*] Desinstallation sur Linux..."
  
  # Verifier si on est root ou sudo
  if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "[!] Ce script necessite des privileges sudo. Veuillez executer:"
    echo "   sudo bash uninstall-prerequisites.sh"
    exit 1
  fi
  
  SUDO=""
  if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
  fi
  
  # Git
  if command_exists git; then
    echo "[*] Desinstallation de Git..."
    $SUDO apt-get remove --purge -y git || true
    $SUDO apt-get autoremove -y || true
  fi
  
  # Node.js
  if command_exists node; then
    echo "[*] Desinstallation de Node.js..."
    $SUDO apt-get remove --purge -y nodejs npm || true
    $SUDO apt-get autoremove -y || true
  fi
  
  # Python
  if command_exists python3; then
    echo "[!] Python est souvent necessaire pour le systeme."
    echo "    Voulez-vous vraiment le desinstaller? (o/N)"
    read -r response
    if [ "$response" = "o" ] || [ "$response" = "O" ]; then
      echo "[*] Desinstallation de Python..."
      $SUDO apt-get remove --purge -y python3 python3-pip python3-venv || true
      $SUDO apt-get autoremove -y || true
    fi
  fi
  
  # jq
  if command_exists jq; then
    echo "[*] Desinstallation de jq..."
    $SUDO apt-get remove --purge -y jq || true
  fi
  
  # MongoDB
  if command_exists mongod; then
    echo "[*] Arret et desinstallation de MongoDB..."
    $SUDO systemctl stop mongod || true
    $SUDO systemctl disable mongod || true
    $SUDO apt-get remove --purge -y mongodb-org mongodb-org-* || true
    $SUDO apt-get autoremove -y || true
    $SUDO rm -rf /var/lib/mongodb || true
    $SUDO rm -rf /var/log/mongodb || true
  fi
  
  # pnpm
  if command_exists pnpm; then
    echo "[*] Desinstallation de pnpm..."
    npm uninstall -g pnpm || true
  fi
  
  echo "[OK] Desinstallation terminee"
}

# Desinstallation selon l'OS
case "$OS" in
  Darwin)
    uninstall_macos
    ;;
  Linux)
    uninstall_linux
    ;;
  *)
    echo "[ERREUR] Systeme d'exploitation non supporte: $OS"
    echo "Desinstallez manuellement les outils installes."
    exit 1
    ;;
esac

echo ""
echo "[OK] Desinstallation terminee!"
echo ""
echo "[*] Pour verifier, fermez et rouvrez votre terminal, puis:"
echo "   git --version"
echo "   node --version"
echo "   python3 --version"
echo "   jq --version"
echo ""

