# Web-only runtime runbook (real machine with internet access)

This runbook is for running **backend + frontend dashboard** without Electron.

## 1) Minimal backend dependencies

### A) BASIC mode backend dependencies

Use `requirements-web-basic.txt` for the smallest backend footprint needed to boot the dashboard API in degraded mode:

- `fastapi`
- `uvicorn[standard]`
- `sse-starlette`
- `httpx`
- `psycopg2-binary`
- `pyyaml`
- `python-dotenv`

Install:

```bash
python -m pip install -r requirements-web-basic.txt
```

### B) NORMAL mode backend dependencies

Use `requirements-web.txt` for full dashboard functionality (including model/training routes):

- everything in `requirements-web-basic.txt`
- `numpy`, `pandas`, `scikit-learn`, `xgboost`, `shap`, `matplotlib`, `pyarrow`, `click`, `tqdm`

Install:

```bash
python -m pip install -r requirements-web.txt
```

## 2) Frontend dependencies

Minimal frontend setup:

- Node.js 20+
- npm
- `frontend/package-lock.json` managed dependencies via `npm ci`

Install and run:

```bash
cd frontend
npm ci
npm run dev -- --host 0.0.0.0 --port 5173
```

## 3) Environment variables (minimal)

### Backend basic mode (minimal)

- `DASHBOARD_BASIC_MODE=1`
- `DATABASE_URL` (can be invalid/unreachable in basic mode; app still boots degraded)

Recommended defaults:

```bash
export DATABASE_URL="postgresql://lol_genius:lol_genius_dev@localhost:5432/lol_genius"
export PROXY_URL="http://localhost:8080"
export MODEL_DIR="data/models"
export DDRAGON_CACHE="data/ddragon"
export DASHBOARD_BASIC_MODE=1
```

### Backend normal mode

- `DASHBOARD_BASIC_MODE` unset or `0`
- working `DATABASE_URL` required
- `PROXY_URL`, `MODEL_DIR`, `DDRAGON_CACHE` recommended for full features

## 4) Exact run commands

### Backend (basic mode)

```bash
DASHBOARD_BASIC_MODE=1 python -m lol_genius.dashboard.run
```

### Backend (normal mode)

```bash
python -m lol_genius.dashboard.run
```

### Frontend

```bash
cd frontend
npm ci
npm run dev -- --host 0.0.0.0 --port 5173
```

### Combined helper (already in repo)

```bash
./scripts/web_only_start.sh basic
# or
./scripts/web_only_start.sh both
```

## 5) Behavior expectations

- **Normal mode**: DB init failures stop backend startup.
- **Basic mode**: backend stays up even if DB pool init fails; DB-dependent routes return structured `503` responses.

Example structured response:

```json
{
  "error": "database_unavailable",
  "detail": "Database is unavailable; dashboard is running in basic mode.",
  "basic_mode": true
}
```

## 6) Recommended setup flow on a fresh machine

```bash
# 1) Python backend deps
python -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -r requirements-web-basic.txt   # or requirements-web.txt for full mode

# 2) Backend run (basic first)
DASHBOARD_BASIC_MODE=1 python -m lol_genius.dashboard.run

# 3) Frontend run (new terminal)
cd frontend
npm ci
npm run dev -- --host 0.0.0.0 --port 5173
```
