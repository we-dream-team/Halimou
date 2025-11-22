"""
Configuration et fixtures pour les tests pytest
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient
import os
from pathlib import Path
from dotenv import load_dotenv

# Charger les variables d'environnement
ROOT_DIR = Path(__file__).parent.parent
env_file = ROOT_DIR / 'backend' / '.env'
if env_file.exists():
    load_dotenv(env_file)

# Définir les variables d'environnement par défaut pour les tests
os.environ.setdefault('MONGO_URL', 'mongodb://localhost:27017')
os.environ.setdefault('DB_NAME', 'halimou')

# Base de données de test
TEST_DB_NAME = os.getenv('DB_NAME', 'halimou') + '_test'
TEST_MONGO_URL = os.getenv('MONGO_URL', 'mongodb://localhost:27017')


@pytest_asyncio.fixture(scope="function")
async def test_client():
    """Créer un client de test FastAPI avec une base de données de test"""
    import sys
    backend_path = str(ROOT_DIR / 'backend')
    if backend_path not in sys.path:
        sys.path.insert(0, backend_path)
    
    # Importer le serveur
    import server
    from motor.motor_asyncio import AsyncIOMotorClient
    
    # Créer une connexion à la base de données de test
    test_client_mongo = AsyncIOMotorClient(TEST_MONGO_URL)
    test_db = test_client_mongo[TEST_DB_NAME]
    
    # Nettoyer la base de données de test avant le test
    collections = ['products', 'inventories', 'employees', 'payrolls']
    for collection_name in collections:
        await test_db[collection_name].delete_many({})
    
    # Sauvegarder la référence originale de db
    original_db = server.db
    
    # Remplacer temporairement la base de données
    server.db = test_db
    
    # Créer le client de test
    from server import app
    from httpx import ASGITransport
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
    
    # Nettoyer après le test
    for collection_name in collections:
        await test_db[collection_name].delete_many({})
    
    # Restaurer la DB originale
    server.db = original_db
    test_client_mongo.close()


@pytest.fixture
def sample_product_data():
    """Données d'exemple pour un produit"""
    return {
        "name": "Croissant",
        "category": "viennoiserie",
        "price": 1.50,
        "is_recurring": True
    }


@pytest.fixture
def sample_inventory_data(sample_product_data):
    """Données d'exemple pour un inventaire"""
    return {
        "date": "2024-01-15",
        "products": [
            {
                "product_id": "test_product_id",
                "product_name": sample_product_data["name"],
                "category": sample_product_data["category"],
                "quantity_produced": 20,
                "quantity_sold": 15,
                "quantity_wasted": 2,
                "quantity_remaining": 3,
                "price": sample_product_data["price"]
            }
        ]
    }


@pytest.fixture
def sample_employee_data():
    """Données d'exemple pour un employé"""
    return {
        "full_name": "Jean Dupont",
        "role": "Pâtissier",
        "base_salary": 2500.00
    }


@pytest.fixture
def sample_payroll_data():
    """Données d'exemple pour une fiche de paie"""
    return {
        "employee_id": "test_employee_id",
        "period": "2024-01",
        "advances": 500.00,
        "paid": 0,
        "notes": "Avance sur salaire"
    }
