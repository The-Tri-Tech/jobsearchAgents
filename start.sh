#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  start.sh — Start JobSearch Agents (backend + frontend)
# ─────────────────────────────────────────────────────────────────────────────

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
PID_FILE="$ROOT_DIR/.pids"
LOG_DIR="$ROOT_DIR/logs"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

mkdir -p "$LOG_DIR"

# ── Guard: already running? ───────────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
  echo -e "${YELLOW}⚠️  Services appear to be running already (found .pids file).${RESET}"
  echo -e "   Run ${CYAN}./stop.sh${RESET} first, or delete ${CYAN}.pids${RESET} manually."
  exit 1
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║   JobSearch Agents — Starting Services   ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Backend (FastAPI via uv) ──────────────────────────────────────────────────
echo -e "${GREEN}▶  Starting Backend  (FastAPI · port 8000)${RESET}"
cd "$BACKEND_DIR"
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload \
  > "$LOG_DIR/backend.log" 2>&1 &
BACKEND_PID=$!
echo -e "   PID: ${YELLOW}$BACKEND_PID${RESET}  •  Logs: logs/backend.log"

# ── Frontend (Flutter Web) ────────────────────────────────────────────────────
echo -e "${GREEN}▶  Starting Frontend (Flutter Web · Chrome)${RESET}"
cd "$FRONTEND_DIR"
flutter run -d chrome --web-port 3000 \
  > "$LOG_DIR/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo -e "   PID: ${YELLOW}$FRONTEND_PID${RESET}  •  Logs: logs/frontend.log"

# ── Save PIDs ─────────────────────────────────────────────────────────────────
echo "BACKEND_PID=$BACKEND_PID" > "$PID_FILE"
echo "FRONTEND_PID=$FRONTEND_PID" >> "$PID_FILE"

echo ""
echo -e "${GREEN}✅  Both services started!${RESET}"
echo -e "   Backend  → ${CYAN}http://localhost:8000${RESET}"
echo -e "   Frontend → ${CYAN}http://localhost:3000${RESET}"
echo -e "   API Docs → ${CYAN}http://localhost:8000/api/v1/openapi.json${RESET}"
echo ""
echo -e "   Run ${CYAN}./stop.sh${RESET} to stop both services."
echo ""
