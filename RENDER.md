# Despliegue en Render

## Arquitectura

```text
Navegador  ->  Render (Tomcat 9 + JSP)  ->  Clever Cloud (MySQL)
```

Render ejecuta la aplicación; la base de datos sigue en Clever Cloud. La
conexión se arma al arrancar el contenedor con las variables de entorno.

## Archivos de despliegue

| Archivo | Para qué |
| --- | --- |
| `Dockerfile` | Imagen Tomcat 9 + JDK 17 con la aplicación en `ROOT`. |
| `docker/conexion.render.jspf` | Plantilla con los marcadores `MYSQL_ADDON_*`. |
| `docker/entrypoint.sh` | Genera `conexion.jspf` y ajusta el puerto de Tomcat. |
| `.dockerignore` | Evita subir `.git`, `db`, documentación y binarios al contexto. |

`WEB-INF/jspf/conexion.jspf` se queda con `localhost` para seguir trabajando
en XAMPP. Dentro del contenedor, el `entrypoint` lo reemplaza por el archivo
generado con las credenciales de Render.

## Pasos en Render

1. Sube estos archivos a GitHub (rama `main`).
2. En Render: **New -> Web Service** y conecta el repositorio.
3. En **Language** elige **Docker**. Deja **Root Directory** vacío si el
   `Dockerfile` está en la raíz del repositorio.
4. En **Health Check Path** escribe `/login.jsp`.
5. En **Environment** agrega las cinco variables del add-on de Clever Cloud:

| Variable | Valor |
| --- | --- |
| `MYSQL_ADDON_HOST` | Host del add-on |
| `MYSQL_ADDON_PORT` | Puerto (normalmente `3306`) |
| `MYSQL_ADDON_DB` | Nombre de la base |
| `MYSQL_ADDON_USER` | Usuario |
| `MYSQL_ADDON_PASSWORD` | Contraseña |

Los valores están en Clever Cloud, en la pestaña **Information** del add-on
MySQL.

6. Guarda y despliega. Render construye la imagen y arranca Tomcat.

## Datos de demostración

El esquema se crea con `db/script1.sql`. Los usuarios, propuestas y proyectos de
demostración se cargan con uno de estos archivos:

| Archivo | Cuándo usarlo |
| --- | --- |
| `db/seed_minimo_clevercloud.sql` | Cliente SQL que respeta los saltos de línea (Workbench, DBeaver, CLI). |
| `db/seed_minimo_clevercloud_paste.sql` | Consola que elimina los saltos de línea al pegar (sin comentarios `--`). |

El seed es idempotente: se puede ejecutar más de una vez sin duplicar datos.

| Usuario | Rol | Clave |
| --- | --- | --- |
| `jsantiago@correo.uts.edu.co` | ESTUDIANTE (INGENIERIA) | `uts2026` |
| `atecnologa@correo.uts.edu.co` | ESTUDIANTE (TECNOLOGIA) | `uts2026` |
| `director@correo.uts.edu.co` | DOCENTE | `uts2026` |
| `evaluador@correo.uts.edu.co` | DOCENTE | `uts2026` |
| `comite@correo.uts.edu.co` | COMITE | `uts2026` |
| `admin@correo.uts.edu.co` | ADMINISTRADOR | `uts2026` |

El administrador entra por la pestaña **Comité / Administrador**; no hay una
cuarta pestaña. Su panel (`dashboard_admin.jsp`) permite gestionar usuarios,
entrar como estudiante o docente para operar sus vistas, y usar todos los
módulos del comité.

## Qué hace el entrypoint

1. Verifica que las cinco variables existan; si falta una, falla con un
   mensaje claro en los logs.
2. Cambia el puerto `8080` de Tomcat por el valor de `PORT` que asigna Render.
3. Reemplaza los marcadores de la plantilla y escribe
   `webapps/ROOT/WEB-INF/jspf/conexion.jspf`.
4. Arranca Tomcat con `catalina.sh run`.

## Notas

- La aplicación queda en la raíz del dominio (`/`), no en
  `/segundo_parcial_java`. Los enlaces usan `${ctx}`, así que se adaptan solos.
- No subas la contraseña a GitHub. Si algún día la escribes en
  `conexion.jspf`, cámbiala en Clever Cloud.
- Usa Tomcat 9, no Tomcat 10: JSTL 1.2 usa `javax.servlet` y en Tomcat 10
  las etiquetas `c:` y `sql:` no se reconocen.
- Los `.jar` de `WEB-INF/lib` deben estar en el repositorio. Ya están
  rastreados por Git.
- La primera petición puede tardar porque Tomcat compila los JSP.
- En el plan gratuito la instancia se suspende por inactividad; la primera
  visita después de un rato tarda unos segundos.

## Problemas frecuentes

| Síntoma | Causa probable |
| --- | --- |
| `Access denied for user` | Usuario, contraseña o base equivocados. |
| `Communications link failure` | Host o puerto incorrectos, o la base no está disponible. |
| Error de SSL | Prueba `sslMode=DISABLED` en la URL de la plantilla. |
| `500` con error de `taglib` | Faltan los `.jar` en `WEB-INF/lib` o se usó Tomcat 10. |
| El health check falla | Revisa los logs; normalmente es una variable faltante o un error de conexión. |
