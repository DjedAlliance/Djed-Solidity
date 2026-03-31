
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ] && [ -f "env/.env" ]; then
  ENV_FILE="env/.env"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Please set your .env file at ./.env or ./env/.env"
  exit 1
fi

# Robust .env loading for Git Bash:
# - supports comments
# - tolerates CRLF line endings from Windows editors
set -a
source <(sed -e 's/\r$//' "$ENV_FILE")
set +a

if [ -z "${RPC_URL:-}" ]; then
  echo "RPC_URL is not set in $ENV_FILE"
  exit 1
fi

if [ -z "${PRIVATE_KEY:-}" ]; then
  echo "PRIVATE_KEY is not set in $ENV_FILE"
  exit 1
fi


forge create src/mock/MockOracle.sol:MockOracle --legacy --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}" --constructor-args 10000000000000000000
