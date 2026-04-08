# Web-only runtime path

This project can run as backend + frontend without Electron.

## Basic mode

Set `DASHBOARD_BASIC_MODE=1` to allow the dashboard API to stay up in degraded mode if DB pool initialization fails.

- Normal mode (default): startup fails if DB is unavailable.
- Basic mode: startup continues; DB-dependent endpoints return structured `503` responses.

## Quick commands

```bash
# Backend + frontend (normal mode)
./scripts/web_only_start.sh both

# Backend + frontend (basic/degraded mode)
./scripts/web_only_start.sh basic
```

## Structured DB-unavailable response

```json
{
  "error": "database_unavailable",
  "detail": "Database is unavailable; dashboard is running in basic mode.",
  "basic_mode": true
}
```
