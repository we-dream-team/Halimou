"""
Tests de validation et gestion d'erreurs
"""
import pytest
import pytest_asyncio
from bson import ObjectId


class TestValidation:
    """Tests pour la validation des données"""
    
    @pytest.mark.asyncio

    
    async def test_product_validation_missing_fields(self, test_client):
        """Test de validation avec champs manquants"""
        # Nom manquant
        invalid_data = {"category": "viennoiserie", "price": 1.50}
        response = await test_client.post("/api/products", json=invalid_data)
        assert response.status_code in [400, 422]  # Validation error (backend returns 400)
    
    @pytest.mark.asyncio

    
    async def test_product_validation_invalid_price(self, test_client):
        """Test de validation avec prix invalide"""
        invalid_data = {
            "name": "Test",
            "category": "viennoiserie",
            "price": "not_a_number"  # Prix invalide
        }
        response = await test_client.post("/api/products", json=invalid_data)
        assert response.status_code in [400, 422]  # Validation error (backend returns 400)
    
    @pytest.mark.asyncio

    
    async def test_inventory_validation_invalid_date_format(self, test_client):
        """Test de validation avec format de date invalide"""
        invalid_data = {
            "date": "15-01-2024",  # Format invalide
            "products": []
        }
        response = await test_client.post("/api/inventories", json=invalid_data)
        # Le format de date devrait être validé
        assert response.status_code in [400, 422]
    
    @pytest.mark.asyncio

    
    async def test_inventory_validation_missing_product_fields(self, test_client):
        """Test de validation avec champs de produit manquants"""
        invalid_data = {
            "date": "2024-01-15",
            "products": [{
                "product_id": "test",
                # Champs manquants
            }]
        }
        response = await test_client.post("/api/inventories", json=invalid_data)
        assert response.status_code in [400, 422]
    
    @pytest.mark.asyncio

    
    async def test_employee_validation_missing_fields(self, test_client):
        """Test de validation d'employé avec champs manquants"""
        # base_salary a une valeur par défaut, donc testons avec un champ vraiment requis manquant
        invalid_data = {}  # full_name manquant (requis)
        response = await test_client.post("/api/employees", json=invalid_data)
        assert response.status_code in [400, 422]  # Validation error
    
    @pytest.mark.asyncio

    
    async def test_payroll_validation_invalid_employee(self, test_client):
        """Test de validation avec employé inexistant"""
        invalid_data = {
            "employee_id": str(ObjectId()),  # ID inexistant
            "period": "2024-01",
            "advances": 500.00
        }
        response = await test_client.post("/api/payrolls", json=invalid_data)
        assert response.status_code == 400


class TestErrorHandling:
    """Tests pour la gestion des erreurs"""
    
    @pytest.mark.asyncio

    
    async def test_404_product_not_found(self, test_client):
        """Test 404 pour produit inexistant"""
        fake_id = str(ObjectId())
        response = await test_client.get(f"/api/products/{fake_id}")
        assert response.status_code == 404
        data = response.json()
        assert "not found" in data["detail"].lower()
    
    @pytest.mark.asyncio

    
    async def test_404_inventory_not_found(self, test_client):
        """Test 404 pour inventaire inexistant"""
        response = await test_client.get("/api/inventories/2020-01-01")
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_404_employee_not_found(self, test_client):
        """Test 404 pour employé inexistant"""
        fake_id = str(ObjectId())
        response = await test_client.get(f"/api/employees/{fake_id}")
        assert response.status_code == 404
    
    @pytest.mark.asyncio

    
    async def test_400_duplicate_inventory(self, test_client, sample_product_data):
        """Test 400 pour inventaire en double"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        inventory_data = {
            "date": "2024-01-15",
            "products": [{
                "product_id": product["id"],
                "product_name": product["name"],
                "category": product["category"],
                "quantity_produced": 20,
                "quantity_sold": 15,
                "quantity_wasted": 2,
                "quantity_remaining": 3,
                "price": product["price"]
            }]
        }
        
        # Créer le premier
        await test_client.post("/api/inventories", json=inventory_data)
        
        # Essayer de créer un deuxième
        response = await test_client.post("/api/inventories", json=inventory_data)
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_400_update_no_fields(self, test_client, sample_product_data):
        """Test 400 pour mise à jour sans champs"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        response = await test_client.put(f"/api/products/{product['id']}", json={})
        assert response.status_code == 400
    
    @pytest.mark.asyncio

    
    async def test_health_check_endpoint(self, test_client):
        """Test du endpoint de health check"""
        response = await test_client.get("/api/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "status" in data
        assert data["status"] == "running"

