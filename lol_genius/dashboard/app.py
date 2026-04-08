from __future__ import annotations

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from lol_genius.db.connection import create_pool

log = logging.getLogger(__name__)

_API_KEY = os.environ.get("API_KEY", "")


@asynccontextmanager
async def lifespan(app: FastAPI):
    dsn = os.environ.get("DATABASE_URL", "")
    proxy_url = os.environ.get("PROXY_URL", "http://localhost:8080")
    model_dir = os.environ.get("MODEL_DIR", "data/models")
    ddragon_cache = os.environ.get("DDRAGON_CACHE", "data/ddragon")
    basic_mode = os.environ.get("DASHBOARD_BASIC_MODE", "0") == "1"

    pool = None
    db_ready = False
    try:
        pool = create_pool(dsn, minconn=1, maxconn=5)
        db_ready = True
    except Exception:
        if not basic_mode:
            raise
        log.exception("Dashboard API starting in basic mode (database unavailable)")

    app.state.pool = pool
    app.state.db_ready = db_ready
    app.state.basic_mode = basic_mode
    app.state.dsn = dsn
    app.state.proxy_url = proxy_url
    app.state.model_dir = model_dir
    app.state.ddragon_cache = ddragon_cache

    if db_ready:
        log.info(f"Dashboard API started: pool created, proxy={proxy_url}")
    else:
        log.info(f"Dashboard API started in basic mode: proxy={proxy_url}")
    yield
    if pool is not None:
        pool.closeall()
    log.info("Dashboard API shut down")


app = FastAPI(title="lol-genius dashboard", lifespan=lifespan)

_cors_raw = os.environ.get("CORS_ALLOWED_ORIGINS", "http://localhost:5173,http://localhost:3000")
_cors_origins = [o.strip() for o in _cors_raw.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

from lol_genius.dashboard.api import router  # noqa: E402

app.include_router(router, prefix="/api/v1")


@app.middleware("http")
async def api_key_middleware(request: Request, call_next):
    if (
        _API_KEY
        and request.url.path.startswith("/api/v1/")
        and not request.url.path.startswith("/api/v1/events")
    ):
        if request.headers.get("X-Api-Key") != _API_KEY:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
    return await call_next(request)
