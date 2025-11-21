#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s || echo unknown)"

echo "[Halimou] OS détecté: $OS"
echo "[Halimou] Dossier projet: $ROOT_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[Halimou] Outil manquant: $1"
    return 1
  fi
}

maybe_install_on_unix() {
  local pkg="$1"
  if command -v brew >/dev/null 2>&1; then
    echo "[Halimou] Tentative d'installation via brew: $pkg"
    brew install "$pkg" || true
  elif command -v apt-get >/dev/null 2>&1; then
    echo "[Halimou] Tentative d'installation via apt-get: $pkg"
    sudo apt-get update -y || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" || true
  else
    echo "[Halimou] Gestionnaire de paquets introuvable. Veuillez installer $pkg manuellement."
  fi
}

echo "[Halimou] Vérification des dépendances système (python3, pip, node, npm/yarn/pnpm)"
require_cmd python3 || maybe_install_on_unix python
require_cmd pip3 || maybe_install_on_unix python3-pip
require_cmd node || maybe_install_on_unix node

if ! command -v npm >/dev/null 2>&1 && ! command -v yarn >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
  echo "[Halimou] Aucun gestionnaire JS (npm/yarn/pnpm) détecté. Installation npm via paquet node recommandée."
fi

echo "[Halimou] Installation backend..."
cd "${ROOT_DIR}/backend"
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

if [ -f ".env" ]; then
  set -a
  source .env
  set +a
fi
export MONGO_URL="${MONGO_URL:-mongodb://localhost:27017}"
export DB_NAME="${DB_NAME:-halimou}"

echo "[Halimou] Initialisation des index MongoDB..."
python init_db.py || true
deactivate || true

echo "[Halimou] Installation frontend..."
cd "${ROOT_DIR}/frontend"
if command -v pnpm >/dev/null 2>&1; then
  pnpm install
elif command -v yarn >/dev/null 2>&1; then
  yarn install
else
  npm install
fi

echo "[Halimou] Lancement de l'application (backend + frontend)..."
cd "${ROOT_DIR}"
exec zsh ./start-dev.sh


