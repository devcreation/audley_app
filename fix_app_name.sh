#!/bin/bash
# Run this ONCE inside your Flutter project root after copying the lib/ folder
# It permanently changes the app name in Android and iOS native config files

echo "Installing rename tool..."
dart pub add rename --dev
echo ""
echo "Setting app name..."
dart run rename setAppName --targets android,ios --value "Audley's Top Performers Incentive"
echo ""
echo "Done! Rebuild the app: flutter run"
