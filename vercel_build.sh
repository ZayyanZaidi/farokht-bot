#!/bin/bash
set -e
export BOT=true
export PUB_ENVIRONMENT=bot

# 1. Install Flutter (stable)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Configure Flutter
echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web
flutter precache --web

# 3. Build the app
echo "Building Flutter Web app..."
cd app

# We run pub get but allow it to continue even if it throws the FormatException 
# because build web will try to resolve it anyway.
flutter pub get || echo "Pub get had some warnings, proceeding to build..."

if [ -z "$BACKEND_URL" ]; then
  BACKEND_URL="https://farokht-bot-backend-784756226072.us-central1.run.app"
fi

# Removed --web-renderer to avoid "Could not find an option" error
flutter build web --release --dart-define=BACKEND_URL=$BACKEND_URL

echo "Build complete."
