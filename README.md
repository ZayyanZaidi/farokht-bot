# Farokht-Bot E-commerce AI App (Privacy-First Local RAG)

This project consists of a Flutter mobile application and a Dockerized Python FastAPI backend. It features a conversational AI interface using a **locally hosted open-source LLM (Ollama)** and a **Vector Database (ChromaDB)** for a privacy-first, always up-to-date personalized shopping experience.

## Prerequisites
- **Flutter SDK**: Required to build and run the mobile app.
- **Docker & Docker Compose**: Required to run the backend and local LLM services.

## Project Structure
- `/app` - The Flutter mobile application.
- `/backend` - The Python FastAPI backend (with ChromaDB integration).

## 1. Running the Backend (Docker Compose)

The backend now uses Docker Compose to run both the FastAPI server and the local Ollama LLM.

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Build and start the services:
   ```bash
   docker-compose up --build -d
   ```
3. Pull the local LLM model (you only need to do this once). We are using `mistral` by default, but you can change it to `llama3` in `docker-compose.yml` and `main.py`:
   ```bash
   docker exec -it farokht-bot-backend-ollama-1 ollama run mistral
   ```
   *(Note: The container name `farokht-bot-backend-ollama-1` might differ slightly based on your folder name. Use `docker ps` to find the exact name of the Ollama container).*

   The backend API will be running at `http://localhost:8000`.

### Syncing the Database dynamically
You can push new products to your AI bot at any time by sending a POST request to `http://localhost:8000/sync_database` with a JSON payload of the product. The AI will instantly be able to recommend it!

## 2. Running the Frontend (Flutter)

Since this project was initialized with the core Dart files, you need to repair the platform folders before running it.

1. Navigate to the `app` directory:
   ```bash
   cd app
   ```
2. Generate platform folders (Android/iOS):
   ```bash
   flutter create .
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

*Note: If testing on an Android emulator, `http://10.0.2.2:8000` is already configured in `api_service.dart` to reach the local backend. For an iOS simulator, change it to `http://localhost:8000`.*
