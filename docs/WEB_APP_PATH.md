# Web-only runtime runbook (local + Railway)

This project can run as **web-only** (FastAPI backend + React frontend) without Electron.

## Backend dependencies (minimal)

Install with:

```bash
python -m pip install -r requirements-web.txt
```

`requirements-web.txt` includes only the minimal runtime set for dashboard service startup and core API handling.

## Frontend dependencies (minimal)

```bash
cd frontend
npm ci
```

## Environment variables (minimal)

### Required for Railway/basic startup

- `DASHBOARD_BASIC_MODE=1` (recommended on first deploy if DB is not ready)

### Optional in basic mode

- `DATABASE_URL` (optional in basic mode; if missing/unreachable backend stays up degraded)

### Required for normal mode

- `DATABASE_URL` (reachable PostgreSQL DSN)

### Optional but useful

- `PROXY_URL` (default: `http://localhost:8080`)
- `MODEL_DIR` (default: `data/models`)
- `DDRAGON_CACHE` (default: `data/ddragon`)
- `API_KEY` (optional header auth)

## Local run commands

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
npm run dev -- --host 0.0.0.0 --port 5173
```

### Combined helper

```bash
./scripts/web_only_start.sh basic
# or
./scripts/web_only_start.sh both
```

## Railway deployment steps

Deploy as **two services**.

### Service A: Backend API (repo root)

1. Create Railway service from repo root.
2. Railway uses `railway.toml` at root.
3. Set environment variables:
   - `DASHBOARD_BASIC_MODE=1` (initially)
   - `DATABASE_URL` (set when DB is provisioned/ready)
4. After DB is healthy, you may set `DASHBOARD_BASIC_MODE=0` or remove it.

Health check endpoint:

```bash
GET /api/v1/system/health
```

### Service B: Frontend (frontend/)

1. Create second Railway service with root directory set to `frontend`.
2. Railway uses `frontend/railway.toml`.
3. Ensure frontend can reach backend:
   - set `VITE_API_BASE_URL` to backend URL + `/api/v1` if not same-origin/proxied.

Example:

```bash
VITE_API_BASE_URL=https://your-backend.up.railway.app/api/v1
```

## Notes

- Backend binds `0.0.0.0` and reads Railway `PORT` automatically.
- In basic mode, DB-dependent endpoints return structured `503` responses instead of crashing startup.
