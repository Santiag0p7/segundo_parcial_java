<%--
    =====================================================================
    admin_impersonar.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Página de PROCESO. El administrador elige una cuenta y el sistema
    reemplaza ${sessionScope.usuario} por la cuenta elegida.

    El administrador original se conserva en
    ${sessionScope.adminOriginal}; admin_volver.jsp lo restaura.

    Restricciones:
      * Solo el administrador real puede ejecutar esta acción.
      * No se puede suplantar a otro ADMINISTRADOR.
      * Solo se permiten cuentas activas.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<fmt:requestEncoding value="UTF-8" />

<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para entrar como otro usuario." />
    </c:redirect>
</c:if>

<c:if test="${sessionScope.usuario.rol ne 'ADMINISTRADOR' or not empty sessionScope.adminOriginal}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La suplantación de usuarios es exclusiva del rol ADMINISTRADOR." />
    </c:redirect>
</c:if>

<c:set var="idObjetivo" value="${fn:trim(param.id_usuario)}" />

<c:if test="${empty idObjetivo}">
    <c:redirect url="admin_suplantar.jsp">
        <c:param name="error" value="No se recibió el usuario que desea suplantar." />
    </c:redirect>
</c:if>

<c:set var="errorObjetivo" value="" />
<c:catch var="errorObjetivo">
    <sql:query var="resObjetivo" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT u.id_usuario,
                     u.documento_identidad,
                     u.nombres,
                     u.apellidos,
                     u.correo_institucional,
                     r.nombre AS rol,
                     pa.nivel_formacion AS nivelFormacion,
                     ep.codigo_estudiantil AS codigoEstudiantil,
                     dp.especialidad AS especialidad
                FROM USUARIOS u
                     INNER JOIN ROLES r ON r.id_rol = u.id_rol
                     LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
                     LEFT JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                     LEFT JOIN DOCENTES_PERFIL dp ON dp.id_docente = u.id_usuario
               WHERE u.id_usuario = ?
                 AND u.estado_activo = 1
          ) t
        <sql:param value="${idObjetivo}" />
    </sql:query>
</c:catch>

<c:choose>

    <c:when test="${not empty errorObjetivo}">
        <c:redirect url="admin_suplantar.jsp">
            <c:param name="error" value="No fue posible consultar el usuario seleccionado." />
        </c:redirect>
    </c:when>

    <c:when test="${empty resObjetivo or resObjetivo.rowCount eq 0}">
        <c:redirect url="admin_suplantar.jsp">
            <c:param name="error" value="El usuario no existe o está inactivo." />
        </c:redirect>
    </c:when>

    <c:when test="${resObjetivo.rows[0].rol eq 'ADMINISTRADOR'}">
        <c:redirect url="admin_suplantar.jsp">
            <c:param name="error" value="No es posible suplantar a otro administrador." />
        </c:redirect>
    </c:when>

    <c:otherwise>
        <c:set var="objetivo" value="${resObjetivo.rows[0]}" />

        <%-- Guardar al administrador y activar la suplantación --%>
        <c:set var="adminOriginal" value="${sessionScope.usuario}" scope="session" />
        <c:set var="usuario" value="${objetivo}" scope="session" />
        <c:set var="impersonando" value="${true}" scope="session" />

        <c:redirect url="dashboard.jsp">
            <c:param name="msg"
                     value="Ahora está operando como ${objetivo.nombres} ${objetivo.apellidos} (${objetivo.rol}). Use 'Volver al panel admin' para regresar." />
        </c:redirect>
    </c:otherwise>

</c:choose>
