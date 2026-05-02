import os
import requests
from database import sync_product
from logger import add_log

API_KEY = os.environ.get("FAROKHT_API_KEY", "a8f3c1d9b7e6f4c2a1d0b9c8e7f6a5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9")
HEADERS = {"x-farokht-key": API_KEY}
BASE_URL = "https://svc-frkt-app-x8d4k2.farokht.store/api/v1/ml/datasets"

from concurrent.futures import ThreadPoolExecutor

def sync_page(page, limit):
    url = f"{BASE_URL}/posts?page={page}&limit={limit}"
    try:
        response = requests.get(url, headers=HEADERS, timeout=10)
        response.raise_for_status()
        items = response.json().get('data', [])
        for item in items:
            product = {
                'id': str(item.get('postId', '')),
                'brand': item.get('user', {}).get('brandName', 'Unknown') if item.get('user') else 'Unknown',
                'name': item.get('title', 'Unknown Product'),
                'sku': str(item.get('postId', '')),
                'price': float(item.get('price')) if item.get('price') is not None else 0.0,
                'color': ', '.join(item.get('colors', [])) if item.get('colors') else '',
                'category': ', '.join([c.get('name', '') for c in item.get('categories', [])]) if item.get('categories') else '',
                'image_url': item.get('image', '')
            }
            sync_product(product)
        count = len(items)
        if count > 0:
            add_log(f"✅ Synced page {page} ({count} items)", "sync")
        return count
    except Exception as e:
        add_log(f"❌ Error syncing page {page}: {str(e)[:50]}", "error")
        print(f"Error syncing page {page}: {e}")
        return 0

def fetch_and_sync_posts(limit=250):
    print("Starting concurrent sync for posts...")
    # 1. Fetch first page to see if there's more
    first_page_count = sync_page(1, limit)
    if first_page_count < limit:
        print(f"Synced {first_page_count} products (only 1 page found).")
        return

    # 2. Fetch more pages in parallel (assuming there are more)
    # Since we don't know the exact total, we'll fetch a reasonable batch
    max_pages = 50 # Increased for a much deeper catalog
    with ThreadPoolExecutor(max_workers=8) as executor:
        pages = range(2, max_pages + 1)
        results = list(executor.map(lambda p: sync_page(p, limit), pages))
    
    total = first_page_count + sum(results)
    add_log(f"🎉 Sync completed! Total items: {total}", "system")
    print(f"Concurrent sync completed. Total synced: ~{total}")

def fetch_and_sync_users(limit=100):
    page = 1
    print("Starting sync for users...")
    while True:
        url = f"{BASE_URL}/users?page={page}&limit={limit}"
        try:
            response = requests.get(url, headers=HEADERS)
            response.raise_for_status()
            data = response.json()
            
            items = data.get('data', [])
            if not items:
                break
                
            print(f"Fetched {len(items)} users from page {page}.")
            if len(items) < limit:
                break
            page += 1
        except Exception as e:
            print(f"Error fetching users: {e}")
            break

if __name__ == "__main__":
    fetch_and_sync_posts()
    fetch_and_sync_users()
