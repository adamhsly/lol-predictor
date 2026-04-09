#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-both}" # api|frontend|both|basic

run_api() {
  cd "$ROOT_DIR"
  : "${DATABASE_URL:=postgresql://lol_genius:lol_genius_dev@localhost:5432/lol_genius}"
  : "${PROXY_URL:=http://localhost:8080}"
  : "${MODEL_DIR:=data/models}"
  : "${DDRAGON_CACHE:=data/ddragon}"
  : "${DASHBOARD_BASIC_MODE:=0}"

  export DATABASE_URL PROXY_URL MODEL_DIR DDRAGON_CACHE DASHBOARD_BASIC_MODE

  echo "[web-only] starting dashboard API on :8081"
  python -m lol_genius.dashboard.run
}

run_frontend() {
  cd "$ROOT_DIR/frontend"
  echo "[web-only] starting frontend dev server on :5173"
  npm run dev
}

case "$MODE" in
  api)
    run_api
    ;;
  frontend)
    run_frontend
    ;;
  both)
    run_api &
    API_PID=$!
    trap 'kill "$API_PID" >/dev/null 2>&1 || true' EXIT
    run_frontend
    ;;
  basic)
    export DASHBOARD_BASIC_MODE=1
    run_api &
    API_PID=$!
    trap 'kill "$API_PID" >/dev/null 2>&1 || true' EXIT
    run_frontend
    ;;
  *)
    echo "Usage: $0 [api|frontend|both|basic]"
    exit 1
    ;;
esac
