# Codex Runtime Audit (2026-04-08)

This audit focuses on making the repository understandable and runnable **inside the Codex container** before any rewrite/migration work.

## 1) Current architecture

The repository is a **mixed system** with four major runtime surfaces:

1. **Python data/ML backend (`lol_genius/`)**
   - CLI-driven data pipeline (`seed`, `crawl`, `build-features`, `train`, etc.).
   - FastAPI services for dashboard API and Riot proxy.
   - PostgreSQL-backed storage + SQL migrations via `dbmate`.
2. **Web dashboard frontend (`frontend/`)**
   - React + Vite SPA, expecting backend API at `/api/v1/*`.
3. **Electron desktop app (`electron-app/`)**
   - Separate React renderer + Electron main process + ONNX runtime native module.
4. **Containerized orchestration (`docker-compose.yml`)**
   - Brings up Postgres, migrations, proxy, crawler, dashboard API, dashboard UI.

## 2) Command validation in Codex

### Environment facts in this container

- Python: `3.10.19` default; `3.12.3` available.
- Node: `v22.21.1`, npm: `11.4.2`.
- Docker CLI/daemon: **not installed**.
- Outbound package fetch for Python is blocked by proxy in this environment.
- Some npm installs work (frontend), but Electron native downloads are blocked.

### Commands tested

#### A. Works

- `cd frontend && npm ci`
  - Installed frontend dependencies successfully.
- `cd frontend && npm run build`
  - Build succeeds and outputs `frontend/dist/`.
- `cd frontend && timeout 20s npm run dev -- --host 0.0.0.0 --port 4173`
  - Dev server starts successfully (timeout used to terminate after verification).

#### B. Fails (environment constraints, not code bugs)

- `python3.12 -m venv .venv && source .venv/bin/activate && pip install -e '.[test,dashboard]'`
  - Fails due to package index/proxy access (`setuptools>=68.0` fetch fails).
- `uv sync --no-dev`
  - Fails fetching `https://pypi.org/simple/...` through tunnel/proxy.
- `cd electron-app && npm ci`
  - Fails installing `onnxruntime-node` due network reachability (`ENETUNREACH`).
- `docker --version` / `docker compose version`
  - Fails because Docker is unavailable in Codex container.

## 3) Missing dependencies / env vars

### Required env vars

From `.env.example` and config loading behavior:

- `RIOT_API_KEY` (required unless `RIOT_PROXY_URL` is set).
- `DATABASE_URL` (required for DB-backed operations).
- `POSTGRES_PASSWORD` (for Docker Compose postgres setup).

### Non-Python tooling dependencies

- `dbmate` required by `lol-genius init-db` command.
- PostgreSQL server required for most CLI flows (`seed/crawl/build-features/train`).
- Docker required if using compose-based quickstart.

### Python package/runtime requirements

- Project requires Python `>=3.11` (`pyproject.toml`), while Codex default python is `3.10`; must use `python3.12` in this container.
- Core Python deps include `fastapi`, `uvicorn`, `python-dotenv`, `xgboost`, etc.; installation currently blocked by network policy.

## 4) What type of app is this?

This is a **mixed application**, not a single-mode app:

- **Electron desktop app** for live in-game predictions.
- **Web app** (React frontend + FastAPI backend) for dashboarding/training/status.
- **Backend data pipeline** (crawler/feature engineering/model training).

If forced to pick a "primary" shape by code volume and operational intent, it is a **data+backend platform with two UIs (web + Electron)**.

## 5) Migration plan to convert into a web app (no rewrite yet)

### Phase 0 — Stabilize current web runtime (now)

1. Keep `frontend/` + `dashboard/` as canonical web path.
2. Ensure every Electron-only capability has an API equivalent in FastAPI (or mark unsupported).
3. Document one local-start script for web-only mode.

### Phase 1 — Define boundaries

1. Extract shared domain modules:
   - model inference
   - live game polling abstractions
   - champion/stat transforms
2. Create a clear service contract for `/api/v1` that fully serves current frontend pages.

### Phase 2 — Port Electron-only features to backend APIs

1. Move LCU polling and live inference orchestration from Electron main process into backend workers.
2. Replace IPC contracts with HTTP/SSE/WebSocket contracts.
3. Keep ONNX inference server-side (or in sidecar) to avoid browser-native limitations.

### Phase 3 — Web UX parity

1. Rebuild Electron renderer screens as web routes/components.
2. Use SSE/WebSocket for live updates already patterned in frontend hooks.
3. Add auth/session model if exposing outside localhost.

### Phase 4 — Packaging and ops

1. Standardize web deployment (Docker Compose for dev; container stack for prod).
2. Add CI jobs for:
   - backend unit tests
   - frontend build/tests
   - API contract checks
3. Mark Electron as optional/legacy once parity is reached.

### Phase 5 — Decommission strategy

1. Freeze Electron feature development.
2. Keep Electron bugfix-only for one transition window.
3. Remove Electron build/release pipeline after agreed cutoff.

---

## Practical "runnable in Codex" status right now

- ✅ Frontend can be installed and built in Codex.
- ✅ Frontend dev server runs in Codex.
- ⚠️ Backend and CLI are blocked by Python package network restrictions + missing DB services.
- ⚠️ Electron is blocked by native dependency download restrictions.

This means the immediate Codex-usable target is: **frontend-only smoke workflow**, with backend/electron validated in a less restricted environment.
