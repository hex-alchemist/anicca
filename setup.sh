#!/usr/bin/env bash
# Anicca — project setup
# Generates the Xcode project from project.yml using xcodegen.

set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  cat <<EOF
xcodegen is not installed.

Install it with one of:
  brew install xcodegen
  mint install yonaskolb/xcodegen

Then re-run: ./setup.sh
EOF
  exit 1
fi

if [ ! -f Secrets.xcconfig ]; then
  echo "Copying Secrets.xcconfig.example -> Secrets.xcconfig"
  cp Secrets.xcconfig.example Secrets.xcconfig
  echo "  Fill in your real keys before building."
fi

xcodegen generate

echo ""
echo "✦ Project generated: Anicca.xcodeproj"
echo "  Open with: open Anicca.xcodeproj"
echo ""
echo "Next steps:"
echo "  1. Fill in Secrets.xcconfig with your real API keys"
echo "  2. Run the SQL from Anicca/Resources/SupabaseSetup.md in your Supabase project"
echo "  3. Configure RevenueCat entitlements and products"
echo "  4. Open Anicca.xcodeproj, select your team in Signing & Capabilities, and Run"
