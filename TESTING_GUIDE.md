# Farokht Bot - Enhanced Query Handling Guide

## 🚀 What's New

The Farokht Bot backend has been significantly upgraded with improved query handling capabilities. Here's what you can now do:

### Supported Query Types

#### 1. **Brand-Specific Product Search**
```
"I'm looking for kurta from Khaadi, do you have it?"
"Show me Khaadi products"
"Does Bareilly Baazar have any jewelry?"
```

#### 2. **Category & Discount Searches**
```
"Which brands have products on discount?"
"Show me discounted shoes"
"Sale items in bag category"
```

#### 3. **Price-Filtered Recommendations**
```
"Can you recommend a shoe under Rs. 2000?"
"I want something cheaper than Rs. 3000"
"Find kurtas between 2000-4000"
"What's available for 500"
```

#### 4. **Trending & Best-Sellers**
```
"What are the best-selling products?"
"Which products are trending right now?"
"What's viral in Pakistan right now?"
"Show me popular items"
```

#### 5. **Similar Products**
```
"Show me similar products to kurta"
"Find alternatives to this bag"
"What's like this product?"
```

#### 6. **Color & Specification Filtering**
```
"Show me black shoes"
"Red kurtas please"
"I need blue bags"
"Cotton material kurtas"
```

#### 7. **Multi-Language Support (English & Urdu)**
```
English: "What are the best kurtas for summer?"
Urdu: "بہترین کرتے کون سے ہیں؟"
Urdu Roman: "Is waqt skincare products konse trend kr ry hain?"
```

---

## 🧪 Testing the Backend

### Backend Health Check
```bash
curl http://localhost:8001/health
```

### Test a Simple Query
```bash
curl -X POST "http://localhost:8001/chat" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "message=show me kurtas&lang=en"
```

### Run Full Test Suite
```bash
cd backend
python test_queries.py
```

---

## 📊 Response Improvements

### Enhanced Intent Detection
- ✅ Properly distinguishes greetings from product searches
- ✅ Prioritizes search intent over generic responses
- ✅ Recognizes trending/discount keywords

### Smart Entity Extraction
- ✅ Extracts price ranges (Rs. 2000, under 500, 2k-4k)
- ✅ Identifies color preferences
- ✅ Detects category from query text
- ✅ Recognizes discount/trending/sale keywords

### Contextual Filtering
- ✅ Filters products by price range
- ✅ Filters by color when specified
- ✅ Category-aware searches
- ✅ Broad category expansion (apparel → kurtas, socks, shoes)

---

## 🔧 Backend Configuration

### Key Improvements Made

1. **database.py**
   - Added `extract_entities()` - Extracts brand, price, color, intent
   - Added `filter_by_price()` - Smart price range filtering
   - Added `filter_by_color()` - Color-based product filtering
   - Added `search_by_brand()` - Brand-specific searches
   - Added `get_best_sellers()` - Trending/popular products
   - Enhanced `search_similar_products()` - Category awareness

2. **main.py**
   - Added `detect_intent()` - Improved intent detection
   - Added `generate_custom_response()` - Contextual responses
   - Enhanced `/chat` endpoint with entity extraction
   - Multi-language template support (English & Urdu)
   - Response customization based on query intent

---

## 🌐 API Endpoints

### POST /chat
Send a query and get products with AI response

**Request:**
```json
{
  "message": "show me red kurtas under Rs. 3000",
  "lang": "en"
}
```

**Response:**
```json
{
  "reply": "Here are products within your budget:\n\n1. 🛍️ Brand - Product Name...",
  "products": [
    {
      "id": "123",
      "brand": "Khaadi",
      "name": "Red Silk Kurta",
      "price": 2500,
      "color": "red",
      "category": "kurta"
    }
  ]
}
```

### GET /stats
Get product count and categories

### GET /health
Check backend health status

### GET /debug_sync
View sample synced products and sync logs

---

## 🎯 Sample Queries & Expected Results

| Query | Type | Expected Behavior |
|-------|------|-------------------|
| "Hello!" | Greeting | Returns greeting response |
| "Show me kurtas" | Search | Returns relevant products |
| "Under 2000" | Price Filter | Filters to budget products |
| "Trending now" | Trending | Returns popular products |
| "Red shoes" | + Color | Filters by color |
| "From Khaadi" | Brand Specific | Searches specific brand |
| "Similar to kurta" | Similar | Finds similar items |

---

## 📱 Flutter App Integration

The Flutter app communicates with the backend via the `/chat` endpoint.

### Key Configuration
- **Backend URL:** `https://farokht-bot-backend-784756226072.us-central1.run.app`
- **Fallback (Local):** `http://localhost:8001`
- **Configurable via:** App Settings → Server URL

### Testing from App
1. Open the Farokht Bot app
2. Type any of the sample queries above
3. View the response and products in the chat interface
4. Theme and UI remain unchanged

---

## 🐛 Troubleshooting

### Query Returns No Results
- Check if the product exists in the database (view /debug_sync)
- Try a broader search term
- Check if category has products

### Price Not Filtering Correctly
- Ensure price format is clear (e.g., "under 2000" not "2000" alone)
- Check if products in that range exist

### Language Not Detected
- Explicitly set `lang` parameter: `en` or `ur`
- Use standard Urdu script (not colloquial)

---

## 📈 Future Enhancements

- [ ] Brand-specific discount detection
- [ ] Size/quantity variations
- [ ] Stock availability real-time check
- [ ] User preference learning
- [ ] Image-based search
- [ ] More language support (Punjabi, Balochi)
- [ ] Advanced filters (material, occasion, etc.)

