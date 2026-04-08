# Web-only runbook (Phase A)

This runbook defines the **web-only path** for `lol-genius` without using Electron.

Scope for this phase:
- use the existing React frontend (`frontend/`)
- use the existing FastAPI dashboard backend (`lol_genius.dashboard.*`)
- keep Electron and ML/data pipeline code untouched

## Architecture (web-only)

- Frontend: Vite + React app in `frontend/`
- Backend API: FastAPI app in `lol_genius/dashboard/app.py` exposed at `/api/v1`
- Optional upstream service for Riot lookups/live features: Riot proxy (`PROXY_URL`, default `http://localhost:8080`)
- Data store: PostgreSQL (`DATABASE_URL`)

## Required services and env vars

### Required for backend startup

- Python 3.11+
- Installed Python deps including dashboard extras (FastAPI/uvicorn/sse-starlette)
- `DATABASE_URL` (PostgreSQL DSN)

### Required for full feature set (predict/live endpoints)

- `PROXY_URL` reachable (default `http://localhost:8080`)
- model artifacts under `MODEL_DIR` (default `data/models`)
- champion cache under `DDRAGON_CACHE` (default `data/ddragon`)

### Optional auth and CORS

- `API_KEY` (if set, requires `X-Api-Key` on `/api/v1/*` except `/api/v1/events`)
- `CORS_ALLOWED_ORIGINS` (defaults include `http://localhost:5173` and `http://localhost:3000`)

## Local dev commands (no Docker)

### 1) Backend API

```bash
# from repo root
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dashboard]"

export DATABASE_URL="postgresql://lol_genius:lol_genius_dev@localhost:5432/lol_genius"
export PROXY_URL="http://localhost:8080"           # optional but recommended
export MODEL_DIR="data/models"                      # optional
export DDRAGON_CACHE="data/ddragon"                 # optional

python -m lol_genius.dashboard.run
```

Backend listens on `http://localhost:8081` by default.

### 2) Frontend

```bash
# new terminal
cd frontend
npm ci
npm run dev
```

Frontend listens on `http://localhost:5173` by default and proxies `/api/*` to `http://localhost:8081`.

## Docker commands (web-only service subset)

```bash
cp .env.example .env
# set RIOT_API_KEY and POSTGRES_PASSWORD in .env

docker compose up -d postgres riot-proxy migrate dashboard-api dashboard
```

This intentionally excludes `crawler` and Electron.

## Minimal smoke checks

```bash
# API health-ish check
curl -sf http://localhost:8081/api/v1/model/training-status

# SSE endpoint should respond (stream)
curl -N http://localhost:8081/api/v1/events

# Frontend build check
cd frontend && npm run build
```

## Notes

- If PostgreSQL is unavailable, backend startup or most API routes will fail.
- If `PROXY_URL` is unavailable, lookup/predict/live routes may fail.
- This runbook is Phase A only; no migration/rewrite behavior changes are introduced.
