@echo off
echo ==============================================
echo Farokht Bot - Data Sync Tool
echo ==============================================

cd backend

if not exist venv\ (
    echo [ERROR] Virtual environment not found. Please run start.bat first to initialize the environment.
    pause
    exit /b 1
)

call venv\Scripts\activate.bat
echo [INFO] Syncing dataset from API into ChromaDB...
py sync_api.py
echo [INFO] Sync completed!
