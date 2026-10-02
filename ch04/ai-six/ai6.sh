#!/bin/bash

# Change dir to the py directory of AI-6 (all module paths are relative to it)
cd "$(dirname "${BASH_SOURCE[0]}")/py"

# Activate venv if not active already
if [[ -z "$VIRTUAL_ENV" || "$VIRTUAL_ENV" != *"ai-six/py/venv" ]]; then
  if [[ ! -f venv/bin/activate ]]; then
    echo "virtualenv not found. Create it first (see py/README.md):"
    echo "  cd py && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
  fi
  source venv/bin/activate
fi

echo "virtualenv: ${VIRTUAL_ENV}"

# Default Python runner
PY_RUN="python"

# Check for global --debug flag
if [[ "$2" == "--debug" ]]; then
  PY_RUN="python -m debugpy --listen 5678 --wait-for-client"
  # Remove the debug flag so it doesn't confuse the client command
  set -- "$1" "${@:3}"
fi

# Create memory directories if they don't exist
mkdir -p memory/cli memory/slack memory/chainlit

if [[ "$1" == "update" ]]; then
  pip install -r requirements.txt
elif [[ "$1" == "cli" ]]; then
  shift  # Drops the first argument ("cli")
  $PY_RUN -m frontend.cli.ai6 "$@"
elif [[ "$1" == "slack" ]]; then
  $PY_RUN -m frontend.slack.app
elif [[ "$1" == "chainlit" ]]; then
  $PY_RUN -m frontend.chainlit.app
elif [[ "$1" == "list-conversations" ]]; then
  # List all conversations in memory
  echo "CLI conversations:"
  ls -1 memory/cli/ 2>/dev/null | sed 's/\.json$//' || echo "  No conversations found"
  echo
  echo "Slack conversations:"
  ls -1 memory/slack/ 2>/dev/null | sed 's/\.json$//' || echo "  No conversations found"
  echo
  echo "Chainlit conversations:"
  ls -1 memory/chainlit/ 2>/dev/null | sed 's/\.json$//' || echo "  No conversations found"
else
  echo 'Usage: ai6.sh <cli | slack | chainlit | list-conversations | update> [--debug]'
  echo
  echo 'CLI options:'
  echo '  ai6.sh cli                     Start a new session'
  echo '  ai6.sh cli -s <session_id>     Continue a specific session'
  echo '  ai6.sh cli -l                  List available CLI sessions'
  echo '  ai6.sh cli -c <config_file>    Use a specific config file'
  echo
  echo 'Other commands:'
  echo '  ai6.sh list-conversations      List all sessions across all frontends'
  echo '  ai6.sh update                  Re-install Python dependencies'
fi
