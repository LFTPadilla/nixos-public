#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: tmux-free-port.sh <port> [port...]" >&2
  exit 2
fi

find_pids() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | sort -u
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$port" 2>/dev/null \
      | sed -nE 's/.*pid=([0-9]+).*/\1/p' \
      | sort -u
    return 0
  fi
}

for port in "$@"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "tmux-free-port: invalid port: $port" >&2
    continue
  fi

  mapfile -t pids < <(find_pids "$port" || true)
  if [[ ${#pids[@]} -eq 0 ]]; then
    echo "tmux-free-port: port $port already free"
    continue
  fi

  echo "tmux-free-port: stopping port $port pids: ${pids[*]}"
  kill "${pids[@]}" 2>/dev/null || true

  for _ in 1 2 3 4 5; do
    alive=()
    for pid in "${pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        alive+=("$pid")
      fi
    done
    [[ ${#alive[@]} -eq 0 ]] && break
    sleep 0.4
  done

  if [[ ${#alive[@]} -gt 0 ]]; then
    echo "tmux-free-port: force killing port $port pids: ${alive[*]}"
    kill -9 "${alive[@]}" 2>/dev/null || true
  fi
done
