#!/bin/bash
set -e

echo "=== MediFlow HMS: Setting up Flutter on Vercel ==="

# Clone Flutter stable if not already available
if [ ! -d "$HOME/flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "Found cached Flutter SDK in $HOME/flutter."
fi

# Add Flutter binary directory to PATH
export PATH="$PATH:$HOME/flutter/bin"

echo "Checking Flutter version..."
flutter --version

echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

echo "Fetching project dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release --no-wasm-dry-run

echo "=== Build finished successfully! Output generated in build/web ==="
