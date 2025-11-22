# Tests pour Halimou

Cette suite de tests couvre tous les scénarios de l'application Halimou.

## Structure des tests

```
tests/
├── conftest.py              # Configuration et fixtures pytest
├── test_products.py         # Tests pour les produits
├── test_inventories.py      # Tests pour les inventaires
├── test_statistics.py       # Tests pour les statistiques
├── test_employees.py        # Tests pour les employés et paie
├── test_validation.py        # Tests de validation et erreurs
└── README.md               # Ce fichier
```

## Installation

```bash
cd backend
pip install -r requirements.txt
```

Les dépendances de test (pytest, etc.) sont déjà incluses dans `requirements.txt`.

## Exécution des tests

### Tous les tests
```bash
pytest tests/ -v
```

### Tests spécifiques
```bash
# Tests pour les produits uniquement
pytest tests/test_products.py -v

# Tests pour les inventaires uniquement
pytest tests/test_inventories.py -v

# Un test spécifique
pytest tests/test_products.py::TestProducts::test_create_product -v
```

### Avec couverture de code
```bash
pytest tests/ --cov=server --cov-report=html
```

### Mode verbose avec sortie détaillée
```bash
pytest tests/ -v -s
```

## Configuration

Les tests utilisent une base de données de test séparée (`halimou_test`) pour éviter d'affecter les données de production.

Assurez-vous que MongoDB est en cours d'exécution avant de lancer les tests.

## Scénarios de test couverts

### Produits (15 tests)
- ✅ Création de produit avec validation
- ✅ Récupération de tous les produits
- ✅ Récupération d'un produit par ID
- ✅ Mise à jour complète et partielle
- ✅ Suppression de produit
- ✅ Filtrage des produits archivés
- ✅ Validation des données (champs manquants, types invalides)
- ✅ Gestion des erreurs 404

### Inventaires (12 tests)
- ✅ Création d'inventaire avec calcul automatique du revenu
- ✅ Récupération d'inventaires (triés par date)
- ✅ Récupération par date
- ✅ Mise à jour d'inventaire avec recalcul
- ✅ Suppression d'inventaire
- ✅ Prévention des doublons (même date)
- ✅ Validation : liste vide, produit invalide, prix négatif
- ✅ Calcul du revenu avec plusieurs produits

### Statistiques (7 tests)
- ✅ Résumé des statistiques globales
- ✅ Statistiques avec plage de dates
- ✅ Statistiques sans données (cas vide)
- ✅ Statistiques par produit
- ✅ Statistiques produit avec plage de dates
- ✅ Performance des produits (comparaison)
- ✅ Calculs de moyennes quotidiennes

### Employés et Paie (10 tests)
- ✅ CRUD complet pour les employés
- ✅ CRUD complet pour les fiches de paie
- ✅ Filtrage par employé
- ✅ Filtrage par période
- ✅ Gestion des employés actifs/inactifs
- ✅ Validation des données

### Validation et Erreurs (14 tests)
- ✅ Validation des champs requis
- ✅ Validation des types de données
- ✅ Validation des formats (dates, etc.)
- ✅ Gestion des erreurs 404 (produits, inventaires, employés)
- ✅ Gestion des erreurs 400 (doublons, champs vides)
- ✅ Messages d'erreur appropriés
- ✅ Health check endpoint

## Fixtures disponibles

Les fixtures dans `conftest.py` fournissent :
- `test_db`: Connexion à la base de données de test
- `clean_db`: Base de données nettoyée avant chaque test
- `test_client`: Client FastAPI pour les tests
- `sample_product_data`: Données d'exemple pour un produit
- `sample_inventory_data`: Données d'exemple pour un inventaire
- `sample_employee_data`: Données d'exemple pour un employé
- `sample_payroll_data`: Données d'exemple pour une fiche de paie

## Notes importantes

1. **Base de données de test**: Les tests utilisent `halimou_test` comme nom de base de données. Cette base est automatiquement nettoyée après chaque test.

2. **Isolation**: Chaque test est isolé et ne dépend pas des autres.

3. **Fixtures**: Utilisez les fixtures fournies pour créer des données de test cohérentes.

4. **Nettoyage**: La base de données de test est automatiquement nettoyée avant chaque test grâce à la fixture `clean_db`.

## Ajout de nouveaux tests

Pour ajouter de nouveaux tests :

1. Créez un nouveau fichier `test_*.py` dans le dossier `tests/`
2. Importez les fixtures nécessaires depuis `conftest.py`
3. Créez des classes de test avec des méthodes `test_*`
4. Utilisez `pytest` pour exécuter vos nouveaux tests

Exemple :
```python
import pytest

class TestNewFeature:
    def test_new_feature(self, test_client, clean_db):
        response = test_client.get("/api/new-endpoint")
        assert response.status_code == 200
```

