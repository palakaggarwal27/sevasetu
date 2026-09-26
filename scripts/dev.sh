#!/bin/sh
# =====================================================================
# SevaSetu — macOS / Linux daily launcher
# Starts the FastAPI backend (venv) + Vite frontend dev server.
#   sh ./scripts/dev.sh
# Stop both servers with Ctrl+C.
# =====================================================================
set -e
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -x "venv/bin/python" ]; then
    echo "ERROR: venv not found. Run 'sh ./scripts/setup.sh' first." >&2
    exit 1
fi
if [ ! -f ".env" ]; then
    echo "ERROR: .env not found. Run 'sh ./scripts/setup.sh' first, then set DATABASE_URL." >&2
    exit 1
fi

BACKEND_PORT=8000
FRONTEND_PORT=5173

echo ""
echo "=== SevaSetu Dev Launcher (macOS / Linux) ==="

# ── Backend: uvicorn with auto-reload on port 8000 ────────────────
echo "[*] Starting backend: http://127.0.0.1:$BACKEND_PORT  (Swagger: /docs)"
"venv/bin/python" -m uvicorn backend.main:app --host 127.0.0.1 --port "$BACKEND_PORT" --reload &
BACKEND_PID=$!

cleanup() {
    if kill -0 "$BACKEND_PID" 2>/dev/null; then
        echo ""
        echo "[*] Stopping backend (PID $BACKEND_PID)..."
        kill "$BACKEND_PID" 2>/dev/null
    fi
}
trap cleanup EXIT INT TERM

# ── Frontend: Vite dev server with /api proxy to the backend ──────
echo "[*] Starting frontend: http://localhost:$FRONTEND_PORT"
(cd frontend && npm run dev -- --port "$FRONTEND_PORT")
