<%--
    =====================================================================
    guardar_propuesta.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 4 (Módulo 2)
    ---------------------------------------------------------------------
    Página de PROCESO (no genera HTML: nunca incluye header/footer) y no
    escribe NADA antes de su <c:redirect>; si la respuesta se confirmara,
    c:redirect lanzaría IllegalStateException.

    RF-04: inserta la propuesta en PROPUESTAS_PROYECTO con
           id_creador = usuario en sesión y estado = 'DISPONIBLE'.

    Validaciones previas (nunca se confía en el formulario):
      1. Sesión activa y rol autorizado (DOCENTE / COMITE / ADMINISTRADOR).
      2. Título y descripción no vacíos.
      3. Nivel destinatario dentro de la lista blanca del ENUM
         ('TECNOLOGIA' / 'INGENIERIA'); cualquier otro valor provocaría un
         error de la base de datos.

    IMPORTANTE: <fmt:requestEncoding value="UTF-8" /> va antes de leer
    cualquier ${param...}; de lo contrario Tomcat 8.5 decodifica el cuerpo
    del POST como ISO-8859-1 y las tildes llegan corruptas.

    Todos los valores viajan con <sql:param> (consulta parametrizada), así
    que no hay concatenación de SQL.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:choose>

    <c:when test="${empty sessionScope.usuario}">
        <c:redirect url="login.jsp">
            <c:param name="error" value="Debe iniciar sesión para registrar propuestas." />
        </c:redirect>
    </c:when>

    <c:when test="${not (sessionScope.usuario.rol eq 'DOCENTE'
                         or sessionScope.usuario.rol eq 'COMITE'
                         or sessionScope.usuario.rol eq 'ADMINISTRADOR')}">
        <c:redirect url="banco_ideas.jsp">
            <c:param name="error" value="Solo los docentes y el comité pueden registrar propuestas de proyecto." />
        </c:redirect>
    </c:when>

    <%-- =========================================================
         2) Validación de los datos del formulario
         ========================================================= --%>
    <c:when test="${empty param.titulo or empty param.descripcion or empty param.nivel_destinatario}">
        <c:redirect url="crear_propuesta.jsp">
            <c:param name="error" value="Debe completar el título, la descripción y el nivel destinatario." />
            <c:param name="titulo" value="${fn:trim(param.titulo)}" />
            <c:param name="descripcion" value="${param.descripcion}" />
            <c:param name="nivel_destinatario" value="${param.nivel_destinatario}" />
        </c:redirect>
    </c:when>

    <%-- Lista blanca del ENUM: evita un error SQL por un valor manipulado --%>
    <c:when test="${param.nivel_destinatario ne 'TECNOLOGIA' and param.nivel_destinatario ne 'INGENIERIA'}">
        <c:redirect url="crear_propuesta.jsp">
            <c:param name="error" value="El nivel destinatario seleccionado no es válido." />
            <c:param name="titulo" value="${fn:trim(param.titulo)}" />
            <c:param name="descripcion" value="${param.descripcion}" />
        </c:redirect>
    </c:when>

    <%-- El título es VARCHAR(255): se valida también en servidor --%>
    <c:when test="${fn:length(fn:trim(param.titulo)) gt 255}">
        <c:redirect url="crear_propuesta.jsp">
            <c:param name="error" value="El título no puede superar los 255 caracteres." />
            <c:param name="descripcion" value="${param.descripcion}" />
            <c:param name="nivel_destinatario" value="${param.nivel_destinatario}" />
        </c:redirect>
    </c:when>

    <%-- =========================================================
         3) Inserción en el banco de propuestas
         ========================================================= --%>
    <c:otherwise>

        <c:catch var="errorInsert">
            <sql:update var="resInsert" dataSource="${db}">
                INSERT INTO PROPUESTAS_PROYECTO
                       (id_creador, titulo, descripcion, nivel_destinatario, estado)
                VALUES (?, ?, ?, ?, 'DISPONIBLE')
                <sql:param value="${sessionScope.usuario.id_usuario}" />
                <sql:param value="${fn:trim(param.titulo)}" />
                <sql:param value="${param.descripcion}" />
                <sql:param value="${param.nivel_destinatario}" />
            </sql:update>
        </c:catch>

        <c:choose>

            <%-- ---------- 3.a) Registro exitoso ---------- --%>
            <c:when test="${empty errorInsert}">
                <c:redirect url="banco_ideas.jsp">
                    <c:param name="msg" value="Propuesta registrada exitosamente y publicada con estado DISPONIBLE." />
                </c:redirect>
            </c:when>

            <%-- ---------- 3.b) Fallo de la base de datos ---------- --%>
            <c:otherwise>
                <c:redirect url="crear_propuesta.jsp">
                    <c:param name="error" value="No fue posible registrar la propuesta. Verifique la conexión a la base de datos e intente de nuevo." />
                    <c:param name="titulo" value="${fn:trim(param.titulo)}" />
                    <c:param name="descripcion" value="${param.descripcion}" />
                    <c:param name="nivel_destinatario" value="${param.nivel_destinatario}" />
                </c:redirect>
            </c:otherwise>

        </c:choose>

    </c:otherwise>

</c:choose>
