FROM n8nio/n8n:2.3.4

USER root

# Install poppler-utils for PDF processing (pdftoppm, pdftotext, pdfinfo)
# Used by Workflow A to convert PDF comprobantes to images before Gemini Vision
# 2026-05-24: cambio apk -> apt-get porque la base de n8nio/n8n:2.3.4 ya no es Alpine
RUN apt-get update && \
    apt-get install -y --no-install-recommends poppler-utils && \
    rm -rf /var/lib/apt/lists/*

# Install exceljs in a temp dir (using plain npm, no catalog: protocol from n8n's package.json)
# Then copy it + dependencies to the task-runner's node_modules path
RUN mkdir -p /tmp/excelbuild && \
    cd /tmp/excelbuild && \
    npm init -y && \
    npm install exceljs && \
    TR=$(find /usr/local/lib/node_modules/n8n/node_modules/.pnpm -maxdepth 1 -type d -name "@n8n+task-runner@*" | head -1) && \
    echo "Task runner path: $TR" && \
    cp -rL /tmp/excelbuild/node_modules/* $TR/node_modules/ && \
    rm -rf /tmp/excelbuild && \
    echo "exceljs installed at $TR/node_modules/exceljs:" && \
    ls "$TR/node_modules/exceljs/package.json"

USER node
