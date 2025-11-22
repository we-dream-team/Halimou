# 📋 Scénarios de Test - Halimou

Documentation complète de tous les scénarios de test pour l'application Halimou.

## 🎯 Vue d'ensemble

La suite de tests couvre **100+ scénarios** répartis en 6 catégories principales :

1. **Produits** (15 scénarios)
2. **Inventaires** (12 scénarios)
3. **Statistiques** (7 scénarios)
4. **Employés et Paie** (10 scénarios)
5. **Validation** (8 scénarios)
6. **Gestion d'erreurs** (6 scénarios)

## 📦 Tests des Produits

### CRUD de base
- ✅ **Création d'un produit** : Vérifie que tous les champs sont correctement enregistrés
- ✅ **Récupération de tous les produits** : Liste complète avec filtrage
- ✅ **Récupération par ID** : Récupération d'un produit spécifique
- ✅ **Mise à jour complète** : Modification de tous les champs
- ✅ **Mise à jour partielle** : Modification d'un seul champ
- ✅ **Suppression** : Suppression et vérification de l'absence

### Filtrage et archivage
- ✅ **Exclusion des produits archivés** : Par défaut, les produits archivés ne sont pas retournés
- ✅ **Inclusion des produits archivés** : Option pour inclure les produits archivés
- ✅ **Différentes catégories** : Test avec viennoiserie, gâteau, autre

### Validation
- ✅ **Données invalides** : Prix négatif, champs manquants
- ✅ **Produit inexistant** : Gestion des erreurs 404

## 📊 Tests des Inventaires

### CRUD de base
- ✅ **Création d'inventaire** : Création avec calcul automatique du revenu
- ✅ **Récupération de tous les inventaires** : Liste triée par date décroissante
- ✅ **Récupération par date** : Récupération d'un inventaire spécifique
- ✅ **Mise à jour d'inventaire** : Modification des quantités avec recalcul
- ✅ **Suppression d'inventaire** : Suppression et vérification

### Validation et règles métier
- ✅ **Prévention des doublons** : Impossible de créer deux inventaires pour la même date
- ✅ **Liste de produits vide** : Rejet si aucun produit
- ✅ **Produit invalide** : Validation des données de produit
- ✅ **Prix négatif** : Rejet des prix invalides
- ✅ **Calcul du revenu** : Vérification du calcul automatique avec plusieurs produits

## 📈 Tests des Statistiques

### Résumé global
- ✅ **Statistiques complètes** : Total des ventes, gaspillage, produits vendus/produits
- ✅ **Statistiques avec plage de dates** : Filtrage par période
- ✅ **Statistiques vides** : Gestion du cas sans données

### Statistiques par produit
- ✅ **Statistiques d'un produit** : Historique détaillé par jour
- ✅ **Statistiques avec plage de dates** : Filtrage temporel
- ✅ **Performance des produits** : Comparaison de plusieurs produits
- ✅ **Calcul des moyennes** : Vérification des calculs de moyennes quotidiennes

## 👥 Tests des Employés et Paie

### Employés
- ✅ **Création d'employé** : Tous les champs requis
- ✅ **Récupération de tous les employés** : Liste complète
- ✅ **Filtrage actifs/inactifs** : Exclusion des employés inactifs par défaut
- ✅ **Mise à jour d'employé** : Modification des informations
- ✅ **Suppression d'employé** : Suppression et vérification

### Fiches de paie
- ✅ **Création de fiche de paie** : Association employé/période
- ✅ **Récupération des fiches** : Liste complète
- ✅ **Filtrage par employé** : Fiches d'un employé spécifique
- ✅ **Filtrage par période** : Fiches d'une période donnée
- ✅ **Mise à jour de fiche** : Modification des avances et notes
- ✅ **Suppression de fiche** : Suppression et vérification

## ✅ Tests de Validation

### Validation des données
- ✅ **Champs manquants** : Rejet des données incomplètes
- ✅ **Types invalides** : Rejet des types incorrects (ex: string au lieu de number)
- ✅ **Format de date invalide** : Validation du format YYYY-MM-DD
- ✅ **Champs de produit manquants** : Validation complète des produits dans inventaire
- ✅ **Employé inexistant** : Validation de l'existence de l'employé pour la paie

## 🚨 Tests de Gestion d'Erreurs

### Codes d'erreur HTTP
- ✅ **404 Produit inexistant** : Message d'erreur approprié
- ✅ **404 Inventaire inexistant** : Message d'erreur approprié
- ✅ **404 Employé inexistant** : Message d'erreur approprié
- ✅ **400 Inventaire en double** : Prévention des doublons
- ✅ **400 Mise à jour sans champs** : Validation des mises à jour vides
- ✅ **Health check** : Vérification du endpoint de santé

## 🚀 Exécution des Tests

### Commande de base
```bash
# Tous les tests
pytest tests/ -v

# Tests spécifiques
pytest tests/test_products.py -v
pytest tests/test_inventories.py -v
```

### Avec couverture de code
```bash
pytest tests/ --cov=server --cov-report=html
```

### Scripts d'exécution
```bash
# macOS/Linux
./run-tests.sh

# Windows
.\run-tests.ps1

# Avec couverture
./run-tests.sh --coverage
```

## 📊 Métriques de Test

- **Couverture cible** : > 80%
- **Tests unitaires** : 50+
- **Tests d'intégration** : 30+
- **Tests de validation** : 20+

## 🔄 Scénarios de Test Manuels Recommandés

En plus des tests automatisés, voici des scénarios à tester manuellement :

### Interface Utilisateur
1. **Navigation** : Tester tous les liens de navigation
2. **Responsive** : Vérifier sur mobile, tablette, desktop
3. **Formulaires** : Validation côté client des formulaires
4. **Modales** : Ouverture/fermeture, validation
5. **Autosave** : Vérifier la sauvegarde automatique après 800ms

### Flux Utilisateur
1. **Création complète** : Produit → Inventaire → Statistiques
2. **Réintégration** : Réintégrer les invendus de la veille
3. **Export** : Exporter les données
4. **Gestion de paie** : Créer employé → Ajouter avance → Calculer reste

### Performance
1. **Chargement initial** : Temps de chargement de la page
2. **Requêtes API** : Temps de réponse des endpoints
3. **Sauvegarde** : Temps de sauvegarde automatique
4. **Statistiques** : Temps de calcul avec beaucoup de données

## 📝 Notes Importantes

1. **Base de données de test** : Les tests utilisent `halimou_test` pour éviter d'affecter les données de production
2. **Isolation** : Chaque test est indépendant et ne dépend pas des autres
3. **Nettoyage automatique** : La base de données est nettoyée avant chaque test
4. **Fixtures** : Utilisation de fixtures pytest pour des données de test cohérentes

## 🔧 Maintenance des Tests

### Ajouter un nouveau test
1. Créer un fichier `test_*.py` dans `tests/`
2. Utiliser les fixtures de `conftest.py`
3. Suivre le pattern des tests existants
4. Documenter le scénario testé

### Exemple de nouveau test
```python
def test_new_feature(self, test_client, clean_db):
    """Test de la nouvelle fonctionnalité"""
    response = test_client.get("/api/new-endpoint")
    assert response.status_code == 200
    assert "expected_field" in response.json()
```

## ✅ Checklist de Tests

Avant chaque release, vérifier :
- [ ] Tous les tests passent (`pytest tests/ -v`)
- [ ] Couverture de code > 80%
- [ ] Tests manuels des flux principaux
- [ ] Tests de performance acceptables
- [ ] Tests de responsive design
- [ ] Tests de compatibilité navigateurs

