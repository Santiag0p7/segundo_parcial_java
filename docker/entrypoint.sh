#!/bin/sh
# =====================================================================
# entrypoint.sh - Sistema de Trabajos de Grado UTS
# ---------------------------------------------------------------------
# Render inyecta las credenciales como variables de entorno. Este script:
#   1) ajusta el puerto de Tomcat al que Render asigna (PORT);
#   2) genera WEB-INF/jspf/conexion.jspf a partir de la plantilla;
#   3) arranca Tomcat en primer plano.
# =====================================================================
set -eu

: "${MYSQL_ADDON_HOST:?Falta MYSQL_ADDON_HOST en las variables de Render}"
: "${MYSQL_ADDON_PORT:?Falta MYSQL_ADDON_PORT en las variables de Render}"
: "${MYSQL_ADDON_DB:?Falta MYSQL_ADDON_DB en las variables de Render}"
: "${MYSQL_ADDON_USER:?Falta MYSQL_ADDON_USER en las variables de Render}"
: "${MYSQL_ADDON_PASSWORD:?Falta MYSQL_ADDON_PASSWORD en las variables de Render}"

CATALINA_BASE="${CATALINA_HOME:-/usr/local/tomcat}"
PUERTO="${PORT:-8080}"

# 1) Tomcat debe escuchar en el puerto que Render expone.
sed -i "s/port=\"8080\"/port=\"${PUERTO}\"/g" "${CATALINA_BASE}/conf/server.xml"

# 2) Generar el archivo real de conexión (sin dejar la contraseña en GitHub).
DESTINO="${CATALINA_BASE}/webapps/ROOT/WEB-INF/jspf/conexion.jspf"
mkdir -p "$(dirname "${DESTINO}")"

envsubst '${MYSQL_ADDON_HOST} ${MYSQL_ADDON_PORT} ${MYSQL_ADDON_DB} ${MYSQL_ADDON_USER} ${MYSQL_ADDON_PASSWORD}' \
    < /opt/conexion.render.jspf > "${DESTINO}"

test -s "${DESTINO}" || {
    echo "ERROR: no se pudo generar ${DESTINO}" >&2
    exit 1
}

echo "Base de datos: ${MYSQL_ADDON_HOST}:${MYSQL_ADDON_PORT}/${MYSQL_ADDON_DB}"
echo "Tomcat escuchando en el puerto ${PUERTO}"

exec "${CATALINA_BASE}/bin/catalina.sh" run
