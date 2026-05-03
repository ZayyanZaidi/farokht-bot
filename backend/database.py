import chromadb
from chromadb.config import Settings
import re
import os
CHROMA_DATA_PATH = os.environ.get("CHROMA_DATA_PATH", "./chroma_data")
client = chromadb.PersistentClient(path=CHROMA_DATA_PATH)
collection = client.get_or_create_collection(name="products")

def sync_product(product: dict):
    """Sync a single product (legacy, use batch version for better performance)."""
    sync_products_batch([product])

def sync_products_batch(products: list):
    """Sync multiple products in a single batch for high performance."""
    if not products:
        return
        
    documents = []
    ids = []
    metadatas = []
    
    for product in products:
        product_str = f"{product.get('brand', '')} {product.get('name', '')} {product.get('category', '')} {product.get('color', '')} {product.get('sku', '')}"
        documents.append(product_str)
        ids.append(str(product['id']))
        metadatas.append(product)
    
    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )

def normalize_query(query: str) -> str:
    """Handles plurals and common synonyms for Pakistani e-commerce."""
    query = query.lower().strip()
    
    # Plural to singular and synonym mapping
    plurals = {
        "kurtas": "kurta",
        "shoes": "shoe",
        "bags": "bag",
        "snacks": "snack",
        "desserts": "dessert",
        "jewelries": "jewelry",
        "socks": "sock",
        "bracelets": "bracelet",
        "clothes": "apparel",
        "clothing": "apparel",
        "dresses": "apparel",
        "suit": "apparel",
        "suits": "apparel",
        "kapray": "apparel",
        "joray": "apparel",
        "products": "product",
        "brands": "brand",
        "shadi": "wedding",
        "shaadi": "wedding",
        "partywear": "formal",
        "collection": ""
    }
    
    words = query.split()
    normalized_words = [plurals.get(word, word) for word in words]
    return " ".join(normalized_words)

def extract_entities(query: str) -> dict:
    """Extract key entities from query: brand, price range, product type, etc."""
    query_lower = query.lower()
    entities = {
        "brand": None,
        "product": None,
        "category": None,
        "min_price": None,
        "max_price": None,
        "color": None,
        "discount": False,
        "trending": False,
        "new": False,
        "similar": False
    }
    
    # Detect intent modifiers
    entities["discount"] = any(word in query_lower for word in ["discount", "sale", "offer", "discount par", "offer par"])
    entities["trending"] = any(word in query_lower for word in ["trending", "trend", "viral", "popular", "best-selling", "best selling", "trend kr"])
    entities["new"] = any(word in query_lower for word in ["new", "launch", "latest", "naya"])
    entities["similar"] = any(word in query_lower for word in ["similar", "like", "same as", "jesa", "similar products"])
    
    # Extract price ranges (handles "500-1000", "under 500", "Rs. 500", "cheaper than")
    price_patterns = [
        r'under\s*(?:rs\.?\s*)?(\d+)',
        r'cheaper\s*than\s*(?:rs\.?\s*)?(\d+)',
        r'below\s*(?:rs\.?\s*)?(\d+)',
        r'upto\s*(?:rs\.?\s*)?(\d+)',
        r'rs\.?\s*(\d+)\s*(?:-|to)\s*(?:rs\.?\s*)?(\d+)',
        r'@\s*(?:rs\.?\s*)?(\d+)',
        r'(\d+)\s*k(?:\s|$)',  # For "2k" meaning 2000
    ]
    
    try:
        for pattern in price_patterns:
            prices = re.findall(pattern, query_lower)
            if prices:
                if isinstance(prices[0], tuple):
                    # Range match
                    min_p = int(prices[0][0])
                    max_p = int(prices[0][1]) if prices[0][1] else min_p * 2
                else:
                    # Single price match
                    price_val = int(prices[0])
                    # If ends with 'k', multiply by 1000
                    if 'k' in query_lower[query_lower.find(prices[0]):query_lower.find(prices[0])+5].lower():
                        price_val *= 1000
                    max_p = price_val
                    min_p = 0
                
                entities["min_price"] = min_p
                entities["max_price"] = max_p
                break
    except:
        pass
    
    # Extract color mentions
    colors = ["red", "blue", "green", "black", "white", "pink", "yellow", "purple", "gold", "silver", "brown", "grey", "gray", "saffron"]
    for color in colors:
        if color in query_lower:
            entities["color"] = color
            break
    
    return entities

def filter_by_price(products: list, min_price: float = None, max_price: float = None) -> list:
    """Filter products by price range."""
    if min_price is None and max_price is None:
        return products
    
    filtered = []
    for p in products:
        price = p.get('price', 0)
        if price == 0:  # Skip products with no price
            continue
        if min_price and price < min_price:
            continue
        if max_price and price > max_price:
            continue
        filtered.append(p)
    
    # If all had zero prices or none matched, return original for UX
    return filtered if filtered else products[:3] if products else []

def filter_by_color(products: list, color: str) -> list:
    """Filter products by color."""
    if not color:
        return products
    
    return [p for p in products if color.lower() in p.get('color', '').lower()]

def filter_by_brand(products: list, brand: str) -> list:
    """Filter products by brand."""
    if not brand:
        return products
    
    return [p for p in products if brand.lower() in p.get('brand', '').lower()]

def get_best_sellers(category: str = None, n_results: int = 5) -> list:
    """Get best-selling products (sorted by popularity/sales)."""
    if collection.count() == 0:
        return []
    
    all_data = collection.get(limit=collection.count(), include=["metadatas"])
    candidates = all_data.get('metadatas', [])
    
    if category:
        candidates = [p for p in candidates if category.lower() in p.get('category', '').lower()]
    
    # Sort by price (common proxy for best-sellers) - newer/featured items often have higher prices
    candidates.sort(key=lambda x: x.get('price', 0), reverse=True)
    return candidates[:n_results]

def search_similar_products(query: str, n_results: int = 5):
    if collection.count() == 0:
        return []
    
    query = normalize_query(query)
    query_lower = query.lower()
    
    # Extract entities for smart filtering
    entities = extract_entities(query)
    
    # Handle special query types
    if entities["trending"]:
        # For trending - return varied/popular items
        return get_best_sellers(n_results=n_results)
    
    # Define broad mappings for Pakistani E-commerce
    broad_mappings = {
        "apparel": ["kurta", "socks", "shoes", "dress", "suit", "kameez", "shalwar", "lawn", "unstitched", "stitched", "pret", "shirt"],
        "jewelry": ["bracelet", "jewelry", "jhumka", "earring", "necklace", "ring", "bangle", "nauratan"],
        "food": ["snack", "dessert", "bites", "chocolate", "cookie", "brownie", "cake"],
        "haircare": ["shampoo", "conditioner", "hair", "oil", "serum"],
        "skincare": ["cream", "serum", "skincare", "lotion", "face", "wash", "moisturizer"],
        "footwear": ["shoe", "sandal", "slipper", "boot", "khussa", "kohlapuri"],
        "wedding": ["formal", "luxury", "chiffon", "embroidered", "bridal", "partywear"]
    }
    
    # 1. Get vector search results
    results = collection.query(
        query_texts=[query],
        n_results=min(n_results * 3, collection.count())
    )
    
    if not results['metadatas'] or not results['metadatas'][0]:
        return []
        
    candidates = results['metadatas'][0]
    
    # 2. Smart Category Filtering
    categories = ["kurta", "bag", "dessert", "snack", "jewelry", "cosmetics", "shoes", "socks", 
                  "bracelet", "apparel", "shampoo", "skincare", "haircare", "cream", "serum",
                  "jhumka", "sandal", "lotion", "oil", "conditioner", "suit", "shirt", "lawn",
                  "unstitched", "pret", "khussa", "wedding", "formal", "kameez", "shalwar"]
    detected_cat = next((cat for cat in categories if cat in query_lower), None)
    
    if detected_cat:
        # If it's a broad category, expand target categories
        targets = broad_mappings.get(detected_cat, [detected_cat])
        
        exact_matches = [
            p for p in candidates 
            if any(t in p.get('category', '').lower() or t in p.get('name', '').lower() for t in targets)
        ]
        
        if exact_matches:
            candidates = exact_matches
    
    # 3. Apply price filtering if specified
    if entities["min_price"] or entities["max_price"]:
        candidates = filter_by_price(candidates, entities["min_price"], entities["max_price"])
    
    # 4. Apply color filtering if specified
    if entities["color"]:
        candidates = filter_by_color(candidates, entities["color"])
    
    return candidates[:n_results] if candidates else []


def get_product_count() -> int:
    """Returns total number of products in the vector DB."""
    return collection.count()

def get_all_categories() -> list:
    """Returns a list of unique categories with counts."""
    count = collection.count()
    if count == 0:
        return []
    
    # Fetch all metadata to extract categories
    all_data = collection.get(limit=count, include=["metadatas"])
    
    category_counts = {}
    for meta in all_data.get('metadatas', []):
        if meta:
            cats = meta.get('category', '')
            for cat in cats.split(', '):
                cat = cat.strip()
                if cat:
                    category_counts[cat] = category_counts.get(cat, 0) + 1
    
    return [{"name": k, "count": v} for k, v in sorted(category_counts.items())]

def search_by_brand(brand: str, n_results: int = 5) -> list:
    """Search products by brand name."""
    if collection.count() == 0:
        return []
    
    # Get all products and filter by brand
    all_data = collection.get(limit=collection.count(), include=["metadatas"])
    candidates = all_data.get('metadatas', [])
    
    results = [p for p in candidates if brand.lower() in p.get('brand', '').lower()]
    return results[:n_results]

def search_by_category(category: str, n_results: int = 5) -> list:
    """Search products by category."""
    if collection.count() == 0:
        return []
    
    query = category.lower()
    
    results = collection.query(
        query_texts=[query],
        n_results=min(n_results * 2, collection.count())
    )
    
    if not results['metadatas'] or not results['metadatas'][0]:
        return []
    
    candidates = results['metadatas'][0]
    filtered = [p for p in candidates if category.lower() in p.get('category', '').lower()]
    
    return filtered[:n_results] if filtered else candidates[:n_results]
