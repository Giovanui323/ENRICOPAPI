#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ ! -d "EnricoPapi.app" ]; then
    ./build_app.sh
fi

echo "🎬 Avvio di Enrico Papi Anti-Distrazione..."
open EnricoPapi.app
