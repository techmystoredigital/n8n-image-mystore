FROM n8nio/n8n:2.3.4

USER root

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
