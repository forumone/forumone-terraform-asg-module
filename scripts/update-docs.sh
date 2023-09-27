#!/bin/bash

set -euo pipefail

readonly paths=(
  .
)

for path in "${paths[@]}"; do
  echo "Updating $path"
  bash scripts/check-docs.sh "$path" >&/dev/null || true
done
