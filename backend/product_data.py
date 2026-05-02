MOCK_PRODUCTS = [
    {
        "id": "1",
        "brand": "Khaadi",
        "name": "Embroidered | Raw Silk",
        "sku": "ESS24533B",
        "price": 5499,
        "color": "red",
        "category": "kurta",
        "image_url": "https://imgur.com/placeholder1.jpg",
    },
    {
        "id": "2",
        "brand": "Khaadi",
        "name": "Embroidered | Raw Silk",
        "sku": "EST24565B",
        "price": 8299,
        "color": "red",
        "category": "kurta",
        "image_url": "https://imgur.com/placeholder2.jpg",
    },
    {
        "id": "3",
        "brand": "Lo-Kal Bites",
        "name": "LB Chocolate Fudge Brownie",
        "sku": "LKB-001",
        "price": 599,
        "category": "dessert",
        "image_url": "https://imgur.com/placeholder3.jpg",
    },
    {
        "id": "4",
        "brand": "Lo-Kal Bites",
        "name": "LB Brownie Bites",
        "sku": "LKB-002",
        "price": 399,
        "category": "dessert",
        "image_url": "https://imgur.com/placeholder4.jpg",
    },
    {
        "id": "5",
        "brand": "Lo-Kal Bites",
        "name": "LB Protein Power Balls",
        "sku": "LKB-003",
        "price": 799,
        "category": "snack",
        "image_url": "https://imgur.com/placeholder5.jpg",
    },
    {
        "id": "6",
        "brand": "Lo-Kal Bites",
        "name": "LB Double Chocolate Chunk Cookie",
        "sku": "LKB-004",
        "price": 899,
        "category": "dessert",
        "image_url": "https://imgur.com/placeholder6.jpg",
    },
    {
        "id": "7",
        "brand": "Astore",
        "name": "Cruise Bag Brown",
        "sku": "AST-001",
        "price": 1499,
        "color": "brown",
        "category": "bag",
        "image_url": "https://imgur.com/placeholder7.jpg",
    },
    {
        "id": "8",
        "brand": "Astore",
        "name": "Cruise Bag Green",
        "sku": "AST-002",
        "price": 1499,
        "color": "green",
        "category": "bag",
        "image_url": "https://imgur.com/placeholder8.jpg",
    },
    {
        "id": "9",
        "brand": "Astore",
        "name": "Cruise Bag Peach",
        "sku": "AST-003",
        "price": 1499,
        "color": "peach",
        "category": "bag",
        "image_url": "https://imgur.com/placeholder9.jpg",
    }
]

def search_products(query: str):
    query = query.lower()
    results = []
    for product in MOCK_PRODUCTS:
        if (query in product["name"].lower() or 
            query in product["brand"].lower() or 
            query in product["category"].lower() or
            (product.get("color") and query in product["color"].lower())):
            results.append(product)
    
    # Simple keyword matching fallback
    if not results:
        if "bag" in query:
            results = [p for p in MOCK_PRODUCTS if p["category"] == "bag"]
        elif "brownie" in query or "sugar-free" in query or "dessert" in query:
            results = [p for p in MOCK_PRODUCTS if p["brand"] == "Lo-Kal Bites"]
        elif "kurta" in query or "red" in query:
            results = [p for p in MOCK_PRODUCTS if p["brand"] == "Khaadi"]
            
    return results
