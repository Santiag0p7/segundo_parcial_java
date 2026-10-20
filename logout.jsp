<%--
    =====================================================================
    logout.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 3
    ---------------------------------------------------------------------
    Cierre de sesión:
      1. Se elimina el atributo "usuario" de la sesión.
      2. Se invalida la sesión completa (destruye todos los atributos).
      3. Se redirige al login con un mensaje informativo.

    Página de PROCESO: no genera HTML (no incluye header/footer).
    El orden importa: <c:remove> debe ir ANTES de session.invalidate(),
    porque después de invalidar la sesión cualquier acceso a ella lanza
    IllegalStateException.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%-- 1. Quitar el usuario de la sesión --%>
<c:remove var="usuario" scope="session" />

<%-- 2. Invalidar la sesión completa --%>
<% session.invalidate(); %>

<%-- 3. Volver al login informando el cierre de sesión --%>
<c:redirect url="login.jsp">
    <c:param name="msg" value="La sesión se ha cerrado correctamente." />
</c:redirect>
