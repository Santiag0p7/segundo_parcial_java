<%--
    =====================================================================
    validar_login.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 3
    ---------------------------------------------------------------------
    Página de PROCESO (no genera HTML: nunca incluye header/footer).

    RF-01: valida correo_institucional + contrasena_hash + estado_activo.
    RF-02: en el mismo JOIN trae el nivel de formación del programa
           ('TECNOLOGIA' / 'INGENIERIA') para adaptar la interfaz.
    RNF-01: deja el usuario en ${sessionScope.usuario} para el RBAC.

    SE USA LEFT JOIN (no INNER) hacia ESTUDIANTES_PERFIL y
    PROGRAMAS_ACADEMICOS a propósito: DOCENTE, COMITE y ADMINISTRADOR no
    tienen fila en ESTUDIANTES_PERFIL; con INNER JOIN no podrían iniciar
    sesión nunca. Para ellos nivelFormacion queda vacío.

    Los valores se pasan con <sql:param> (consultas parametrizadas) para
    evitar inyección SQL.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%--
    Codificación de los parámetros POST. Tomcat 8.5 interpreta el cuerpo del
    POST como ISO-8859-1 si nadie fija la codificación, lo que corrompería
    claves o correos con tildes. <fmt:requestEncoding> debe ejecutarse ANTES
    de leer cualquier ${param...}.
--%>
<fmt:requestEncoding value="UTF-8" />

<c:choose>

    <%-- =========================================================
         1) Campos incompletos: se regresa al formulario
         ========================================================= --%>
    <c:when test="${empty param.correo or empty param.contrasena}">
        <c:redirect url="login.jsp">
            <c:param name="error" value="Debe ingresar el correo institucional y la contraseña." />
            <c:param name="correo" value="${fn:trim(param.correo)}" />
        </c:redirect>
    </c:when>

    <%-- =========================================================
         2) Autenticación contra la base de datos
         ========================================================= --%>
    <c:otherwise>

        <sql:query var="resUsuario" dataSource="${db}">
            <%--
                IMPORTANTE: las claves del row de <sql:query> son los NOMBRES
                FÍSICOS de las columnas (ResultSetMetaData.getColumnName), NO
                los alias. Por eso la consulta va envuelta en una tabla
                derivada: así "rol" y "nivelFormacion" sí existen como claves
                y ${sessionScope.usuario.rol} funciona en header/dashboard.
            --%>
            SELECT t.*
              FROM (
                  SELECT u.id_usuario,
                         u.documento_identidad,
                         u.nombres,
                         u.apellidos,
                         u.correo_institucional,
                         r.nombre              AS rol,
                         pa.nivel_formacion    AS nivelFormacion,
                         ep.codigo_estudiantil AS codigoEstudiantil,
                         dp.especialidad       AS especialidad
                    FROM USUARIOS u
                         INNER JOIN ROLES r                 ON r.id_rol       = u.id_rol
                         LEFT  JOIN ESTUDIANTES_PERFIL ep   ON ep.id_estudiante = u.id_usuario
                         LEFT  JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa  = ep.id_programa
                         LEFT  JOIN DOCENTES_PERFIL dp      ON dp.id_docente   = u.id_usuario
                   WHERE u.correo_institucional = ?
                     AND u.contrasena_hash      = ?
                     AND u.estado_activo        = 1
                  <sql:param value="${fn:trim(param.correo)}" />
                  <sql:param value="${param.contrasena}" />
              ) t
        </sql:query>

        <c:choose>

            <%-- ---------- 2.a) Credenciales válidas ---------- --%>
            <c:when test="${resUsuario.rowCount > 0}">
                <%-- Comprobación de perfil: cada rol tiene su propia pestaña, así que
                     la pestaña seleccionada debe coincidir exactamente con el rol real. --%>
                <c:set var="rolReal" value="${resUsuario.rows[0].rol}" />
                <c:set var="perfilValido" value="${empty param.perfil or param.perfil eq rolReal}" />
                <c:choose>
                    <c:when test="${not perfilValido}">
                        <c:redirect url="login.jsp">
                            <c:param name="error" value="El perfil seleccionado no coincide con esta cuenta. Seleccione la pestaña correcta para su rol." />
                            <c:param name="correo" value="${fn:trim(param.correo)}" />
                        </c:redirect>
                    </c:when>
                    <c:otherwise>
                        <%-- RNF-01: el mapa de la fila queda disponible para el RBAC --%>
                        <c:set var="usuario" value="${resUsuario.rows[0]}" scope="session" />
                        <c:choose>
                            <c:when test="${resUsuario.rows[0].rol eq 'ADMINISTRADOR'}">
                                <c:redirect url="dashboard_admin.jsp" />
                            </c:when>
                            <c:otherwise>
                                <c:redirect url="dashboard.jsp" />
                            </c:otherwise>
                        </c:choose>
                    </c:otherwise>
                </c:choose>
            </c:when>

            <%-- ---------- 2.b) Credenciales inválidas o inactivo ---------- --%>
            <c:otherwise>
                <c:redirect url="login.jsp">
                    <c:param name="error" value="Credenciales inválidas o cuenta inactiva." />
                    <c:param name="correo" value="${fn:trim(param.correo)}" />
                </c:redirect>
            </c:otherwise>

        </c:choose>

    </c:otherwise>

</c:choose>
