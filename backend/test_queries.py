#!/usr/bin/env python
"""Test script for enhanced Farokht Bot queries"""
import requests
import json
import time

BASE_URL = "http://localhost:8001"

test_queries = [
    {
        "query": "I'm looking for kurta from Khaadi, do you have it?",
        "lang": "en",
        "description": "Brand-specific product search"
    },
    {
        "query": "Which brands products are currently on discount in haircare?",
        "lang": "en",
        "description": "Discounted products in category"
    },
    {
        "query": "Can you recommend a shoe under Rs. 2000?",
        "lang": "en",
        "description": "Price-filtered recommendation"
    },
    {
        "query": "What are the best-selling products from Khaadi?",
        "lang": "en",
        "description": "Best-sellers from brand"
    },
    {
        "query": "Which products are trending right now?",
        "lang": "en",
        "description": "Trending products"
    },
    {
        "query": "Show me similar products to kurta",
        "lang": "en",
        "description": "Similar products"
    },
    {
        "query": "I want something like kurta but cheaper than Rs. 3000",
        "lang": "en",
        "description": "Budget-friendly alternative"
    },
    {
        "query": "Is waqt pakistan me konsy 4 skincare products trend kr rhy?",
        "lang": "ur",
        "description": "Urdu: Trending skincare products"
    },
    {
        "query": "Mere ammi ko dessan cotton k kurty hi pehanny hoty hain. Koe aisi product hai?",
        "lang": "ur",
        "description": "Urdu: Material-specific search"
    }
]

print("=" * 80)
print("FAROKHT BOT - ADVANCED QUERY TESTING")
print("=" * 80)

for i, test in enumerate(test_queries, 1):
    print(f"\n{'─' * 80}")
    print(f"TEST {i}: {test['description']}")
    print(f"{'─' * 80}")
    print(f"Query: {test['query']}")
    print(f"Language: {test['lang']}")
    
    try:
        data = {
            'message': test['query'],
            'lang': test['lang']
        }
        
        response = requests.post(
            f"{BASE_URL}/chat",
            data=data,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"\n✅ Response Status: OK")
            print(f"\nBot Reply:\n{result['reply']}")
            
            if result['products']:
                print(f"\nProducts Found: {len(result['products'])}")
                for j, product in enumerate(result['products'], 1):
                    print(f"  {j}. {product.get('brand', 'N/A')} - {product.get('name', 'N/A')} (Rs. {product.get('price', 'N/A')})")
            else:
                print("\nNo products found.")
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    time.sleep(0.5)  # Small delay between requests

print(f"\n{'=' * 80}")
print("Testing Complete!")
print(f"{'=' * 80}")
