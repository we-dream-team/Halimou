from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, date
from bson import ObjectId

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Pydantic Models
class Product(BaseModel):
    id: Optional[str] = None
    name: str
    category: str  # gâteau, viennoiserie, autre
    price: float
    is_recurring: bool = True
    is_archived: bool = False
    created_at: Optional[datetime] = None

class ProductCreate(BaseModel):
    name: str
    category: str
    price: float
    is_recurring: bool = True

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    is_recurring: Optional[bool] = None
    is_archived: Optional[bool] = None

class InventoryProduct(BaseModel):
    product_id: str
    product_name: str
    category: str
    quantity_produced: int
    quantity_sold: int = 0
    quantity_wasted: int = 0
    quantity_remaining: int = 0
    price: float

class DailyInventory(BaseModel):
    id: Optional[str] = None
    date: str  # Format: YYYY-MM-DD
    products: List[InventoryProduct]
    total_revenue: float = 0.0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class DailyInventoryCreate(BaseModel):
    date: str
    products: List[InventoryProduct]

class DailyInventoryUpdate(BaseModel):
    products: List[InventoryProduct]

class StatsSummary(BaseModel):
    total_sales: float
    total_wasted: int
    total_sold: int
    total_produced: int
    products_stats: List[dict]

# Helper function to convert ObjectId to string
def serialize_doc(doc):
    if doc and "_id" in doc:
        doc["id"] = str(doc["_id"])
        del doc["_id"]
    return doc

# Products Endpoints
@api_router.post("/products", response_model=Product)
async def create_product(product: ProductCreate):
    product_dict = product.dict()
    product_dict["created_at"] = datetime.utcnow()
    product_dict["is_archived"] = False
    
    result = await db.products.insert_one(product_dict)
    created_product = await db.products.find_one({"_id": result.inserted_id})
    return Product(**serialize_doc(created_product))

@api_router.get("/products", response_model=List[Product])
async def get_products(include_archived: bool = False):
    query = {} if include_archived else {"is_archived": False}
    products = await db.products.find(query).to_list(1000)
    return [Product(**serialize_doc(p)) for p in products]

@api_router.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: str):
    product = await db.products.find_one({"_id": ObjectId(product_id)})
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return Product(**serialize_doc(product))

@api_router.put("/products/{product_id}", response_model=Product)
async def update_product(product_id: str, product_update: ProductUpdate):
    update_data = {k: v for k, v in product_update.dict().items() if v is not None}
    
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    result = await db.products.update_one(
        {"_id": ObjectId(product_id)},
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Product not found")
    
    updated_product = await db.products.find_one({"_id": ObjectId(product_id)})
    return Product(**serialize_doc(updated_product))

@api_router.delete("/products/{product_id}")
async def delete_product(product_id: str):
    result = await db.products.delete_one({"_id": ObjectId(product_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Product not found")
    return {"message": "Product deleted successfully"}

# Daily Inventory Endpoints
@api_router.post("/inventories", response_model=DailyInventory)
async def create_inventory(inventory: DailyInventoryCreate):
    # Check if inventory already exists for this date
    existing = await db.inventories.find_one({"date": inventory.date})
    if existing:
        raise HTTPException(status_code=400, detail="Inventory already exists for this date")
    
    inventory_dict = inventory.dict()
    inventory_dict["created_at"] = datetime.utcnow()
    inventory_dict["updated_at"] = datetime.utcnow()
    
    # Calculate total revenue
    total_revenue = sum(p["quantity_sold"] * p["price"] for p in inventory_dict["products"])
    inventory_dict["total_revenue"] = total_revenue
    
    result = await db.inventories.insert_one(inventory_dict)
    created_inventory = await db.inventories.find_one({"_id": result.inserted_id})
    return DailyInventory(**serialize_doc(created_inventory))

@api_router.get("/inventories", response_model=List[DailyInventory])
async def get_inventories(limit: int = 30):
    inventories = await db.inventories.find().sort("date", -1).limit(limit).to_list(limit)
    return [DailyInventory(**serialize_doc(inv)) for inv in inventories]

@api_router.get("/inventories/{date}", response_model=DailyInventory)
async def get_inventory_by_date(date: str):
    inventory = await db.inventories.find_one({"date": date})
    if not inventory:
        raise HTTPException(status_code=404, detail="Inventory not found for this date")
    return DailyInventory(**serialize_doc(inventory))

@api_router.put("/inventories/{date}", response_model=DailyInventory)
async def update_inventory(date: str, inventory_update: DailyInventoryUpdate):
    # Calculate total revenue
    products = inventory_update.products
    total_revenue = sum(p.quantity_sold * p.price for p in products)
    
    update_data = {
        "products": [p.dict() for p in products],
        "total_revenue": total_revenue,
        "updated_at": datetime.utcnow()
    }
    
    result = await db.inventories.update_one(
        {"date": date},
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Inventory not found")
    
    updated_inventory = await db.inventories.find_one({"date": date})
    return DailyInventory(**serialize_doc(updated_inventory))

@api_router.delete("/inventories/{date}")
async def delete_inventory(date: str):
    result = await db.inventories.delete_one({"date": date})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Inventory not found")
    return {"message": "Inventory deleted successfully"}

# Statistics Endpoints
@api_router.get("/stats/summary", response_model=StatsSummary)
async def get_stats_summary(start_date: Optional[str] = None, end_date: Optional[str] = None):
    query = {}
    if start_date and end_date:
        query["date"] = {"$gte": start_date, "$lte": end_date}
    elif start_date:
        query["date"] = {"$gte": start_date}
    elif end_date:
        query["date"] = {"$lte": end_date}
    
    inventories = await db.inventories.find(query).to_list(1000)
    
    total_sales = 0.0
    total_wasted = 0
    total_sold = 0
    total_produced = 0
    product_stats = {}
    
    for inv in inventories:
        total_sales += inv.get("total_revenue", 0)
        for p in inv.get("products", []):
            total_wasted += p.get("quantity_wasted", 0)
            total_sold += p.get("quantity_sold", 0)
            total_produced += p.get("quantity_produced", 0)
            
            # Product-specific stats
            prod_id = p.get("product_id")
            if prod_id not in product_stats:
                product_stats[prod_id] = {
                    "product_id": prod_id,
                    "product_name": p.get("product_name"),
                    "category": p.get("category"),
                    "total_produced": 0,
                    "total_sold": 0,
                    "total_wasted": 0,
                    "total_revenue": 0.0,
                    "avg_sold_per_day": 0.0
                }
            
            product_stats[prod_id]["total_produced"] += p.get("quantity_produced", 0)
            product_stats[prod_id]["total_sold"] += p.get("quantity_sold", 0)
            product_stats[prod_id]["total_wasted"] += p.get("quantity_wasted", 0)
            product_stats[prod_id]["total_revenue"] += p.get("quantity_sold", 0) * p.get("price", 0)
    
    # Calculate averages
    num_days = len(inventories) if inventories else 1
    for prod_id in product_stats:
        product_stats[prod_id]["avg_sold_per_day"] = round(product_stats[prod_id]["total_sold"] / num_days, 1)
    
    return StatsSummary(
        total_sales=total_sales,
        total_wasted=total_wasted,
        total_sold=total_sold,
        total_produced=total_produced,
        products_stats=list(product_stats.values())
    )

@api_router.get("/stats/product/{product_id}")
async def get_product_stats(product_id: str, start_date: Optional[str] = None, end_date: Optional[str] = None):
    query = {}
    if start_date and end_date:
        query["date"] = {"$gte": start_date, "$lte": end_date}
    
    inventories = await db.inventories.find(query).to_list(1000)
    
    daily_stats = []
    for inv in inventories:
        for p in inv.get("products", []):
            if p.get("product_id") == product_id:
                daily_stats.append({
                    "date": inv.get("date"),
                    "produced": p.get("quantity_produced", 0),
                    "sold": p.get("quantity_sold", 0),
                    "wasted": p.get("quantity_wasted", 0),
                    "revenue": p.get("quantity_sold", 0) * p.get("price", 0)
                })
    
    return {"product_id": product_id, "daily_stats": daily_stats}

# Export Endpoint
@api_router.get("/export")
async def export_data(start_date: Optional[str] = None, end_date: Optional[str] = None):
    query = {}
    if start_date and end_date:
        query["date"] = {"$gte": start_date, "$lte": end_date}
    
    inventories = await db.inventories.find(query).sort("date", -1).to_list(1000)
    products = await db.products.find({"is_archived": False}).to_list(1000)
    
    return {
        "inventories": [serialize_doc(inv) for inv in inventories],
        "products": [serialize_doc(p) for p in products]
    }

# Health check
@api_router.get("/")
async def root():
    return {"message": "Pâtisserie Inventory API", "status": "running"}

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
