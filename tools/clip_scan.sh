#!/bin/bash
# Adds the photos that are not in the search index yet (db/clip). The first run over ~24,000 photos takes a while; later runs only see new photos.
#   tools/clip_scan.sh
# Needs the syt-clip image (docker compose build clip); the job is defined in compose.yaml. Runs after the nightly face scan; the search service reads the new index by itself.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$REPO/db/clip"
cd "$REPO" && docker compose run --rm clip-index
