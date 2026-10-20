<%--
    =====================================================================
    admin_volver.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Página de PROCESO. Restaura la sesión del administrador que había
    quedado guardada en ${sessionScope.adminOriginal} y elimina las
    marcas de suplantación.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<c:choose>

    <c:when test="${empty sessionScope.adminOriginal}">
        <c:redirect url="dashboard.jsp">
            <c:param name="error" value="No hay una sesión de administrador pendiente por restaurar." />
        </c:redirect>
    </c:when>

    <c:otherwise>
        <c:set var="usuario" value="${sessionScope.adminOriginal}" scope="session" />
        <c:remove var="adminOriginal" scope="session" />
        <c:remove var="impersonando" scope="session" />
        <c:redirect url="dashboard_admin.jsp">
            <c:param name="msg" value="Volvió al panel de administración." />
        </c:redirect>
    </c:otherwise>

</c:choose>
