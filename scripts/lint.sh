#!/bin/bash
set -e

echo "=== Running selene ==="
if command -v selene &> /dev/null; then
    selene src/ tests/
else
    echo "selene not installed, skipping"
fi

echo "=== Running luau-analyze ==="
if command -v luau-analyze &> /dev/null; then
    luau-analyze src/
else
    echo "luau-analyze not installed, skipping"
fi

echo "=== Lint complete ==="
