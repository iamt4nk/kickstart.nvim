#!/usr/bin/env bash
# Runs every tests/test_*.lua headlessly against this config.
#
#   ./tests/run.sh              # use the real ~/.local/share/nvim (pass 2)
#   CLEAN=1 ./tests/run.sh      # use a throwaway data dir (pass 1)
set -uo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NVIM_APPNAME=""
cd "$CONFIG_DIR" || exit 1

if [[ "${CLEAN:-0}" == "1" ]]; then
  SCRATCH="$(mktemp -d)"
  export XDG_DATA_HOME="$SCRATCH/share"
  export XDG_STATE_HOME="$SCRATCH/state"
  export XDG_CACHE_HOME="$SCRATCH/cache"
  echo "clean-slate run, data dir: $XDG_DATA_HOME"
  trap 'rm -rf "$SCRATCH"' EXIT
fi

failed=0
for test_file in "$CONFIG_DIR"/tests/test_*.lua; do
  name="$(basename "$test_file")"
  echo "RUN $name"
  if ! nvim --headless -u "$CONFIG_DIR/init.lua" -l "$test_file" 2>&1; then
    failed=1
  fi
done

if [[ $failed -eq 0 ]]; then
  echo "ALL TESTS PASSED"
else
  echo "TESTS FAILED"
fi
exit $failed
