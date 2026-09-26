# =====================================================================
# SevaSetu — Windows daily launcher (PowerShell)
# Starts the FastAPI backend (venv) + Vite frontend dev server.
#   powershell -ExecutionPolicy Bypass -File .\scripts\dev.ps1
# Stop both servers with Ctrl+C.
# =====================================================================
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Error "venv not found. Run .\scripts\setup.ps1 first."
}
if (-not (Test-Path ".env")) {
    Write-Error ".env not found. Run .\scripts\setup.ps1 first, then set DATABASE_URL."
}

$backendPort = 8000
$frontendPort = 5173

Write-Host "=== SevaSetu Dev Launcher ===" -ForegroundColor Cyan

# ── Backend: uvicorn with auto-reload on port 8000 ────────────────
Write-Host "[*] Starting backend: http://127.0.0.1:$backendPort  (Swagger: /docs)" -ForegroundColor Green
$backend = Start-Process -FilePath ".\venv\Scripts\python.exe" `
    -ArgumentList "-m", "uvicorn", "backend.main:app", "--host", "127.0.0.1", "--port", "$backendPort", "--reload" `
    -PassThru -NoNewWindow

# ── Frontend: Vite dev server with /api proxy to the backend ──────
Write-Host "[*] Starting frontend: http://localhost:$frontendPort" -ForegroundColor Green
Push-Location frontend
try {
    npm run dev -- --port $frontendPort
} finally {
    Pop-Location
    if ($backend -and -not $backend.HasExited) {
        Write-Host "`n[*] Stopping backend (PID $($backend.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $backend.Id -Force -ErrorAction SilentlyContinue
    }
}
