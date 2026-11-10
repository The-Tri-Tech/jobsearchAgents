#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  stop.sh — Stop JobSearch Agents (backend + frontend)
# ─────────────────────────────────────────────────────────────────────────────

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$ROOT_DIR/.pids"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║   JobSearch Agents — Stopping Services   ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

kill_pid() {
  local name="$1"
  local pid="$2"

  if [ -z "$pid" ]; then
    echo -e "${YELLOW}⚠️   $name: no PID recorded, skipping.${RESET}"
    return
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    # Wait up to 5 s, then force-kill
    for i in $(seq 1 10); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.5
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null
      echo -e "${RED}✖  $name (PID $pid) force-killed.${RESET}"
    else
      echo -e "${GREEN}✔  $name (PID $pid) stopped.${RESET}"
    fi
  else
    echo -e "${YELLOW}⚠️   $name (PID $pid) was not running.${RESET}"
  fi
}

if [ ! -f "$PID_FILE" ]; then
  echo -e "${YELLOW}⚠️  No .pids file found — services may not be running.${RESET}"
  echo -e "   Attempting to kill any stray processes on ports 8000 / 3000…"

  # Fallback: kill by port
  for port in 8000 3000; do
    pids=$(lsof -ti tcp:"$port" 2>/dev/null)
    if [ -n "$pids" ]; then
      kill -9 $pids 2>/dev/null && echo -e "${GREEN}✔  Killed process on port $port ($pids).${RESET}"
    fi
  done
  echo ""
  exit 0
fi

# ── Read PIDs and stop ────────────────────────────────────────────────────────
source "$PID_FILE"

kill_pid "Backend  (FastAPI)" "$BACKEND_PID"
kill_pid "Frontend (Flutter)" "$FRONTEND_PID"

# ── Also kill any child processes (uvicorn reload workers, flutter sub-procs) ─
for port in 8000 3000; do
  strays=$(lsof -ti tcp:"$port" 2>/dev/null)
  if [ -n "$strays" ]; then
    kill -9 $strays 2>/dev/null
    echo -e "${GREEN}✔  Cleaned up stray processes on port $port.${RESET}"
  fi
done

rm -f "$PID_FILE"

echo ""
echo -e "${GREEN}✅  All services stopped.${RESET}"
echo ""
