# n8n-image-mystore

Custom Docker image extending the official n8nio/n8n image with `exceljs` package preinstalled.

This is required for the Conciliacion workflows that use `require('exceljs')` in Code nodes to read/write Excel files efficiently.

## Usage

Used as the source for the Mine Store n8n container in Easy Panel. When Easy Panel builds this Dockerfile, it produces an image identical to n8n official + exceljs available in the task-runner path.

## How it works

1. Starts from `n8nio/n8n:latest`.
2. Switches to root temporarily.
3. Installs `exceljs` in `/usr/local/lib/node_modules/n8n` so the task-runner can `require('exceljs')`.
4. Switches back to `node` user (n8n's default for security).

## Maintenance

To add more npm packages, edit the `RUN` line:

\`\`\`
RUN cd /usr/local/lib/node_modules/n8n && npm install exceljs xlsx other-package --no-save
\`\`\`

Then commit + push. Easy Panel will rebuild on next deploy.
