#!/bin/bash
set -e
export BOT=true
export PUB_ENVIRONMENT=bot
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --no-analytics
flutter config --enable-web
flutter --version
cd app
# flutter pub get # Skipping separate pub get to bypass advisories bug
if [ -z "$BACKEND_URL" ]; then
  BACKEND_URL="https://farokht-bot-backend-784756226072.us-central1.run.app"
fi
flutter build web --release --web-renderer html --dart-define=BACKEND_URL=$BACKEND_URL
