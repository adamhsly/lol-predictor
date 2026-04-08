.PHONY: web-install-basic web-install web-backend web-backend-basic web-frontend web-dev

web-install-basic:
	python -m pip install -r requirements-web-basic.txt

web-install:
	python -m pip install -r requirements-web.txt

web-backend:
	python -m lol_genius.dashboard.run

web-backend-basic:
	DASHBOARD_BASIC_MODE=1 python -m lol_genius.dashboard.run

web-frontend:
	cd frontend && npm ci && npm run dev -- --host 0.0.0.0 --port 5173

web-dev:
	./scripts/web_only_start.sh both
