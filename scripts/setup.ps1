# =====================================================================
# SevaSetu - Windows one-time setup (PowerShell 5.1 compatible)
# Creates venv, installs backend + frontend dependencies,
# and generates .env from env.example if missing.
# Run from the project root:   powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
# =====================================================================
$ErrorActionPreference = "Stop"

# Always operate from repo root (script may be invoked from anywhere)
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host ""
Write-Host "=== SevaSetu Setup (Windows) ===" -ForegroundColor Cyan

# -- 1. Locate Python -------------------------------------------------
$python = $null
foreach ($candidate in @("python", "python3", "py")) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $python = $candidate
        break
    }
}
if (-not $python) {
    Write-Error "Python not found. Install Python 3.10+ from https://www.python.org/downloads/ and re-run."
}
Write-Host "[1/4] Using Python: $python ($(& $python --version))"

# -- 2. Create venv if missing ----------------------------------------
if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Host "[2/4] Creating virtual environment (.\venv)..." -ForegroundColor Yellow
    & $python -m venv venv
    if ($LASTEXITCODE -ne 0) { Write-Error "venv creation failed." }
} else {
    Write-Host "[2/4] venv already exists - skipping creation."
}
$venvPython = ".\venv\Scripts\python.exe"

# -- 3. Install backend dependencies ----------------------------------
Write-Host "[3/4] Installing backend dependencies (backend/requirements.txt)..." -ForegroundColor Yellow
& $venvPython -m pip install --upgrade pip --quiet
& $venvPython -m pip install -r backend\requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Error "Backend dependency install failed." }

# -- 4. Generate .env from env.example if missing ----------------------
if (-not (Test-Path ".env")) {
    Copy-Item "env.example" ".env"
    Write-Host "[4/4] Created .env from env.example." -ForegroundColor Green
    Write-Host ""
    Write-Host "  >>> ACTION REQUIRED: open .env and set DATABASE_URL <<<" -ForegroundColor Red
    Write-Host "  Supabase > Project Settings > Database > Connection pooling (port 6543)" -ForegroundColor Red
    Write-Host "  Example: DATABASE_URL=postgresql://postgres.REF:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres"
    Write-Host "  (For a quick offline test you can use: DATABASE_URL=sqlite:///./sevasetu_local.db)"
} else {
    Write-Host "[4/4] .env already exists - leaving it untouched."
}

# -- Frontend dependencies ---------------------------------------------
Write-Host "[+] Installing frontend dependencies (frontend/ npm install)..." -ForegroundColor Yellow
Push-Location frontend
npm install --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "npm install failed. Is Node.js 18+ installed?" }
Pop-Location

Write-Host ""
Write-Host "=== Setup complete! ===" -ForegroundColor Green
Write-Host "Next:  .\scripts\dev.ps1     (starts backend + frontend together)"
Write-Host "Then:  open http://localhost:5173"
