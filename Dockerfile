FROM n8nio/n8n:2.3.4

USER root

RUN cd /usr/local/lib/node_modules/n8n && npm install exceljs --no-save

USER node
