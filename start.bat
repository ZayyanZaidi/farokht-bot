@echo off
echo ==============================================
echo Farokht Bot - Local Environment Startup
echo ==============================================

cd backend

if not exist venv\ (
    echo [INFO] Virtual environment not found. Creating one...
    py -m venv venv
    echo [INFO] Installing dependencies...
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
) else (
    call venv\Scripts\activate.bat
)

echo [INFO] Starting FastAPI server...
uvicorn main:app --reload --host 0.0.0.0 --port 8000
