"""
Tests pour les endpoints de statistiques
"""
import pytest
import pytest_asyncio
from datetime import date, timedelta


class TestStatistics:
    """Tests pour les statistiques"""
    
    @pytest.mark.asyncio

    
    async def test_stats_summary(self, test_client, sample_product_data):
        """Test de récupération du résumé des statistiques"""
        # Créer des produits et inventaires
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        # Créer des inventaires pour plusieurs dates
        for i in range(3):
            inventory_data = {
                "date": (date.today() - timedelta(days=2-i)).strftime("%Y-%m-%d"),
                "products": [{
                    "product_id": product["id"],
                    "product_name": product["name"],
                    "category": product["category"],
                    "quantity_produced": 20 + i,
                    "quantity_sold": 15 + i,
                    "quantity_wasted": 2,
                    "quantity_remaining": 3 + i,
                    "price": product["price"]
                }]
            }
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get("/api/stats/summary")
        assert response.status_code == 200
        stats = response.json()
        
        assert "total_sales" in stats
        assert "total_wasted" in stats
        assert "total_sold" in stats
        assert "total_produced" in stats
        assert "products_stats" in stats
        
        assert stats["total_sold"] > 0
        assert stats["total_produced"] > 0
        assert isinstance(stats["products_stats"], list)
        assert len(stats["products_stats"]) > 0
    
    @pytest.mark.asyncio

    
    async def test_stats_summary_with_date_range(self, test_client, sample_product_data):
        """Test de statistiques avec une plage de dates"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        # Créer des inventaires
        start_date = (date.today() - timedelta(days=5)).strftime("%Y-%m-%d")
        end_date = (date.today() - timedelta(days=2)).strftime("%Y-%m-%d")
        
        for i in range(4):
            inventory_data = {
                "date": (date.today() - timedelta(days=5-i)).strftime("%Y-%m-%d"),
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
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get(f"/api/stats/summary?start_date={start_date}&end_date={end_date}")
        assert response.status_code == 200
        stats = response.json()
        assert stats["total_sold"] > 0
    
    @pytest.mark.asyncio

    
    async def test_stats_summary_empty(self, test_client):
        """Test de statistiques sans données"""
        response = await test_client.get("/api/stats/summary")
        assert response.status_code == 200
        stats = response.json()
        assert stats["total_sales"] == 0.0
        assert stats["total_wasted"] == 0
        assert stats["total_sold"] == 0
        assert stats["total_produced"] == 0
        assert stats["products_stats"] == []
    
    @pytest.mark.asyncio

    
    async def test_product_stats(self, test_client, sample_product_data):
        """Test de statistiques par produit"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        # Créer des inventaires avec ce produit
        for i in range(3):
            inventory_data = {
                "date": (date.today() - timedelta(days=2-i)).strftime("%Y-%m-%d"),
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
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get(f"/api/stats/product/{product['id']}")
        assert response.status_code == 200
        stats = response.json()
        
        assert stats["product_id"] == product["id"]
        assert "daily_stats" in stats
        assert isinstance(stats["daily_stats"], list)
        assert len(stats["daily_stats"]) == 3
    
    @pytest.mark.asyncio

    
    async def test_product_stats_with_date_range(self, test_client, sample_product_data):
        """Test de statistiques produit avec plage de dates"""
        product_response = await test_client.post("/api/products", json=sample_product_data)
        product = product_response.json()
        
        start_date = (date.today() - timedelta(days=3)).strftime("%Y-%m-%d")
        end_date = (date.today() - timedelta(days=1)).strftime("%Y-%m-%d")
        
        # Créer des inventaires
        for i in range(5):
            inventory_data = {
                "date": (date.today() - timedelta(days=4-i)).strftime("%Y-%m-%d"),
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
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get(
            f"/api/stats/product/{product['id']}?start_date={start_date}&end_date={end_date}"
        )
        assert response.status_code == 200
        stats = response.json()
        # Devrait avoir seulement les jours dans la plage
        assert len(stats["daily_stats"]) <= 3
    
    @pytest.mark.asyncio

    
    async def test_stats_products_performance(self, test_client, sample_product_data):
        """Test des statistiques de performance par produit"""
        # Créer plusieurs produits
        products = []
        for i in range(3):
            product_data = {**sample_product_data, "name": f"Produit {i}"}
            product_response = await test_client.post("/api/products", json=product_data)
            product = product_response.json()
            products.append(product)
        
        # Créer des inventaires avec différents produits
        for i, product in enumerate(products):
            inventory_data = {
                "date": (date.today() - timedelta(days=2-i)).strftime("%Y-%m-%d"),
                "products": [{
                    "product_id": product["id"],
                    "product_name": product["name"],
                    "category": product["category"],
                    "quantity_produced": 20,
                    "quantity_sold": 15 + i,  # Différentes quantités vendues
                    "quantity_wasted": 2,
                    "quantity_remaining": 3,
                    "price": product["price"]
                }]
            }
            await test_client.post("/api/inventories", json=inventory_data)
        
        response = await test_client.get("/api/stats/summary")
        stats = response.json()
        
        # Vérifier que les statistiques par produit sont correctes
        assert len(stats["products_stats"]) == 3
        for product_stat in stats["products_stats"]:
            assert "product_id" in product_stat
            assert "total_revenue" in product_stat
            assert "avg_sold_per_day" in product_stat
            assert product_stat["total_revenue"] > 0

