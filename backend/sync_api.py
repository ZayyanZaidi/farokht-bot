import os
import requests
from database import sync_product
from logger import add_log

API_KEY = os.environ.get("FAROKHT_API_KEY", "a8f3c1d9b7e6f4c2a1d0b9c8e7f6a5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9")
HEADERS = {"x-farokht-key": API_KEY}
BASE_URL = "https://svc-frkt-app-x8d4k2.farokht.store/api/v1/ml/datasets"

from concurrent.futures import ThreadPoolExecutor

# Global sync state for visibility
sync_status = {
    "status": "idle", # idle, syncing, completed, error
    "progress": 0,
    "total_pages": 0,
    "items_synced": 0,
    "last_error": None,
    "start_time": None,
    "end_time": None
}

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
            sync_status["items_synced"] += count
            sync_status["progress"] += 1
        return count
    except Exception as e:
        error_msg = str(e)[:100]
        add_log(f"❌ Error syncing page {page}: {error_msg}", "error")
        sync_status["last_error"] = f"Page {page}: {error_msg}"
        print(f"Error syncing page {page}: {e}")
        return 0

def fetch_and_sync_posts(limit=250):
    from datetime import datetime
    print("Starting concurrent sync for posts...")
    
    sync_status["status"] = "syncing"
    sync_status["start_time"] = datetime.now().strftime("%H:%M:%S")
    sync_status["items_synced"] = 0
    sync_status["progress"] = 0
    sync_status["last_error"] = None
    
    # 1. Fetch first page to see if there's more
    first_page_count = sync_page(1, limit)
    if first_page_count < limit:
        print(f"Synced {first_page_count} products (only 1 page found).")
        sync_status["status"] = "completed"
        sync_status["end_time"] = datetime.now().strftime("%H:%M:%S")
        sync_status["total_pages"] = 1
        return

    # 2. Fetch more pages in parallel
    max_pages = 50 
    sync_status["total_pages"] = max_pages
    
    with ThreadPoolExecutor(max_workers=8) as executor:
        pages = range(2, max_pages + 1)
        results = list(executor.map(lambda p: sync_page(p, limit), pages))
    
    total = first_page_count + sum(results)
    sync_status["status"] = "completed"
    sync_status["end_time"] = datetime.now().strftime("%H:%M:%S")
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
