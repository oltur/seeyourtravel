#!/bin/bash
# (Re)starts the search + assistant service syt-clip. It is defined in compose.yaml; the Gemini key comes from .env and goes into this container only.
#   tools/clip_up.sh
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$REPO/db/clip"
cd "$REPO" && docker compose up -d --force-recreate clip
