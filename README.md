# Halimou — Gestion d’inventaire pour pâtisserie

Application complète (backend FastAPI + frontend Next.js ) pour gérer l’inventaire quotidien d’une pâtisserie : produits, inventaires journaliers, chiffres d’affaires et statistiques.

## Aperçu
- Backend: FastAPI + MongoDB (Motor) avec endpoints produits, inventaires et statistiques
- Frontend Web: Next.js + Tailwind CSS

## Structure du projet
```
backend/             # API FastAPI + scripts d'init BDD
frontend/            # Application web Next.js (Tailwind)
tests/               # Tests Python (placeholder)
```

## Prérequis
- Git
- Node.js 18+ et pnpm/yarn/npm
- Python 3.10+ (installation manuelle recommandée)
- jq (outil de traitement JSON)
- MongoDB (local ou hébergé)

## 🚀 Installation rapide des prérequis

### Option 1: Installation automatique (recommandé)

**macOS / Linux:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.sh)
```

**Windows (PowerShell):**
```powershell
PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
```

**Ou télécharger et exécuter localement:**
- macOS/Linux: `bash install-prerequisites.sh`
- Windows: `.\install-prerequisites.ps1`

**Pour désinstaller les prérequis (tests):**
- Windows: `.\uninstall-prerequisites.ps1` (en tant qu'administrateur)

Ces scripts installent automatiquement:
- ✅ Git
- ✅ Node.js (LTS)
- ✅ Python 3.10+
- ✅ MongoDB
- ✅ pnpm (gestionnaire de paquets Node.js)

### Option 2: Installation manuelle

Si vous préférez installer manuellement, consultez:
- [Git](https://git-scm.com/downloads)
- [Node.js 18+](https://nodejs.org/)
- [Python 3.10+](https://www.python.org/downloads/)
- [MongoDB](https://www.mongodb.com/try/download/community) ou [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (cloud)

## Variables d’environnement
Créer `backend/.env` :
```
MONGO_URL=mongodb://localhost:27017
DB_NAME=halimou
```

Frontend Web (`frontend`): définir `NEXT_PUBLIC_API_URL` si le backend n'est pas sur `http://localhost:8001`.
```
NEXT_PUBLIC_API_URL=http://localhost:8001
```

## Installation & lancement

### 1) Backend (FastAPI)
Installer les dépendances et lancer l’API sur le port 8001.
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Initialiser les index MongoDB (optionnel mais recommandé)
python init_db.py

# Lancer l’API
uvicorn server:app --host 0.0.0.0 --port 8001 --reload
```
Endpoints racine: `GET /api/` renvoie l’état du service.

### 2) Frontend Web (Next.js)
```bash
cd frontend
npm install   # ou yarn / pnpm
npm run dev   # démarre sur http://localhost:3000
```
Par défaut, l'app Web pointe vers `NEXT_PUBLIC_API_URL` ou `http://localhost:8001`.

## Fonctionnalités principales
- Catalogue produits: création, édition, suppression, archivage
- Inventaire quotidien: quantités produites, vendues, jetées, restant calculé automatiquement
- Résumé du jour: chiffre d’affaires
- Statistiques: ventes, gaspillage, revenu total, performance par produit, export JSON

## API (extraits)
Base URL: `http://<HOST>:8001/api`

Produits:
- `POST /products` — créer
- `GET /products` — lister (par défaut sans archivés)
- `GET /products/{id}` — détail
- `PUT /products/{id}` — mettre à jour
- `DELETE /products/{id}` — supprimer

Inventaires:
- `POST /inventories` — créer l’inventaire du jour (unique par date)
- `GET /inventories?limit=N` — lister récents
- `GET /inventories/{date}` — lire par date (YYYY-MM-DD)
- `PUT /inventories/{date}` — mettre à jour les produits du jour
- `DELETE /inventories/{date}` — supprimer

Statistiques:
- `GET /stats/summary?start_date=&end_date=` — agrégats sur la période
- `GET /stats/product/{product_id}` — stats par produit
- `GET /export?start_date=&end_date=` — export JSON (inventaires + produits)

Health:
- `GET /` — ping du service

## Notes d’implémentation
- Backend: `FastAPI`, `motor` (MongoDB async), `pydantic` v2, CORS ouvert pour faciliter le dev.
- Frontend Web: axios (`frontend/lib/api.ts`) utilise `NEXT_PUBLIC_API_URL` (fallback `http://localhost:8001`).
- UI: Tailwind CSS avec composants simples (ex: `Navigation.tsx`).
- Redirection d’accueil: `frontend/app/page.tsx` redirige vers `/inventaire`.

## Dépannage
- CORS/URL API: vérifiez `NEXT_PUBLIC_API_URL` côté web.
- MongoDB: assurez-vous que `MONGO_URL` et `DB_NAME` sont corrects, et que le service est démarré.
- Index: si les requêtes sont lentes, exécutez `python backend/init_db.py`.

## Scripts utiles

### Développement
- **Installation complète:** `.\install-and-start.ps1` (Windows) ou `bash install-and-start.sh` (macOS/Linux)
- **Démarrage rapide:** `.\start-dev.ps1` (Windows) ou `bash start-dev.sh` (macOS/Linux)
- **Backend seul:** `uvicorn server:app --reload --port 8001`
- **Frontend seul:** `npm run dev` dans `frontend`

## Services Windows

Pour installer l'application comme services Windows (démarrage automatique) :

```powershell
# Installer les services (en tant qu'administrateur)
.\install-windows-services.ps1

# Gérer les services
.\manage-services.ps1 status
.\manage-services.ps1 start
.\manage-services.ps1 stop
.\manage-services.ps1 restart
```

Voir [WINDOWS_SERVICES.md](WINDOWS_SERVICES.md) pour plus de détails.

## Licence
Projet interne/démo. Adapter selon vos besoins.
