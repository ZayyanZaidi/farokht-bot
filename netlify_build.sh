#!/bin/bash

# 1. Install Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Build the app
cd app
flutter pub get
flutter build web --release --web-renderer html
