#!/bin/sh
# =====================================================================
# SevaSetu — macOS / Linux one-time setup
# Creates venv, installs backend + frontend dependencies,
# and generates .env from env.example if missing.
# Run from the project root:   sh ./scripts/setup.sh
# =====================================================================
set -e

# Always operate from repo root
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "=== SevaSetu Setup (macOS / Linux) ==="

# ── 1. Locate Python 3 ────────────────────────────────────────────
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3 not found. Install Python 3.10+ and re-run." >&2
    exit 1
fi
echo "[1/4] Using Python: $PYTHON ($($PYTHON --version 2>&1))"

# ── 2. Create venv if missing ─────────────────────────────────────
if [ ! -x "venv/bin/python" ]; then
    echo "[2/4] Creating virtual environment (./venv)..."
    "$PYTHON" -m venv venv
else
    echo "[2/4] venv already exists — skipping creation."
fi
VENV_PYTHON="venv/bin/python"

# ── 3. Install backend dependencies ───────────────────────────────
echo "[3/4] Installing backend dependencies (backend/requirements.txt)..."
"$VENV_PYTHON" -m pip install --upgrade pip --quiet
"$VENV_PYTHON" -m pip install -r backend/requirements.txt

# ── 4. Generate .env from env.example if missing ──────────────────
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "[4/4] Created .env from env.example."
    echo ""
    echo "  >>> ACTION REQUIRED: open .env and set DATABASE_URL <<<"
    echo "  Supabase → Project Settings → Database → Connection pooling (port 6543)"
    echo "  Example: DATABASE_URL=postgresql://postgres.REF:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres"
    echo "  (For a quick offline test you can use: DATABASE_URL=sqlite:///./sevasetu_local.db)"
else
    echo "[4/4] .env already exists — leaving it untouched."
fi

# ── Frontend dependencies ─────────────────────────────────────────
echo "[+] Installing frontend dependencies (frontend/ npm install)..."
if command -v npm >/dev/null 2>&1; then
    (cd frontend && npm install --no-audit --no-fund)
else
    echo "ERROR: npm not found. Install Node.js 18+ and re-run: sh ./scripts/setup.sh" >&2
    exit 1
fi

echo ""
echo "=== Setup complete! ==="
echo "Next:  sh ./scripts/dev.sh     (starts backend + frontend together)"
echo "Then:  open http://localhost:5173"
