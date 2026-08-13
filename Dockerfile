FROM n8nio/n8n:2.32.5

USER root

# 2026-05-24: poppler-utils REMOVIDO (era para Workflow A / Telegram bot, pausado).
# Si se reactiva: agregar instalacion con el package manager correcto (la base
# de n8nio/n8n ya no es Alpine, ni acepta apt directo).
#
# 2026-07-29: base subida 2.3.4 -> 2.32.5 para corregir el bug del task runner
# (grant token TTL ~15s => 403 en arranque, arreglado en n8n 2.20.0 / PR #29357).
#
# 2026-08-13: exceljs queda disponible en AMBAS rutas -- el task runner Y el
# proceso principal de n8n. Antes solo se copiaba al task runner; si el codigo
# llegaba a correr en el proceso principal, require('exceljs') fallaba y la
# conciliacion (15 nodos lo usan) se caia sin motivo aparente.
#
# Ademas se instala AISLADO en /opt/extra_modules y se enlaza, en vez de volcar
# ~30 paquetes dentro de los node_modules de n8n (podian pisar dependencias
# propias de n8n o del runner). El paso del RUN, en orden:
#   1) instalar exceljs aislado en /opt/extra_modules
#   2) enlazarlo en los node_modules del proceso principal de n8n
#   3) localizar el node_modules del @n8n/task-runner y enlazarlo ahi tambien;
#      si no lo encuentra, el build FALLA con mensaje claro (antes copiaba a un
#      destino equivocado)
#   4) verificar con un require() real desde cada ruta: si algo no resuelve,
#      falla el build aqui y no en produccion a mitad de una conciliacion.
# NOTA: sin comentarios dentro del RUN a proposito -- un '#' en una linea
# continuada puede comentar el resto del comando y construir la imagen "bien"
# pero sin exceljs.

RUN set -eux; \
    mkdir -p /opt/extra_modules; \
    cd /opt/extra_modules; \
    npm init -y > /dev/null; \
    npm install --omit=dev exceljs; \
    EXCEL=/opt/extra_modules/node_modules/exceljs; \
    test -f "$EXCEL/package.json"; \
    N8N_MAIN=/usr/local/lib/node_modules/n8n; \
    mkdir -p "$N8N_MAIN/node_modules"; \
    ln -sfn "$EXCEL" "$N8N_MAIN/node_modules/exceljs"; \
    TR=$(find "$N8N_MAIN/node_modules/.pnpm" -maxdepth 1 -type d -name "@n8n+task-runner@*" 2>/dev/null | head -1); \
    if [ -z "$TR" ]; then \
        TR=$(find /usr/local/lib/node_modules -maxdepth 8 -type d -name "@n8n+task-runner@*" 2>/dev/null | head -1); \
    fi; \
    if [ -z "$TR" ]; then \
        echo "ERROR: no se encontro el node_modules del @n8n/task-runner."; \
        find /usr/local/lib/node_modules -maxdepth 8 -type d -name "*task-runner*" 2>/dev/null | head -20 || true; \
        exit 1; \
    fi; \
    echo "Task runner path: $TR"; \
    mkdir -p "$TR/node_modules"; \
    ln -sfn "$EXCEL" "$TR/node_modules/exceljs"; \
    cd "$N8N_MAIN"; node -e "require('exceljs'); console.log('OK exceljs en proceso principal')"; \
    cd "$TR"; node -e "require('exceljs'); console.log('OK exceljs en task runner')"; \
    rm -rf /root/.npm

# Los nodos Code deben tener permitido importar exceljs. Se declara aqui como
# valor por defecto para que no dependa de que alguien lo recuerde en el panel;
# si la variable ya existe en el entorno de EasyPanel, esa tiene prioridad.
ENV NODE_FUNCTION_ALLOW_EXTERNAL=exceljs

USER node
