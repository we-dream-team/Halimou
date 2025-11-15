# 🥐 Application de Gestion d'Inventaire Pâtisserie

Application mobile complète pour gérer l'inventaire quotidien d'une pâtisserie-boulangerie.

## 📱 Fonctionnalités Principales

### 1. **Inventaire du Jour**
- Sélection des produits disponibles
- Saisie des quantités : produites, vendues, jetées
- Calcul automatique des quantités restantes
- Résumé du chiffre d'affaires quotidien

### 2. **Catalogue Produits**
- Gestion complète des produits (CRUD)
- Catégories : viennoiserie, gâteau, autre
- Prix unitaires
- Produits récurrents vs produits du jour
- 6 produits pré-configurés :
  - Croissant (1.20 €)
  - Pain au chocolat (1.30 €)
  - Mille-feuille (4.50 €)
  - Tarte aux pommes (3.80 €)
  - Pain aux raisins (1.40 €)
  - Éclair au chocolat (3.20 €)

### 3. **Statistiques & Historique**
- Vue d'ensemble : CA, produits vendus/jetés/fabriqués
- Filtres par période : 7 jours, 30 jours, tout
- Performance par produit :
  - Moyenne de vente par jour
  - Taux de vente
  - Taux de gaspillage
- Historique des inventaires récents
- Export des données

## 🎨 Design

- **Interface moderne et épurée**
- **Navigation par tabs** (bas de l'écran)
- **Gros boutons tactiles** (min 44x44)
- **Couleurs professionnelles** :
  - Bleu : #4A90E2 (principal)
  - Vert : #10B981 (ventes, CA)
  - Rouge : #EF4444 (gaspillage)
  - Orange : #F59E0B (production)

## 🚀 Comment Utiliser

### Premier jour

1. **Ajouter des produits** (onglet Produits)
   - Cliquer sur "Ajouter un produit"
   - Remplir : nom, catégorie, prix
   - Cocher "Produit récurrent" pour les produits quotidiens

2. **Créer l'inventaire du jour** (onglet Inventaire)
   - Cliquer sur "Gérer les produits"
   - Sélectionner les produits disponibles aujourd'hui
   - Confirmer
   - Saisir les quantités produites
   - Au fil de la journée : mettre à jour les ventes
   - En fin de journée : ajouter les quantités jetées
   - Enregistrer

3. **Consulter les statistiques** (onglet Statistiques)
   - Voir le CA total
   - Analyser les performances par produit
   - Identifier les produits avec trop de gaspillage
   - Ajuster la production pour les jours suivants

### Jours suivants

1. Aller dans l'onglet Inventaire
2. La date du jour est automatiquement sélectionnée
3. Cliquer sur "Gérer les produits" pour ajouter les produits du jour
4. Les produits récurrents sont déjà pré-sélectionnés
5. Saisir les quantités et enregistrer

## 🛠️ Architecture Technique

### Frontend
- **Framework** : Expo (React Native)
- **Navigation** : expo-router avec tabs
- **Librairies** :
  - axios (API calls)
  - date-fns (gestion dates)
  - react-native-modal (modals)
  - @expo/vector-icons (icônes)

### Backend
- **Framework** : FastAPI (Python)
- **Base de données** : MongoDB
- **API** : REST avec préfixe `/api`

### Collections MongoDB

**products**
```json
{
  "_id": ObjectId,
  "name": string,
  "category": string,
  "price": float,
  "is_recurring": boolean,
  "is_archived": boolean,
  "created_at": datetime
}
```

**inventories**
```json
{
  "_id": ObjectId,
  "date": string (YYYY-MM-DD),
  "products": [
    {
      "product_id": string,
      "product_name": string,
      "category": string,
      "quantity_produced": int,
      "quantity_sold": int,
      "quantity_wasted": int,
      "quantity_remaining": int,
      "price": float
    }
  ],
  "total_revenue": float,
  "created_at": datetime,
  "updated_at": datetime
}
```

## 📊 API Endpoints

### Produits
- `POST /api/products` - Créer un produit
- `GET /api/products` - Lister tous les produits
- `GET /api/products/{id}` - Obtenir un produit
- `PUT /api/products/{id}` - Modifier un produit
- `DELETE /api/products/{id}` - Supprimer un produit

### Inventaires
- `POST /api/inventories` - Créer un inventaire
- `GET /api/inventories` - Lister les inventaires
- `GET /api/inventories/{date}` - Obtenir un inventaire par date
- `PUT /api/inventories/{date}` - Modifier un inventaire
- `DELETE /api/inventories/{date}` - Supprimer un inventaire

### Statistiques
- `GET /api/stats/summary` - Résumé global (avec filtres date)
- `GET /api/stats/product/{id}` - Stats par produit
- `GET /api/export` - Exporter les données

## 💡 Conseils d'Utilisation

### Réduire le gaspillage
- Consulter régulièrement les statistiques
- Identifier les produits avec taux de gaspillage élevé
- Ajuster les quantités produites selon les moyennes de vente

### Optimiser la production
- Observer les tendances par jour de la semaine
- Les produits récurrents sont toujours disponibles dans l'inventaire
- Ajouter des produits spéciaux uniquement certains jours

### Suivre le CA
- Vérifier le CA quotidien dans l'inventaire
- Comparer les périodes dans les statistiques
- Identifier les produits les plus rentables

## 🎯 Prochaines Évolutions Possibles

- Prévisions de vente basées sur l'historique
- Gestion multi-utilisateurs (équipe)
- Notifications pour produits en surplus
- Graphiques de tendances
- Export Excel/PDF des statistiques
- Photos des produits
- Gestion des ingrédients et stocks

## 📝 Notes

- L'application fonctionne en mode web et peut être installée comme PWA
- Les données sont sauvegardées automatiquement dans MongoDB
- Pas d'authentification requise (un seul utilisateur)
- Interface optimisée pour smartphone et tablette

---

**Développé avec ❤️ pour les artisans pâtissiers**
