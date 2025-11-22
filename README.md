# Halimou — Gestion d’inventaire pour pâtisserie

Application complète (backend FastAPI + frontend Next.js ) pour gérer l’inventaire quotidien d’une pâtisserie : produits, inventaires journaliers, chiffres d’affaires et statistiques.

## Aperçu
- Backend: FastAPI + MongoDB (Motor) avec endpoints produits, inventaires et statistiques
- Frontend Web: Next.js + Tailwind CSS

## Structure du projet
```
backend/             # API FastAPI + scripts d'init BDD
frontend/            # Application web Next.js (Tailwind CSS)
tests/               # Suite de tests pytest complète
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

**Windows (PowerShell - Windows 10 Pro / Windows 11):**

**Option A: Téléchargement automatique (nécessite une connexion internet)**
```powershell
PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
```

**Option B: Téléchargement manuel (si erreur de connexion)**
Si vous obtenez l'erreur **"Le nom distant n'a pas pu être résolu"**, consultez le guide détaillé:
- **[INSTALLATION_MANUELLE_WINDOWS.md](INSTALLATION_MANUELLE_WINDOWS.md)** - Guide complet avec captures d'écran

**Résumé rapide:**
1. Téléchargez le fichier `install-prerequisites.ps1` depuis: https://github.com/we-dream-team/Halimou/blob/main/install-prerequisites.ps1
2. Clic droit sur le fichier > "Raw" > Enregistrer sous (avec extension `.ps1`)
3. Ouvrez PowerShell en tant qu'administrateur
4. Naviguez vers le dossier: `cd "C:\chemin\vers\le\dossier"`
5. Exécutez: `.\install-prerequisites.ps1`

**Option C: Cloner le repository (si Git est installé)**
```powershell
git clone https://github.com/we-dream-team/Halimou.git
cd Halimou
.\install-prerequisites.ps1
```

**macOS/Linux:**
- `bash install-prerequisites.sh`

**Note Windows 10 Pro:**
- Le script détecte automatiquement si `winget` est disponible
- Si `winget` n'est pas installé, le script utilisera automatiquement Chocolatey
- Aucune action manuelle requise - le script s'adapte à votre système

**Pour désinstaller les prérequis (tests):**
- Windows: `.\uninstall-prerequisites.ps1` (en tant qu'administrateur)
- macOS/Linux: `bash uninstall-prerequisites.sh`

Ces scripts installent automatiquement:
- ✅ Git
- ✅ Node.js (LTS)
- ⚠️ **Python 3.10+** (installation manuelle recommandée sur Windows)
- ✅ jq (outil de traitement JSON)
- ✅ MongoDB (optionnel, peut utiliser MongoDB Atlas)
- ✅ pnpm (gestionnaire de paquets Node.js)

**✨ Fonctionnalité automatique :** Après l'installation des prérequis, les scripts proposent automatiquement de :
1. Cloner le projet depuis GitHub
2. Installer les dépendances (backend + frontend)
3. Démarrer l'application (backend + frontend)

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

### 🚀 Installation automatique complète (recommandé)

Les scripts `install-prerequisites.sh` (macOS/Linux) et `install-prerequisites.ps1` (Windows) font tout automatiquement :
1. Installent les prérequis
2. Clonent le projet
3. Installent les dépendances
4. Démarrant l'application

**macOS/Linux:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.sh)
```

**Windows:**
```powershell
PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
```

### Installation manuelle étape par étape

Si vous préférez installer manuellement :

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

### 📦 Gestion des Produits
- Création, édition, suppression et archivage de produits
- Catégorisation (viennoiserie, gâteau, autre)
- Produits récurrents (apparaissent automatiquement dans les inventaires)

### 📊 Inventaire Quotidien
- Saisie des quantités : produites, vendues, jetées
- Calcul automatique des quantités restantes
- Réintégration des invendus de la veille
- Sauvegarde automatique après 800ms d'inactivité
- Résumé du jour avec chiffre d'affaires

### 📈 Statistiques
- Vue d'ensemble : ventes totales, gaspillage, revenu
- Performance par produit : moyennes quotidiennes, taux de vente, gaspillage
- Filtrage par période : semaine, 7 jours, 30 jours, tout
- Export des données en JSON

### 👥 Gestion de la Paie
- Gestion des employés : création, modification, suppression
- Fiches de paie par période (mois)
- Suivi des avances sur salaire
- Calcul automatique du reste à payer

## API Endpoints

Base URL: `http://<HOST>:8001/api`

### Produits
- `POST /products` — Créer un produit
- `GET /products?include_archived=true` — Lister tous les produits (avec archivés)
- `GET /products/{id}` — Récupérer un produit par ID
- `PUT /products/{id}` — Mettre à jour un produit
- `DELETE /products/{id}` — Supprimer un produit

### Inventaires
- `POST /inventories` — Créer l'inventaire du jour (unique par date)
- `GET /inventories?limit=N` — Lister les inventaires récents (triés par date décroissante)
- `GET /inventories/{date}` — Récupérer un inventaire par date (format: YYYY-MM-DD)
- `PUT /inventories/{date}` — Mettre à jour les produits de l'inventaire
- `DELETE /inventories/{date}` — Supprimer un inventaire

### Statistiques
- `GET /stats/summary?start_date=&end_date=` — Résumé global avec agrégats
- `GET /stats/product/{product_id}?start_date=&end_date=` — Statistiques détaillées par produit
- `GET /export?start_date=&end_date=` — Export JSON complet (inventaires + produits)

### Employés et Paie
- `POST /employees` — Créer un employé
- `GET /employees?include_inactive=true` — Lister les employés
- `PUT /employees/{id}` — Mettre à jour un employé
- `DELETE /employees/{id}` — Supprimer un employé
- `POST /payrolls` — Créer une fiche de paie
- `GET /payrolls?employee_id=&period=` — Lister les fiches de paie (avec filtres)
- `PUT /payrolls/{id}` — Mettre à jour une fiche de paie
- `DELETE /payrolls/{id}` — Supprimer une fiche de paie

### Health Check
- `GET /` — Vérifier l'état du service

## Notes d'implémentation

### Backend
- **Framework**: FastAPI avec support async
- **Base de données**: MongoDB avec Motor (driver async)
- **Validation**: Pydantic v2 pour la validation des données
- **CORS**: Configuré pour permettre les requêtes depuis le frontend
- **Index MongoDB**: Optimisés pour les requêtes fréquentes (date, is_archived)

### Frontend
- **Framework**: Next.js 16 avec React
- **Styling**: Tailwind CSS avec design responsive
- **API Client**: Axios configuré dans `frontend/lib/api.ts`
- **Navigation**: Menu responsive avec hamburger sur mobile
- **Redirection**: Page d'accueil redirige vers `/inventaire`

### Tests
- **Framework**: pytest avec pytest-asyncio
- **Client de test**: httpx.AsyncClient pour les tests d'intégration
- **Couverture**: 54+ scénarios de test couvrant tous les endpoints
- **Base de données de test**: Isolation complète avec `halimou_test`

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

## 🔧 Dépannage

### Windows 10 Pro / Windows 11
Si vous rencontrez des problèmes lors de l'installation sur Windows, consultez les guides détaillés :
- **[INSTALLATION_MANUELLE_WINDOWS.md](INSTALLATION_MANUELLE_WINDOWS.md)** - Si vous avez des problèmes de connexion réseau
- **[TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)** - Guide de dépannage complet

**Problèmes courants:**
- **"Le nom distant n'a pas pu être résolu":** Problème de connexion DNS/internet. Utilisez l'Option B (téléchargement manuel) ci-dessus
- **winget non disponible (Windows 10 Pro):** Le script utilisera automatiquement Chocolatey
- **Python introuvable:** Installez Python manuellement et cochez "Add Python to PATH"
- **Commandes non reconnues:** Fermez et rouvrez PowerShell après l'installation

### macOS / Linux
- Assurez-vous d'avoir les permissions d'installation (sudo peut être requis)
- Vérifiez que Homebrew est installé sur macOS
- Sur Linux, utilisez `apt-get` (Debian/Ubuntu) ou le gestionnaire de paquets de votre distribution

## 🧪 Tests

L'application dispose d'une suite de tests complète avec pytest.

### Exécution des tests

**macOS/Linux:**
```bash
./run-tests.sh
```

**Windows:**
```powershell
.\run-tests.ps1
```

**Avec couverture de code:**
```bash
./run-tests.sh --coverage
# ou
pytest tests/ --cov=server --cov-report=html
```

### Documentation des tests

- **[tests/README.md](tests/README.md)** - Guide complet des tests
- **[TESTS_SCENARIOS.md](TESTS_SCENARIOS.md)** - Liste de tous les scénarios de test

### Scénarios couverts

- ✅ **Produits** : CRUD complet, validation, archivage
- ✅ **Inventaires** : CRéation, mise à jour, calcul automatique du revenu
- ✅ **Statistiques** : Résumés globaux et par produit, plages de dates
- ✅ **Employés et Paie** : Gestion complète des salariés et bulletins
- ✅ **Validation** : Tests de validation des données
- ✅ **Gestion d'erreurs** : Codes HTTP appropriés, messages d'erreur

## Licence
Projet interne/démo. Adapter selon vos besoins.
