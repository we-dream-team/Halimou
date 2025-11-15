"""
Database initialization script
Creates indexes for optimized queries
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv
from pathlib import Path

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

async def init_database():
    # MongoDB connection
    mongo_url = os.environ['MONGO_URL']
    client = AsyncIOMotorClient(mongo_url)
    db = client[os.environ['DB_NAME']]
    
    print("Creating indexes for optimal performance...")
    
    # Create index on products.is_archived for filtering
    await db.products.create_index([('is_archived', 1)])
    print("✓ Index created: products.is_archived")
    
    # Create index on inventories.date for sorting (descending for recent first)
    await db.inventories.create_index([('date', -1)])
    print("✓ Index created: inventories.date (descending)")
    
    # Create compound index for common query pattern
    await db.inventories.create_index([('date', -1), ('total_revenue', -1)])
    print("✓ Index created: inventories.date + total_revenue")
    
    print("\n✅ Database indexes initialized successfully!")
    
    client.close()

if __name__ == "__main__":
    asyncio.run(init_database())
