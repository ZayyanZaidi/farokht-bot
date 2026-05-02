import os
import json
import random
import threading
import re
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

from datetime import datetime
from logger import add_log, activity_logs
from database import (
    search_similar_products, sync_product, get_all_categories, get_product_count,
    extract_entities, search_by_brand, search_by_category, get_best_sellers, 
    filter_by_price, filter_by_color
)

app = FastAPI(title="Farokht-Bot Advanced RAG Backend")

from fastapi.responses import HTMLResponse

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", response_class=HTMLResponse)
async def root():
    count = get_product_count()
    status_color = "#4CAF50" if count > 0 else "#FF8C00"
    
    logs_html = "".join([
        f'<div style="margin-bottom: 8px; font-size: 13px; color: #fff; opacity: 0.8;">'
        f'<span style="color: #5CE1E6;">[{log["time"]}]</span> {log["event"]}</div>'
        for log in activity_logs[:10]
    ])

    return f"""
    <html>
        <head>
            <title>Farokht Bot | Backend Dashboard</title>
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap" rel="stylesheet">
            <style>
                body {{ 
                    font-family: 'Inter', sans-serif; 
                    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); 
                    color: white; margin: 0; display: flex; justify-content: center; align-items: center; height: 100vh;
                }}
                .card {{
                    background: rgba(255, 255, 255, 0.05);
                    backdrop-filter: blur(20px);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 30px;
                    padding: 40px;
                    width: 450px;
                    text-align: center;
                    box-shadow: 0 25px 50px rgba(0,0,0,0.3);
                }}
                .status-dot {{
                    height: 12px; width: 12px; background: {status_color}; border-radius: 50%; display: inline-block; margin-right: 8px;
                    box-shadow: 0 0 10px {status_color};
                }}
                .count {{ font-size: 64px; font-weight: 700; margin: 20px 0; color: #5CE1E6; }}
                .label {{ font-size: 14px; opacity: 0.6; text-transform: uppercase; letter-spacing: 2px; }}
                .logs {{ text-align: left; background: rgba(0,0,0,0.2); padding: 15px; border-radius: 15px; margin-top: 30px; max-height: 150px; overflow-y: auto; }}
                .btn {{
                    display: inline-block; margin-top: 20px; padding: 12px 25px; background: #FF8C00; color: white; 
                    text-decoration: none; border-radius: 15px; font-weight: bold; transition: 0.3s;
                }}
                .btn:hover {{ transform: scale(1.05); box-shadow: 0 5px 15px rgba(255,140,0,0.4); }}
            </style>
            <meta http-equiv="refresh" content="5">
        </head>
        <body>
            <div class="card">
                <div style="font-weight: bold; font-size: 20px; margin-bottom: 20px;">
                    <span class="status-dot"></span> Farokht Backend Live
                </div>
                <div class="label">Total Products Synced</div>
                <div class="count">{count}</div>
                <div class="label">Latest Activity</div>
                <div class="logs">{logs_html}</div>
                <a href="/debug_sync" class="btn">View Raw Data</a>
            </div>
        </body>
    </html>
    """

@app.on_event("startup")
async def startup_event():
    """Automatically sync products on server startup."""
    from sync_api import fetch_and_sync_posts
    add_log("🚀 Server starting - Auto-sync initiated", "system")
    # Run in thread to not block startup
    thread = threading.Thread(target=fetch_and_sync_posts, daemon=True)
    thread.start()

class Product(BaseModel):
    id: str
    brand: str
    name: str
    sku: str
    price: float
    color: Optional[str] = None
    category: str
    image_url: str

class ChatResponse(BaseModel):
    reply: str
    products: List[dict] = []

@app.post("/sync_database")
async def sync_database_endpoint(product: Product):
    sync_product(product.dict())
    add_log(f"Synced product: {product.name}", "sync")
    return {"status": "success", "message": f"Product {product.id} synced to Vector DB."}

@app.get("/stats")
async def get_stats():
    """Returns product count and available categories for the home screen."""
    count = get_product_count()
    categories = get_all_categories()
    return {
        "product_count": count,
        "categories": categories,
        "status": "healthy"
    }

@app.get("/categories")
async def get_categories():
    """Returns category list with counts for the home screen chips."""
    categories = get_all_categories()
    return {"categories": categories}

@app.get("/products")
async def get_products(limit: int = 10, offset: int = 0):
    """Returns a paginated list of products for the home screen catalog."""
    count = get_product_count()
    products = search_similar_products("a", n_results=limit)
    return {"products": products, "total": count}

@app.post("/sync_trigger")
async def trigger_sync():
    """Triggers a background data sync from the Farokht API."""
    try:
        from sync_api import fetch_and_sync_posts
        add_log("🔄 Manual Sync Triggered", "sync")
        
        def run_sync():
            try:
                fetch_and_sync_posts()
                add_log("✅ Database Sync Completed", "sync")
            except Exception as e:
                add_log(f"❌ Sync Error: {str(e)}", "error")

        thread = threading.Thread(target=run_sync, daemon=True)
        thread.start()
        return {"status": "started", "message": "Product sync started in background."}
    except Exception as e:
        add_log(f"Failed to start sync: {str(e)}", "error")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/live_activity")
async def get_live_activity():
    """Returns the latest system activity logs."""
    return {"logs": activity_logs[:20]}

def detect_intent(message: str) -> str:
    """Detect the intent of the user's message - prioritize search over generic intents."""
    msg_lower = message.lower()
    
    # Check for search-related keywords first (these have priority)
    search_keywords = ["looking for", "show me", "find", "do you have", "can you", "which", 
                       "what are", "recommend", "trending", "discount", "sale", "similar"]
    if any(keyword in msg_lower for keyword in search_keywords):
        return "search"
    
    # If no search keywords, check for other intents (only if message is short)
    if len(msg_lower.split()) < 5:
        intents = {
            "greeting": ["hello", "hi", "hey", "assalam", "salam", "aoa", "adaab"],
            "thanks": ["thank", "shukria", "shukriya", "meherbani", "jazakallah"],
            "bot_identity": ["who are you", "aap kon", "your name", "what are you"],
            "help": ["help", "madad", "guide", "how to", "what can you do"],
        }
        
        for intent, keywords in intents.items():
            if any(word in msg_lower for word in keywords):
                return intent
    
    # Default to search for longer messages or messages with search terms
    return "search"

def generate_custom_response(message: str, products: List[dict], lang: str = "auto") -> str:
    """Generate contextual response based on query intent and products found."""
    
    # Auto-detect language if not specified
    if lang == "auto":
        lang = "en"
        # Simple detection: if message has Urdu script characters
        if any('\u0600' <= c <= '\u06FF' for c in message):
            lang = "ur"
    
    msg_lower = message.lower()
    intent = detect_intent(message)
    
    # Extract entities for context
    entities = extract_entities(message)
    
    # Response templates for different intents and languages
    templates = {
        "en": {
            "greeting": [
                "Hello! 👋 Welcome to Farokht. What would you like to find today?",
                "Hi there! I'm here to help you find amazing products. What are you looking for?"
            ],
            "thanks": [
                "You're very welcome! Let me know if you need anything else. 😊",
                "Anytime! Feel free to ask if you need more help."
            ],
            "bot": "I'm Farokht AI, your personal shopping assistant. I can help you find the best products and deals in Pakistan!",
            "help": "You can search for products like 'kurtas', 'bags', or specific brands. I can also help with price filters and recommendations!",
            "search_intros": [
                "Great! I found some amazing options for you:",
                "Perfect! Here's what I found:",
                "Excellent choice! Check these out:"
            ],
            "search_outros": [
                "Would you like to see more options?",
                "Can I help you with anything else?",
                "Would you like to add any of these to your cart?"
            ],
            "not_found": "Sorry, I couldn't find exactly what you're looking for. Try searching for a different product or brand!",
            "discount": "Great! Here are some discounted items for you:",
            "trending": "These are trending right now in Pakistan! 🔥",
            "similar": "Here are similar products you might like:",
            "price_filter": "Here are products within your budget:"
        },
        "ur": {
            "greeting": [
                "السلام علیکم! 👋 Farokht میں خوش آمدید۔ آج آپ کیا ڈھونڈنا چاہتے ہیں؟",
                "ہیلو! میں آپ کو بہترین پروڈکٹس تلاش کرنے میں مدد کر سکتا ہوں۔"
            ],
            "thanks": [
                "آپ کا بہت شکریہ! اگر مزید کچھ چاہیے تو ضرور بتائیں۔ 😊",
                "کسی بھی وقت! مزید مدد کے لیے بیجھک پوچھیں۔"
            ],
            "bot": "میں Farokht AI ہوں، آپ کا ذاتی شاپنگ اسسٹنٹ۔ میں آپ کو پاکستان کے بہترین پروڈکٹس اور ڈیلز تلاش کرنے میں مدد کر سکتا ہوں!",
            "help": "آپ 'کرتے'، 'بیگ' یا مخصوص برانڈز کے لیے تلاش کر سکتے ہیں۔ میں قیمت کی فلٹرنگ میں بھی مدد کر سکتا ہوں!",
            "search_intros": [
                "شاندار! میں نے آپ کے لیے کچھ خوبصورت اختیارات ڈھونڈے ہیں:",
                "بہترین! یہ ہے جو میں نے ڈھونڈا:",
                "شاندار پسند! ان کو دیکھیں:"
            ],
            "search_outros": [
                "کیا آپ مزید اختیارات دیکھنا چاہتے ہیں؟",
                "کیا میں آپ کی مزید مدد کر سکتا ہوں؟",
                "کیا آپ ان میں سے کوئی اپنی کارٹ میں شامل کرنا چاہتے ہیں؟"
            ],
            "not_found": "معاف کریں، مجھے بالکل وہی نہیں ملا جو آپ تلاش کر رہے ہیں۔ کسی اور پروڈکٹ یا برانڈ کے لیے کوشش کریں!",
            "discount": "بہترین! یہاں آپ کے لیے ڈسکاؤنٹ کی چیزیں ہیں:",
            "trending": "یہ ابھی پاکستان میں ٹریند کر رہے ہیں! 🔥",
            "similar": "یہ اسی طرح کی پروڈکٹس ہیں جو آپ کو پسند آ سکتی ہیں:",
            "price_filter": "یہاں آپ کے بجٹ میں پروڈکٹس ہیں:"
        }
    }
    
    current_temp = templates.get(lang, templates["en"])
    
    # 1. Handle non-search intents first
    if intent == "greeting":
        return random.choice(current_temp["greeting"])
    elif intent == "thanks":
        return random.choice(current_temp["thanks"])
    elif intent == "bot_identity":
        return current_temp["bot"]
    elif intent == "help":
        return current_temp["help"]
    
    # 2. No products found
    if not products:
        return current_temp["not_found"]
    
    # 3. Product search response with context
    intro_key = "search_intros"
    
    if entities["discount"]:
        intro_key = "discount"
    elif entities["trending"]:
        intro_key = "trending"
    elif entities["similar"]:
        intro_key = "similar"
    elif entities["min_price"] or entities["max_price"]:
        intro_key = "price_filter"
    
    # Build response with products
    if isinstance(current_temp[intro_key], list):
        reply = random.choice(current_temp[intro_key]) + "\n\n"
    else:
        reply = current_temp[intro_key] + "\n\n"
    
    for i, p in enumerate(products, 1):
        price = p.get('price', 'N/A')
        brand = p.get('brand', 'Unknown')
        name = p.get('name', 'Product')
        reply += f"{i}. 🛍️ {brand} - {name}\n   Rs. {price}"
        if p.get('color'):
            reply += f" | {p.get('color')}"
        reply += "\n"
    
    reply += "\n" + random.choice(current_temp["search_outros"])
    return reply

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(
    message: str = Form(...),
    lang: str = Form("auto"),
    image: Optional[UploadFile] = File(None)
):
    """Enhanced chat endpoint with intelligent query handling."""
    # Extract entities to determine search strategy
    entities = extract_entities(message)
    
    # Intelligent product search based on query type
    if "brand" in message:
        # Search by brand if brand is mentioned
        relevant_products = search_by_brand(message.split("from")[-1].strip() if "from" in message else message, n_results=5)
    elif entities["trending"]:
        # Get trending/best-selling products
        relevant_products = get_best_sellers(n_results=5)
    elif entities["discount"]:
        # For discount queries, return products (in real app, would check discount status)
        relevant_products = search_similar_products(message, n_results=5)
    else:
        # Default semantic search
        relevant_products = search_similar_products(message, n_results=5)
    
    # Apply additional filters if specified
    if entities["min_price"] or entities["max_price"]:
        relevant_products = filter_by_price(relevant_products, entities["min_price"], entities["max_price"])
    
    if entities["color"]:
        relevant_products = filter_by_color(relevant_products, entities["color"])
    
    reply = generate_custom_response(message, relevant_products, lang=lang)
    
    add_log(f"Processed: '{message[:30]}...' Intent: search", "chat")
        
    return ChatResponse(reply=reply.strip(), products=relevant_products)

@app.get("/debug_sync")
def debug_sync():
    """Debug endpoint to verify synced products."""
    count = get_product_count()
    # Get a sample of products
    sample = search_similar_products("a", n_results=5) 
    return {
        "total_count": count,
        "sample_products": sample,
        "logs": activity_logs[:10]
    }

@app.get("/health")
def health_check():
    count = get_product_count()
    return {"status": "healthy", "product_count": count}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
