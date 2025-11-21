#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "[Halimou] Démarrage depuis: $ROOT_DIR"

# Valeurs par défaut
export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://localhost:8001}"
BACKEND_PORT="${BACKEND_PORT:-8001}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"

echo "[Halimou] NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}"
echo "[Halimou] Backend port=${BACKEND_PORT}, Frontend port=${FRONTEND_PORT}"

# Lancer le backend (FastAPI + Uvicorn)
(
  cd "${ROOT_DIR}/backend"
  if [ -d ".venv" ]; then
    echo "[Halimou] Activation de l'environnement virtuel backend"
    source .venv/bin/activate
  fi
  # Charger .env si présent
  if [ -f ".env" ]; then
    set -a
    source .env
    set +a
  fi
  # Valeurs par défaut pour éviter les erreurs si non définies
  export MONGO_URL="${MONGO_URL:-mongodb://localhost:27017}"
  export DB_NAME="${DB_NAME:-halimou}"
  echo "[Halimou] Mongo: MONGO_URL=${MONGO_URL} DB_NAME=${DB_NAME}"
  echo "[Halimou] Lancement du backend..."
  uvicorn server:app --host 0.0.0.0 --port "${BACKEND_PORT}" --reload
) &
BACKEND_PID=$!

# Lancer le frontend (Next.js)
(
  cd "${ROOT_DIR}/frontend"
  echo "[Halimou] Installation (si nécessaire) et lancement du frontend..."
  if command -v pnpm >/dev/null 2>&1; then
    pnpm install --silent || true
    pnpm dev -p "${FRONTEND_PORT}"
  elif command -v yarn >/dev/null 2>&1; then
    yarn install --silent || true
    yarn dev -p "${FRONTEND_PORT}"
  else
    npm install --silent || true
    npm run dev -- -p "${FRONTEND_PORT}"
  fi
) &
FRONTEND_PID=$!

cleanup() {
  echo "\n[Halimou] Arrêt en cours..."
  kill "${BACKEND_PID}" >/dev/null 2>&1 || true
  kill "${FRONTEND_PID}" >/dev/null 2>&1 || true
  wait "${BACKEND_PID}" "${FRONTEND_PID}" 2>/dev/null || true
  echo "[Halimou] Arrêt terminé."
}

trap cleanup INT TERM

echo "[Halimou] Backend PID=${BACKEND_PID}, Frontend PID=${FRONTEND_PID}"
echo "[Halimou] URLs:"
echo "  - API: ${NEXT_PUBLIC_API_URL}"
echo "  - Web: http://localhost:${FRONTEND_PORT}"

wait "${BACKEND_PID}" "${FRONTEND_PID}"


