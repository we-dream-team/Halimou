"""
Tests pour les endpoints de produits
"""
import pytest
import pytest_asyncio
from bson import ObjectId


class TestProducts:
    """Tests pour les opérations CRUD sur les produits"""
    
    @pytest.mark.asyncio
    async def test_create_product(self, test_client, sample_product_data):
        """Test de création d'un produit"""
        response = await test_client.post("/api/products", json=sample_product_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == sample_product_data["name"]
        assert data["category"] == sample_product_data["category"]
        assert data["price"] == sample_product_data["price"]
        assert data["is_recurring"] == sample_product_data["is_recurring"]
        assert data["is_archived"] is False
        assert "id" in data
        assert "created_at" in data
    
    @pytest.mark.asyncio

    
    async def test_create_product_invalid_data(self, test_client):
        """Test de création avec des données invalides"""
        # Prix négatif
        invalid_data = {
            "name": "Test",
            "category": "viennoiserie",
            "price": -1.0
        }
        response = await test_client.post("/api/products", json=invalid_data)
        assert response.status_code in [400, 422]  # Validation error (backend may return 400 or 422)
    
    @pytest.mark.asyncio

    
    async def test_get_all_products(self, test_client, sample_product_data):
        """Test de récupération de tous les produits"""
        # Créer quelques produits
        for i in range(3):
            product_data = {**sample_product_data, "name": f"Produit {i}"}
            await test_client.post("/api/products", json=product_data)
        
        response = await test_client.get("/api/products")
        assert response.status_code == 200
        products = response.json()
        assert isinstance(products, list)
        assert len(products) == 3
    
    @pytest.mark.asyncio

    
    async def test_get_all_products_exclude_archived(self, test_client, sample_product_data):
        """Test que les produits archivés ne sont pas retournés par défaut"""
        # Créer un produit normal
        normal_response = await test_client.post("/api/products", json=sample_product_data)
        normal_product = normal_response.json()
        
        # Créer et archiver un produit
        archived_data = {**sample_product_data, "name": "Archived Product"}
        archived_response = await test_client.post("/api/products", json=archived_data)
        archived_product = archived_response.json()
        await test_client.put(f"/api/products/{archived_product['id']}", json={"is_archived": True})
        
        # Récupérer tous les produits
        response = await test_client.get("/api/products")
        products = response.json()
        product_ids = [p["id"] for p in products]
        
        assert normal_product["id"] in product_ids
        assert archived_product["id"] not in product_ids
    
    @pytest.mark.asyncio

    
    async def test_get_all_products_include_archived(self, test_client, sample_product_data):
        """Test de récupération avec les produits archivés"""
        # Créer et archiver un produit
        archived_data = {**sample_product_data, "name": "Archived Product"}
        archived_response = await test_client.post("/api/products", json=archived_data)
        archived_product = archived_response.json()
        await test_client.put(f"/api/products/{archived_product['id']}", json={"is_archived": True})
        
        # Récupérer avec include_archived=True
        response = await test_client.get("/api/products?include_archived=true")
        products = response.json()
        product_ids = [p["id"] for p in products]
        
        assert archived_product["id"] in product_ids
    
    @pytest.mark.asyncio

    
    async def test_get_product_by_id(self, test_client, sample_product_data):
        """Test de récupération d'un produit par ID"""
        created_response = await test_client.post("/api/products", json=sample_product_data)
        created = created_response.json()
        product_id = created["id"]
        
        response = await test_client.get(f"/api/products/{product_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == product_id
        assert data["name"] == sample_product_data["name"]
    
    @pytest.mark.asyncio

    
    async def test_get_product_not_found(self, test_client):
        """Test de récupération d'un produit inexistant"""
        fake_id = str(ObjectId())
        response = await test_client.get(f"/api/products/{fake_id}")
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_update_product(self, test_client, sample_product_data):
        """Test de mise à jour d'un produit"""
        created_response = await test_client.post("/api/products", json=sample_product_data)
        created = created_response.json()
        product_id = created["id"]
        
        update_data = {"price": 2.00, "name": "Croissant Premium"}
        response = await test_client.put(f"/api/products/{product_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["price"] == 2.00
        assert data["name"] == "Croissant Premium"
        # Les autres champs ne doivent pas changer
        assert data["category"] == sample_product_data["category"]
    
    @pytest.mark.asyncio

    
    async def test_update_product_partial(self, test_client, sample_product_data):
        """Test de mise à jour partielle d'un produit"""
        created_response = await test_client.post("/api/products", json=sample_product_data)
        created = created_response.json()
        product_id = created["id"]
        
        # Mettre à jour seulement le prix
        update_data = {"price": 3.50}
        response = await test_client.put(f"/api/products/{product_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["price"] == 3.50
        assert data["name"] == sample_product_data["name"]  # Inchangé
    
    @pytest.mark.asyncio

    
    async def test_update_product_no_fields(self, test_client, sample_product_data):
        """Test de mise à jour sans champs"""
        created_response = await test_client.post("/api/products", json=sample_product_data)
        created = created_response.json()
        product_id = created["id"]
        
        response = await test_client.put(f"/api/products/{product_id}", json={})
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_update_product_not_found(self, test_client):
        """Test de mise à jour d'un produit inexistant"""
        fake_id = str(ObjectId())
        response = await test_client.put(f"/api/products/{fake_id}", json={"price": 2.0})
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_delete_product(self, test_client, sample_product_data):
        """Test de suppression d'un produit"""
        created_response = await test_client.post("/api/products", json=sample_product_data)
        created = created_response.json()
        product_id = created["id"]
        
        response = await test_client.delete(f"/api/products/{product_id}")
        assert response.status_code == 200
        
        # Vérifier que le produit n'existe plus
        get_response = await test_client.get(f"/api/products/{product_id}")
        assert get_response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_delete_product_not_found(self, test_client):
        """Test de suppression d'un produit inexistant"""
        fake_id = str(ObjectId())
        response = await test_client.delete(f"/api/products/{fake_id}")
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_product_categories(self, test_client):
        """Test avec différentes catégories de produits"""
        categories = ["viennoiserie", "gâteau", "autre"]
        for category in categories:
            product_data = {
                "name": f"Produit {category}",
                "category": category,
                "price": 1.0
            }
            response = await test_client.post("/api/products", json=product_data)
            assert response.status_code == 200
            data = response.json()
            assert data["category"] == category

