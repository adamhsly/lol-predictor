#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/frontend"

npm ci
npm run build

echo "Starting Vite dev server for 10s smoke check..."
timeout 10s npm run dev -- --host 0.0.0.0 --port 4173 || true

echo "Frontend smoke checks completed."
