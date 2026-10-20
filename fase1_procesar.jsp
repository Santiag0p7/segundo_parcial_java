<%--
    =====================================================================
    fase1_procesar.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 5 (Módulo 3, Fase 1)
    ---------------------------------------------------------------------
    Página de PROCESO (no genera HTML y no escribe nada antes de su
    <c:redirect>).

    Registra el arranque de la Fase 1:
      Paso 0  (solo idea propia, RF-09): crea la PROPUESTA asociada al
              estudiante y la marca SELECCIONADA.
      Paso 1  PAGOS_PROYECTO: tipo DERECHOS_GRADO, estado PENDIENTE (RF-08).
      Paso 2  PROYECTOS_GRADO: fase_actual = 1, estado EN_PROCESO.
      Paso 3  INTEGRANTES_PROYECTO: estudiante creador con es_lider = TRUE.
      Paso 4  INTEGRANTES_PROYECTO: compañero (opcional) con es_lider = FALSE.
      Paso 5  PROPUESTAS_PROYECTO: estado = SELECCIONADA (si vino del banco).

    ¿POR QUÉ EXISTE EL PASO 0? PROYECTOS_GRADO no tiene columna de
    descripción: si el estudiante escribe una idea propia y solo se guardara
    el proyecto, el texto de la idea se perdería y RF-09 quedaría a medias.
    Por eso la idea propia se guarda como una fila de PROPUESTAS_PROYECTO
    (creador = el estudiante, nivel = su nivel de formación) y el proyecto
    apunta a ella con id_propuesta. Así la descripción se conserva y
    mi_proyecto.jsp la puede mostrar.

    ORDEN: el pago va antes que el proyecto (como pide el enunciado) y es
    válido porque PAGOS_PROYECTO solo referencia USUARIOS(id_estudiante),
    no al proyecto.

    IMPORTANTE:
      * <fmt:requestEncoding value="UTF-8" /> antes de leer ${param...}.
      * <sql:param> posicional respecto de cada "?" (trampa 11).
      * rowCount gt 0, nunca "not empty", para saber si una consulta trajo
        filas (trampa 10).
      * LAST_INSERT_ID() no es fiable entre etiquetas <sql:> distintas: los
        ids recién creados se recuperan con MAX(...) en tabla derivada.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para registrar su proyecto de grado." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'ESTUDIANTE'}">
    <c:redirect url="banco_ideas.jsp">
        <c:param name="error" value="Solo los estudiantes pueden iniciar la Fase 1 de un proyecto de grado." />
    </c:redirect>
</c:if>

<%-- Un estudiante no puede tener dos proyectos (UNIQUE en INTEGRANTES_PROYECTO) --%>
<c:catch var="errorPrevio">
    <sql:query var="resProyectoPrevio" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT i.id_proyecto
                FROM INTEGRANTES_PROYECTO i
               WHERE i.id_estudiante = ?
               LIMIT 1
          ) t
        <sql:param value="${u.id_usuario}" />
    </sql:query>
</c:catch>

<c:if test="${not empty errorPrevio}">
    <c:redirect url="mi_proyecto.jsp">
        <c:param name="error" value="No fue posible verificar su situación académica. Verifique la conexión a la base de datos." />
    </c:redirect>
</c:if>

<c:if test="${not empty resProyectoPrevio and resProyectoPrevio.rowCount gt 0}">
    <c:redirect url="mi_proyecto.jsp">
        <c:param name="error" value="Usted ya tiene un proyecto de grado registrado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Datos del formulario (normalizados)
     ========================================================= --%>
<c:set var="valorTitulo" value="${fn:trim(param.titulo)}" />
<c:set var="valorSoporte" value="${fn:trim(param.soporte_pago)}" />
<c:set var="valorCompanero" value="${fn:trim(param.codigo_companero)}" />
<c:set var="errorValidacion" value="" />

<c:if test="${empty errorValidacion and empty valorTitulo}">
    <c:set var="errorValidacion" value="Debe indicar el título del proyecto." />
</c:if>

<c:if test="${empty errorValidacion and fn:length(valorTitulo) gt 255}">
    <c:set var="errorValidacion" value="El título no puede superar los 255 caracteres." />
</c:if>

<%-- RF-08: el soporte de pago es obligatorio --%>
<c:if test="${empty errorValidacion and empty valorSoporte}">
    <c:set var="errorValidacion" value="Debe indicar la ruta del soporte de pago en PDF." />
</c:if>

<c:if test="${empty errorValidacion and fn:length(valorSoporte) gt 255}">
    <c:set var="errorValidacion" value="La ruta del soporte de pago no puede superar los 255 caracteres." />
</c:if>

<%-- RF-09: la descripción solo es obligatoria cuando la idea es propia --%>
<c:if test="${empty errorValidacion and empty param.id_propuesta and empty fn:trim(param.descripcion)}">
    <c:set var="errorValidacion" value="Debe describir su idea propia antes de registrarla." />
</c:if>

<%-- =========================================================
     3) Si viene del banco, la propuesta debe seguir DISPONIBLE y
        ser del nivel del estudiante
     ========================================================= --%>
<c:if test="${empty errorValidacion and not empty param.id_propuesta}">
    <c:catch var="errorPropuesta">
        <sql:query var="resPropuestaVal" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT p.id_propuesta, p.titulo, p.estado, p.nivel_destinatario
                    FROM PROPUESTAS_PROYECTO p
                   WHERE p.id_propuesta = ?
                     AND p.estado = 'DISPONIBLE'
                     AND p.nivel_destinatario = ?
              ) t
            <sql:param value="${param.id_propuesta}" />
            <sql:param value="${u.nivelFormacion}" />
        </sql:query>
    </c:catch>

    <c:if test="${not empty errorPropuesta}">
        <c:set var="errorValidacion" value="No fue posible validar la propuesta. Verifique la conexión a la base de datos." />
    </c:if>

    <c:if test="${empty errorPropuesta and (empty resPropuestaVal or resPropuestaVal.rowCount == 0)}">
        <c:set var="errorValidacion" value="La propuesta seleccionada ya no está disponible o no corresponde a su nivel de formación." />
    </c:if>
</c:if>

<%-- =========================================================
     4) Dupla: validación del compañero (RF del módulo)
        Debe existir, estar activo, ser del MISMO nivel y no tener
        ya un proyecto.
     ========================================================= --%>
<c:if test="${empty errorValidacion and not empty valorCompanero}">
    <c:catch var="errorCompanero">
        <sql:query var="resCompanero" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT u2.id_usuario,
                         u2.nombres,
                         u2.apellidos,
                         u2.estado_activo,
                         ep.codigo_estudiantil  AS codigo_estudiantil,
                         pa.nivel_formacion     AS nivelFormacion,
                         (SELECT COUNT(*)
                            FROM INTEGRANTES_PROYECTO i2
                           WHERE i2.id_estudiante = u2.id_usuario) AS proyectos
                    FROM ESTUDIANTES_PERFIL ep
                         INNER JOIN USUARIOS u2 ON u2.id_usuario = ep.id_estudiante
                         LEFT  JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                   WHERE ep.codigo_estudiantil = ?
              ) t
            <sql:param value="${valorCompanero}" />
        </sql:query>
    </c:catch>

    <c:choose>

        <c:when test="${not empty errorCompanero}">
            <c:set var="errorValidacion" value="No fue posible validar el código del compañero. Verifique la conexión a la base de datos." />
        </c:when>

        <c:when test="${empty resCompanero or resCompanero.rowCount == 0}">
            <c:set var="errorValidacion" value="El código de compañero no corresponde a ningún estudiante registrado." />
        </c:when>

        <c:when test="${resCompanero.rows[0].id_usuario eq u.id_usuario}">
            <c:set var="errorValidacion" value="El código del compañero no puede ser el suyo." />
        </c:when>

        <%-- estado_activo es BOOLEAN: llega como java.lang.Boolean y no se puede
             comparar con 1/0 en EL (ELException). Se usa su valor lógico. --%>
        <c:when test="${not resCompanero.rows[0].estado_activo}">
            <c:set var="errorValidacion" value="El estudiante indicado como compañero no está activo." />
        </c:when>

        <c:when test="${resCompanero.rows[0].nivelFormacion ne u.nivelFormacion}">
            <c:set var="errorValidacion" value="El compañero debe pertenecer a su mismo nivel de formación." />
        </c:when>

        <c:when test="${resCompanero.rows[0].proyectos gt 0}">
            <c:set var="errorValidacion" value="El estudiante indicado como compañero ya tiene un proyecto de grado registrado." />
        </c:when>

    </c:choose>
</c:if>

<%-- =========================================================
     5) Errores de validación: de vuelta al formulario sin perder
        lo que el estudiante escribió
     ========================================================= --%>
<c:if test="${not empty errorValidacion}">
    <c:redirect url="fase1_registro.jsp">
        <c:param name="error" value="${errorValidacion}" />
        <c:param name="titulo" value="${valorTitulo}" />
        <c:param name="descripcion" value="${param.descripcion}" />
        <c:param name="codigo_companero" value="${valorCompanero}" />
        <c:param name="soporte_pago" value="${valorSoporte}" />
        <c:param name="id_propuesta" value="${param.id_propuesta}" />
    </c:redirect>
</c:if>

<%-- =========================================================
     6) Registro
     ========================================================= --%>
<c:catch var="errorRegistro">

    <%-- ---------- Paso 0: idea propia (RF-09) ---------- --%>
    <c:choose>

        <c:when test="${not empty param.id_propuesta}">
            <c:set var="idPropuestaFinal" value="${param.id_propuesta}" />
        </c:when>

        <c:otherwise>
            <sql:update var="resNuevaPropuesta" dataSource="${db}">
                INSERT INTO PROPUESTAS_PROYECTO
                       (id_creador, titulo, descripcion, nivel_destinatario, estado)
                VALUES (?, ?, ?, ?, 'SELECCIONADA')
                <sql:param value="${u.id_usuario}" />
                <sql:param value="${valorTitulo}" />
                <sql:param value="${param.descripcion}" />
                <sql:param value="${u.nivelFormacion}" />
            </sql:update>

            <sql:query var="resIdPropuesta" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT MAX(p.id_propuesta) AS id_propuesta
                        FROM PROPUESTAS_PROYECTO p
                       WHERE p.id_creador = ?
                  ) t
                <sql:param value="${u.id_usuario}" />
            </sql:query>

            <c:set var="idPropuestaFinal" value="${resIdPropuesta.rows[0].id_propuesta}" />
        </c:otherwise>

    </c:choose>

    <%-- ---------- Paso 1: RF-08, pago de derechos de grado ---------- --%>
    <sql:update var="resPago" dataSource="${db}">
        INSERT INTO PAGOS_PROYECTO
               (id_estudiante, tipo_pago, ruta_comprobante_pdf, estado_pago)
        VALUES (?, 'DERECHOS_GRADO', ?, 'PENDIENTE')
        <sql:param value="${u.id_usuario}" />
        <sql:param value="${valorSoporte}" />
    </sql:update>

    <%-- ---------- Paso 2: proyecto de grado en la Fase 1 ---------- --%>
    <sql:update var="resProyecto" dataSource="${db}">
        INSERT INTO PROYECTOS_GRADO
               (id_propuesta, fase_actual, titulo, estado)
        VALUES (?, 1, ?, 'EN_PROCESO')
        <sql:param value="${idPropuestaFinal}" />
        <sql:param value="${valorTitulo}" />
    </sql:update>

    <sql:query var="resIdProyecto" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT MAX(g.id_proyecto) AS id_proyecto
                FROM PROYECTOS_GRADO g
               WHERE g.id_propuesta = ?
          ) t
        <sql:param value="${idPropuestaFinal}" />
    </sql:query>

    <c:set var="idProyectoFinal" value="${resIdProyecto.rows[0].id_proyecto}" />

    <%-- ---------- Paso 3: el estudiante que registra es el líder ---------- --%>
    <sql:update var="resLider" dataSource="${db}">
        INSERT INTO INTEGRANTES_PROYECTO
               (id_proyecto, id_estudiante, es_lider)
        VALUES (?, ?, 1)
        <sql:param value="${idProyectoFinal}" />
        <sql:param value="${u.id_usuario}" />
    </sql:update>

    <%-- ---------- Paso 4: compañero de la dupla (opcional) ---------- --%>
    <c:if test="${not empty valorCompanero}">
        <sql:update var="resCompaneroIns" dataSource="${db}">
            INSERT INTO INTEGRANTES_PROYECTO
                   (id_proyecto, id_estudiante, es_lider)
            VALUES (?, ?, 0)
            <sql:param value="${idProyectoFinal}" />
            <sql:param value="${resCompanero.rows[0].id_usuario}" />
        </sql:update>
    </c:if>

    <%-- ---------- Paso 5: la propuesta del banco queda SELECCIONADA ---------- --%>
    <c:if test="${not empty param.id_propuesta}">
        <sql:update var="resEstadoPropuesta" dataSource="${db}">
            UPDATE PROPUESTAS_PROYECTO
               SET estado = 'SELECCIONADA'
             WHERE id_propuesta = ?
               AND estado = 'DISPONIBLE'
            <sql:param value="${param.id_propuesta}" />
        </sql:update>
    </c:if>

</c:catch>

<%-- =========================================================
     7) Resultado
     ========================================================= --%>
<c:choose>

    <c:when test="${empty errorRegistro}">
        <c:redirect url="mi_proyecto.jsp">
            <c:param name="msg" value="Proyecto registrado en la Fase 1. El soporte de pago quedó PENDIENTE de revisión por el comité." />
        </c:redirect>
    </c:when>

    <%--
        Si algo falló con la transacción a medias, se avisa sin revelar el
        detalle técnico. JSTL no ofrece transacciones (limitación aceptada).
    --%>
    <c:otherwise>
        <c:redirect url="mi_proyecto.jsp">
            <c:param name="error" value="No fue posible completar el registro de la Fase 1. Verifique la conexión a la base de datos e intente de nuevo." />
        </c:redirect>
    </c:otherwise>

</c:choose>
