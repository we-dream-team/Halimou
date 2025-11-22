"""
Tests pour les endpoints d'inventaires
"""
import pytest
import pytest_asyncio
from datetime import date, timedelta


class TestInventories:
    """Tests pour les opérations CRUD sur les inventaires"""
    
    @pytest.mark.asyncio

    
    async def test_create_inventory(self, test_client, sample_product_data, sample_inventory_data):
        """Test de création d'un inventaire"""
        # Créer d'abord un produit
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 200
        data = response.json()
        assert data["date"] == inventory_data["date"]
        assert len(data["products"]) == 1
        assert data["total_revenue"] == 15 * 1.50  # quantity_sold * price
        assert "id" in data
        assert "created_at" in data
    
    @pytest.mark.asyncio

    
    async def test_create_inventory_duplicate_date(self, test_client, sample_product_data, sample_inventory_data):
        """Test de création d'un inventaire avec une date déjà existante"""
        # Créer un produit
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        
        # Créer le premier inventaire
        await test_client.post("/api/inventories", json=inventory_data)
        
        # Essayer de créer un deuxième avec la même date
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 400
        data = response.json()
        assert "already exists" in data["detail"].lower()
    
    @pytest.mark.asyncio

    
    async def test_create_inventory_empty_products(self, test_client):
        """Test de création d'un inventaire sans produits"""
        inventory_data = {
            "date": "2024-01-15",
            "products": []
        }
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_create_inventory_invalid_product(self, test_client, sample_inventory_data):
        """Test de création avec un produit invalide"""
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = ""  # ID vide
        
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_create_inventory_negative_price(self, test_client, sample_product_data, sample_inventory_data):
        """Test de création avec un prix négatif"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        inventory_data["products"][0]["price"] = -1.0
        
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_get_all_inventories(self, test_client, sample_product_data, sample_inventory_data):
        """Test de récupération de tous les inventaires"""
        # Créer un produit
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        # Créer plusieurs inventaires
        dates = ["2024-01-15", "2024-01-16", "2024-01-17"]
        for test_date in dates:
            inventory_data = sample_inventory_data.copy()
            inventory_data["date"] = test_date
            inventory_data["products"][0]["product_id"] = product["id"]
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get("/api/inventories")
        assert response.status_code == 200
        inventories = response.json()
        assert isinstance(inventories, list)
        assert len(inventories) == 3
        # Vérifier que les inventaires sont triés par date décroissante
        assert inventories[0]["date"] == "2024-01-17"
    
    @pytest.mark.asyncio

    
    async def test_get_inventory_by_date(self, test_client, sample_product_data, sample_inventory_data):
        """Test de récupération d'un inventaire par date"""
        # Créer un produit et un inventaire
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get(f"/api/inventories/{inventory_data['date']}")
        assert response.status_code == 200
        data = response.json()
        assert data["date"] == inventory_data["date"]
    
    @pytest.mark.asyncio

    
    async def test_get_inventory_not_found(self, test_client):
        """Test de récupération d'un inventaire inexistant"""
        response = await test_client.get("/api/inventories/2020-01-01")
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_update_inventory(self, test_client, sample_product_data, sample_inventory_data):
        """Test de mise à jour d'un inventaire"""
        # Créer un produit et un inventaire
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        inventory_response = await test_client.post("/api/inventories", json=inventory_data)
        created = inventory_response.json()
        
        # Mettre à jour les quantités
        updated_products = created["products"].copy()
        updated_products[0]["quantity_sold"] = 20
        updated_products[0]["quantity_remaining"] = 5
        
        response = await test_client.put(f"/api/inventories/{inventory_data['date']}", json={"products": updated_products})
        assert response.status_code == 200
        data = response.json()
        assert data["products"][0]["quantity_sold"] == 20
        # Vérifier que le total_revenue est recalculé
        assert data["total_revenue"] == 20 * 1.50
    
    @pytest.mark.asyncio

    
    async def test_update_inventory_not_found(self, test_client):
        """Test de mise à jour d'un inventaire inexistant"""
        response = await test_client.put("/api/inventories/2020-01-01", json={"products": []})
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_delete_inventory(self, test_client, sample_product_data, sample_inventory_data):
        """Test de suppression d'un inventaire"""
        # Créer un produit et un inventaire
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        inventory_data = sample_inventory_data.copy()
        inventory_data["products"][0]["product_id"] = product["id"]
        await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.delete(f"/api/inventories/{inventory_data['date']}")
        assert response.status_code == 200
        
        # Vérifier que l'inventaire n'existe plus
        get_response = await test_client.get(f"/api/inventories/{inventory_data['date']}")
        assert get_response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_inventory_revenue_calculation(self, test_client, sample_product_data):
        """Test du calcul automatique du revenu total"""
        # Créer un produit
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        # Créer un inventaire avec plusieurs produits
        inventory_data = {
            "date": "2024-01-15",
            "products": [
                {
                    "product_id": product["id"],
                    "product_name": product["name"],
                    "category": product["category"],
                    "quantity_produced": 20,
                    "quantity_sold": 10,
                    "quantity_wasted": 2,
                    "quantity_remaining": 8,
                    "price": 1.50
                },
                {
                    "product_id": product["id"],
                    "product_name": product["name"],
                    "category": product["category"],
                    "quantity_produced": 15,
                    "quantity_sold": 12,
                    "quantity_wasted": 1,
                    "quantity_remaining": 2,
                    "price": 2.00
                }
            ]
        }
        
        response = await test_client.post("/api/inventories", json=inventory_data)
        data = response.json()
        expected_revenue = (10 * 1.50) + (12 * 2.00)  # 15 + 24 = 39
        assert data["total_revenue"] == expected_revenue

