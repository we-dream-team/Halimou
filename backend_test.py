#!/usr/bin/env python3
"""
Backend API Test Suite for Pâtisserie Inventory Application
Tests all CRUD operations, statistics, and export functionality
"""

import requests
import json
from datetime import datetime, date, timedelta
import sys
import os

# Get backend URL from frontend .env file
def get_backend_url():
    try:
        with open('/app/frontend/.env', 'r') as f:
            for line in f:
                if line.startswith('EXPO_PUBLIC_BACKEND_URL='):
                    return line.split('=', 1)[1].strip()
    except FileNotFoundError:
        pass
    return "http://localhost:8001"

BASE_URL = get_backend_url()
API_URL = f"{BASE_URL}/api"

print(f"Testing backend API at: {API_URL}")

class TestResults:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.errors = []
    
    def success(self, test_name):
        self.passed += 1
        print(f"✅ {test_name}")
    
    def failure(self, test_name, error):
        self.failed += 1
        self.errors.append(f"{test_name}: {error}")
        print(f"❌ {test_name}: {error}")
    
    def summary(self):
        total = self.passed + self.failed
        print(f"\n{'='*60}")
        print(f"TEST SUMMARY: {self.passed}/{total} tests passed")
        if self.errors:
            print(f"\nFAILED TESTS:")
            for error in self.errors:
                print(f"  - {error}")
        print(f"{'='*60}")
        return self.failed == 0

results = TestResults()

# Test data storage
created_products = []
created_inventories = []

def test_health_check():
    """Test API health check endpoint"""
    try:
        response = requests.get(f"{API_URL}/")
        if response.status_code == 200:
            data = response.json()
            if "message" in data and "status" in data:
                results.success("Health check endpoint")
                return True
            else:
                results.failure("Health check endpoint", "Invalid response format")
        else:
            results.failure("Health check endpoint", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Health check endpoint", str(e))
    return False

def test_create_products():
    """Test creating sample products"""
    products_data = [
        {"name": "Croissant", "category": "viennoiserie", "price": 1.50, "is_recurring": True},
        {"name": "Pain au chocolat", "category": "viennoiserie", "price": 1.80, "is_recurring": True},
        {"name": "Mille-feuille", "category": "gâteau", "price": 4.50, "is_recurring": True},
        {"name": "Tarte aux pommes", "category": "gâteau", "price": 3.20, "is_recurring": True}
    ]
    
    for product_data in products_data:
        try:
            response = requests.post(f"{API_URL}/products", json=product_data)
            if response.status_code == 200:
                product = response.json()
                if "id" in product and product["name"] == product_data["name"]:
                    created_products.append(product)
                    results.success(f"Create product: {product_data['name']}")
                else:
                    results.failure(f"Create product: {product_data['name']}", "Invalid response format")
            else:
                results.failure(f"Create product: {product_data['name']}", f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            results.failure(f"Create product: {product_data['name']}", str(e))

def test_get_products():
    """Test retrieving all products"""
    try:
        response = requests.get(f"{API_URL}/products")
        if response.status_code == 200:
            products = response.json()
            if isinstance(products, list) and len(products) >= len(created_products):
                results.success("Get all products")
                return True
            else:
                results.failure("Get all products", f"Expected list with at least {len(created_products)} products, got {len(products) if isinstance(products, list) else 'non-list'}")
        else:
            results.failure("Get all products", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get all products", str(e))
    return False

def test_get_single_product():
    """Test retrieving a single product"""
    if not created_products:
        results.failure("Get single product", "No products created to test with")
        return False
    
    product_id = created_products[0]["id"]
    try:
        response = requests.get(f"{API_URL}/products/{product_id}")
        if response.status_code == 200:
            product = response.json()
            if product["id"] == product_id:
                results.success("Get single product")
                return True
            else:
                results.failure("Get single product", "Product ID mismatch")
        else:
            results.failure("Get single product", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get single product", str(e))
    return False

def test_update_product():
    """Test updating a product"""
    if not created_products:
        results.failure("Update product", "No products created to test with")
        return False
    
    product_id = created_products[0]["id"]
    update_data = {"price": 2.00}
    
    try:
        response = requests.put(f"{API_URL}/products/{product_id}", json=update_data)
        if response.status_code == 200:
            product = response.json()
            if product["price"] == 2.00:
                results.success("Update product")
                return True
            else:
                results.failure("Update product", f"Price not updated correctly: {product['price']}")
        else:
            results.failure("Update product", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Update product", str(e))
    return False

def test_create_inventories():
    """Test creating daily inventories"""
    if len(created_products) < 2:
        results.failure("Create inventories", "Need at least 2 products to test inventories")
        return False
    
    # Create inventories for 3 different dates
    dates = [
        (date.today() - timedelta(days=2)).strftime("%Y-%m-%d"),
        (date.today() - timedelta(days=1)).strftime("%Y-%m-%d"),
        date.today().strftime("%Y-%m-%d")
    ]
    
    for i, test_date in enumerate(dates):
        inventory_data = {
            "date": test_date,
            "products": [
                {
                    "product_id": created_products[0]["id"],
                    "product_name": created_products[0]["name"],
                    "category": created_products[0]["category"],
                    "quantity_produced": 20 + i * 5,
                    "quantity_sold": 15 + i * 3,
                    "quantity_wasted": 2,
                    "quantity_remaining": 3 + i * 2,
                    "price": created_products[0]["price"]
                },
                {
                    "product_id": created_products[1]["id"],
                    "product_name": created_products[1]["name"],
                    "category": created_products[1]["category"],
                    "quantity_produced": 15 + i * 3,
                    "quantity_sold": 12 + i * 2,
                    "quantity_wasted": 1,
                    "quantity_remaining": 2 + i,
                    "price": created_products[1]["price"]
                }
            ]
        }
        
        try:
            response = requests.post(f"{API_URL}/inventories", json=inventory_data)
            if response.status_code == 200:
                inventory = response.json()
                if "id" in inventory and inventory["date"] == test_date:
                    created_inventories.append(inventory)
                    # Verify total_revenue calculation
                    expected_revenue = sum(p["quantity_sold"] * p["price"] for p in inventory_data["products"])
                    if abs(inventory["total_revenue"] - expected_revenue) < 0.01:
                        results.success(f"Create inventory for {test_date}")
                    else:
                        results.failure(f"Create inventory for {test_date}", f"Revenue calculation incorrect: expected {expected_revenue}, got {inventory['total_revenue']}")
                else:
                    results.failure(f"Create inventory for {test_date}", "Invalid response format")
            else:
                results.failure(f"Create inventory for {test_date}", f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            results.failure(f"Create inventory for {test_date}", str(e))

def test_get_inventories():
    """Test retrieving all inventories"""
    try:
        response = requests.get(f"{API_URL}/inventories")
        if response.status_code == 200:
            inventories = response.json()
            if isinstance(inventories, list) and len(inventories) >= len(created_inventories):
                results.success("Get all inventories")
                return True
            else:
                results.failure("Get all inventories", f"Expected list with at least {len(created_inventories)} inventories")
        else:
            results.failure("Get all inventories", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get all inventories", str(e))
    return False

def test_get_inventory_by_date():
    """Test retrieving inventory by date"""
    if not created_inventories:
        results.failure("Get inventory by date", "No inventories created to test with")
        return False
    
    test_date = created_inventories[0]["date"]
    try:
        response = requests.get(f"{API_URL}/inventories/{test_date}")
        if response.status_code == 200:
            inventory = response.json()
            if inventory["date"] == test_date:
                results.success("Get inventory by date")
                return True
            else:
                results.failure("Get inventory by date", "Date mismatch")
        else:
            results.failure("Get inventory by date", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get inventory by date", str(e))
    return False

def test_update_inventory():
    """Test updating an inventory"""
    if not created_inventories:
        results.failure("Update inventory", "No inventories created to test with")
        return False
    
    test_date = created_inventories[0]["date"]
    # Update the first product's quantities
    updated_products = created_inventories[0]["products"].copy()
    updated_products[0]["quantity_sold"] = 20
    updated_products[0]["quantity_remaining"] = 5
    
    update_data = {"products": updated_products}
    
    try:
        response = requests.put(f"{API_URL}/inventories/{test_date}", json=update_data)
        if response.status_code == 200:
            inventory = response.json()
            if inventory["products"][0]["quantity_sold"] == 20:
                results.success("Update inventory")
                return True
            else:
                results.failure("Update inventory", "Quantity not updated correctly")
        else:
            results.failure("Update inventory", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Update inventory", str(e))
    return False

def test_stats_summary():
    """Test statistics summary endpoint"""
    try:
        response = requests.get(f"{API_URL}/stats/summary")
        if response.status_code == 200:
            stats = response.json()
            required_fields = ["total_sales", "total_wasted", "total_sold", "total_produced", "products_stats"]
            if all(field in stats for field in required_fields):
                if stats["total_sales"] > 0 and stats["total_sold"] > 0:
                    results.success("Get stats summary")
                    return True
                else:
                    results.failure("Get stats summary", "Stats values appear incorrect (zero values)")
            else:
                results.failure("Get stats summary", f"Missing required fields: {[f for f in required_fields if f not in stats]}")
        else:
            results.failure("Get stats summary", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get stats summary", str(e))
    return False

def test_stats_with_date_range():
    """Test statistics with date range"""
    start_date = (date.today() - timedelta(days=2)).strftime("%Y-%m-%d")
    end_date = date.today().strftime("%Y-%m-%d")
    
    try:
        response = requests.get(f"{API_URL}/stats/summary?start_date={start_date}&end_date={end_date}")
        if response.status_code == 200:
            stats = response.json()
            if "total_sales" in stats and "products_stats" in stats:
                results.success("Get stats summary with date range")
                return True
            else:
                results.failure("Get stats summary with date range", "Invalid response format")
        else:
            results.failure("Get stats summary with date range", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get stats summary with date range", str(e))
    return False

def test_product_stats():
    """Test product-specific statistics"""
    if not created_products:
        results.failure("Get product stats", "No products created to test with")
        return False
    
    product_id = created_products[0]["id"]
    try:
        response = requests.get(f"{API_URL}/stats/product/{product_id}")
        if response.status_code == 200:
            stats = response.json()
            if "product_id" in stats and "daily_stats" in stats:
                if stats["product_id"] == product_id and isinstance(stats["daily_stats"], list):
                    results.success("Get product stats")
                    return True
                else:
                    results.failure("Get product stats", "Invalid stats format")
            else:
                results.failure("Get product stats", "Missing required fields")
        else:
            results.failure("Get product stats", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Get product stats", str(e))
    return False

def test_export():
    """Test data export endpoint"""
    try:
        response = requests.get(f"{API_URL}/export")
        if response.status_code == 200:
            data = response.json()
            if "inventories" in data and "products" in data:
                if isinstance(data["inventories"], list) and isinstance(data["products"], list):
                    results.success("Export data")
                    return True
                else:
                    results.failure("Export data", "Invalid data format")
            else:
                results.failure("Export data", "Missing required fields")
        else:
            results.failure("Export data", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Export data", str(e))
    return False

def test_export_with_date_range():
    """Test data export with date range"""
    start_date = (date.today() - timedelta(days=1)).strftime("%Y-%m-%d")
    end_date = date.today().strftime("%Y-%m-%d")
    
    try:
        response = requests.get(f"{API_URL}/export?start_date={start_date}&end_date={end_date}")
        if response.status_code == 200:
            data = response.json()
            if "inventories" in data and "products" in data:
                results.success("Export data with date range")
                return True
            else:
                results.failure("Export data with date range", "Invalid data format")
        else:
            results.failure("Export data with date range", f"Status code: {response.status_code}")
    except Exception as e:
        results.failure("Export data with date range", str(e))
    return False

def test_error_handling():
    """Test error handling scenarios"""
    
    # Test 404 for non-existent product
    try:
        response = requests.get(f"{API_URL}/products/507f1f77bcf86cd799439011")  # Valid ObjectId format
        if response.status_code == 404:
            results.success("404 error for non-existent product")
        else:
            results.failure("404 error for non-existent product", f"Expected 404, got {response.status_code}")
    except Exception as e:
        results.failure("404 error for non-existent product", str(e))
    
    # Test 404 for non-existent inventory
    try:
        response = requests.get(f"{API_URL}/inventories/2020-01-01")
        if response.status_code == 404:
            results.success("404 error for non-existent inventory")
        else:
            results.failure("404 error for non-existent inventory", f"Expected 404, got {response.status_code}")
    except Exception as e:
        results.failure("404 error for non-existent inventory", str(e))
    
    # Test duplicate inventory creation
    if created_inventories:
        duplicate_date = created_inventories[0]["date"]
        duplicate_data = {
            "date": duplicate_date,
            "products": [
                {
                    "product_id": created_products[0]["id"],
                    "product_name": created_products[0]["name"],
                    "category": created_products[0]["category"],
                    "quantity_produced": 10,
                    "quantity_sold": 8,
                    "quantity_wasted": 1,
                    "quantity_remaining": 1,
                    "price": created_products[0]["price"]
                }
            ]
        }
        
        try:
            response = requests.post(f"{API_URL}/inventories", json=duplicate_data)
            if response.status_code == 400:
                results.success("400 error for duplicate inventory date")
            else:
                results.failure("400 error for duplicate inventory date", f"Expected 400, got {response.status_code}")
        except Exception as e:
            results.failure("400 error for duplicate inventory date", str(e))

def test_delete_operations():
    """Test delete operations (cleanup)"""
    
    # Delete an inventory
    if created_inventories:
        test_date = created_inventories[-1]["date"]
        try:
            response = requests.delete(f"{API_URL}/inventories/{test_date}")
            if response.status_code == 200:
                results.success("Delete inventory")
            else:
                results.failure("Delete inventory", f"Status code: {response.status_code}")
        except Exception as e:
            results.failure("Delete inventory", str(e))
    
    # Delete a product
    if created_products:
        product_id = created_products[-1]["id"]
        try:
            response = requests.delete(f"{API_URL}/products/{product_id}")
            if response.status_code == 200:
                results.success("Delete product")
            else:
                results.failure("Delete product", f"Status code: {response.status_code}")
        except Exception as e:
            results.failure("Delete product", str(e))

def run_all_tests():
    """Run all tests in sequence"""
    print("Starting Pâtisserie Inventory API Tests...")
    print(f"Backend URL: {API_URL}")
    print("="*60)
    
    # Health check first
    if not test_health_check():
        print("❌ Health check failed - stopping tests")
        return False
    
    # Products CRUD tests
    test_create_products()
    test_get_products()
    test_get_single_product()
    test_update_product()
    
    # Inventory CRUD tests
    test_create_inventories()
    test_get_inventories()
    test_get_inventory_by_date()
    test_update_inventory()
    
    # Statistics tests
    test_stats_summary()
    test_stats_with_date_range()
    test_product_stats()
    
    # Export tests
    test_export()
    test_export_with_date_range()
    
    # Error handling tests
    test_error_handling()
    
    # Cleanup tests
    test_delete_operations()
    
    return results.summary()

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)