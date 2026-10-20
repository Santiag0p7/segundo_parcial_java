# =====================================================================
# Dockerfile - Sistema de Trabajos de Grado UTS
# ---------------------------------------------------------------------
# Tomcat 9 (javax.servlet) + JDK 17. NO usar Tomcat 10: el proyecto
# depende de JSTL 1.2 y de las URIs http://java.sun.com/jsp/jstl/...
# =====================================================================
FROM tomcat:9.0-jdk17-temurin

# envsubst (gettext-base) genera conexion.jspf al arrancar el contenedor.
RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Quitar las aplicaciones de ejemplo de Tomcat.
RUN rm -rf "${CATALINA_HOME}/webapps/"*

# Copiar la aplicación (solo lo necesario; ver .dockerignore).
WORKDIR /tmp/build
COPY . .

RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cp -r /tmp/build/*.jsp /tmp/build/assets /tmp/build/WEB-INF "${CATALINA_HOME}/webapps/ROOT/" \
    && rm -rf /tmp/build

# Plantilla y script de arranque.
COPY docker/conexion.render.jspf /opt/conexion.render.jspf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Render inyecta PORT en tiempo de ejecución; 8080 es el valor local.
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
