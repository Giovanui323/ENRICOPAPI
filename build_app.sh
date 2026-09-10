#!/bin/bash
set -e

echo "🔨 Compilazione di Enrico Papi in corso..."

APP_NAME="EnricoPapi"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
MODULE_CACHE=".build/ModuleCache"

mkdir -p "${MODULE_CACHE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 1. Compilazione Swift con ottimizzazioni
echo "📦 Compilazione dei sorgenti Swift..."
swiftc Sources/EnricoPapi/*.swift \
    -o "${MACOS_DIR}/${APP_NAME}" \
    -module-cache-path "${MODULE_CACHE}" \
    -O

# 2. Copia Info.plist e Icona
echo "📋 Installazione Info.plist e AppIcon..."
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

# 3. Copia eventuali asset aggiuntivi (immagini, audio)
if [ -d "Assets" ]; then
    cp -r Assets/* "${RESOURCES_DIR}/" 2>/dev/null || true
fi

# 4. Firma ad-hoc del bundle per i permessi macOS
echo "🔏 Firma del bundle dell'applicazione..."
codesign --force --deep --sign - "${BUNDLE_DIR}" 2>/dev/null || true

echo "✅ Applicazione compilata con successo: ${BUNDLE_DIR}"
echo "🚀 Per avviarla esegui: open ${BUNDLE_DIR} oppure ./run.sh"
