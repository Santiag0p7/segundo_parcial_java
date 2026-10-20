<%--
    =====================================================================
    seleccionar_propuesta.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    COMPATIBILIDAD (Paso 5 en adelante). Esta página YA NO crea el proyecto.

    En el Paso 4 este proceso cerraba el RF-07 insertando en PROYECTOS_GRADO
    y en INTEGRANTES_PROYECTO sin registrar pago. Desde el Paso 5 (Módulo 3,
    Fase 1) la selección debe pasar por fase1_registro.jsp, donde además se
    captura el soporte de pago (RF-08) y la posible dupla de estudiantes.

    Dejar este archivo operando como antes permitía crear un proyecto en
    Fase 1 sin comprobante, saltándose la verificación del comité.

    Ahora solo redirige, sin tocar la base de datos:

        con id_propuesta  -> fase1_registro.jsp?id_propuesta=N
        sin id_propuesta  -> banco_ideas.jsp?error=...

    Se conserva el archivo (en lugar de borrarlo) para que cualquier enlace
    o marcador antiguo siga funcionando y termine en el flujo correcto. No
    escribe nada antes de los <c:redirect>, así que nunca lanza
    IllegalStateException.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- Antes de leer cualquier ${param...} (POST en ISO-8859-1 por defecto) --%>
<fmt:requestEncoding value="UTF-8" />

<c:choose>

    <%-- =========================================================
         1) Control de acceso
         ========================================================= --%>
    <c:when test="${empty sessionScope.usuario}">
        <c:redirect url="login.jsp">
            <c:param name="error" value="Debe iniciar sesión para seleccionar una propuesta." />
        </c:redirect>
    </c:when>

    <c:when test="${sessionScope.usuario.rol ne 'ESTUDIANTE'}">
        <c:redirect url="banco_ideas.jsp">
            <c:param name="error" value="Solo los estudiantes pueden seleccionar una propuesta del banco de ideas." />
        </c:redirect>
    </c:when>

    <%-- =========================================================
         2) Redirección al flujo vigente de la Fase 1
         ========================================================= --%>
    <c:when test="${not empty param.id_propuesta}">
        <c:redirect url="fase1_registro.jsp">
            <c:param name="id_propuesta" value="${param.id_propuesta}" />
        </c:redirect>
    </c:when>

    <c:otherwise>
        <c:redirect url="banco_ideas.jsp">
            <c:param name="error" value="No se recibió la propuesta que desea seleccionar." />
        </c:redirect>
    </c:otherwise>

</c:choose>
