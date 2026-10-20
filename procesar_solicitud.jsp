<%--
    =====================================================================
    procesar_solicitud.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 7 (Módulo 5)
    ---------------------------------------------------------------------
    Página de PROCESO (no genera HTML y no escribe nada antes de su
    <c:redirect>). Recibe por POST el parámetro `tipo_solicitud`:

      CAMBIO_DOCENTE      -> INSERT SOLICITUDES_CAMBIO_DOCENTE      (RF-23)
      PRORROGA            -> INSERT PAGOS_PROYECTO (PRORROGA) y
                             INSERT SOLICITUDES_PRORROGA             (RF-25)
      EXONERACION_SABER   -> INSERT SOLICITUDES_EXONERACION_SABER   (RF-28)
      CANCELACION         -> UPDATE PROYECTOS_GRADO estado CANCELADO (RF-27)

    DECISIONES IMPORTANTES:
      * El proyecto NO se recibe por parámetro: se deduce de la sesión
        (INTEGRANTES_PROYECTO). Así nadie puede radicar solicitudes sobre el
        proyecto de otro estudiante manipulando el formulario.
      * SOLICITUDES_PRORROGA.id_pago es NOT NULL con FK: primero se inserta
        el pago con la ruta simulada y luego se recupera su id con MAX(...)
        (LAST_INSERT_ID() no es fiable entre etiquetas <sql:> distintas).
      * Toda validación se repite aquí aunque el formulario ya la haga: el
        HTML se puede saltar.
      * Sin transacciones (JSTL no las ofrece): si falla un INSERT posterior,
        el anterior no se revierte. Se avisa al usuario.
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
        <c:param name="error" value="Debe iniciar sesión para radicar una solicitud." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'ESTUDIANTE'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="Solo los estudiantes pueden radicar solicitudes extraordinarias." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Proyecto del estudiante (nunca desde el formulario)
     ========================================================= --%>
<c:catch var="errorProyecto">
    <sql:query var="resProyecto" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT g.id_proyecto, g.titulo, g.fase_actual, g.estado
                FROM INTEGRANTES_PROYECTO i
                     INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
               WHERE i.id_estudiante = ?
               LIMIT 1
          ) t
        <sql:param value="${u.id_usuario}" />
    </sql:query>
</c:catch>

<c:if test="${not empty errorProyecto}">
    <c:redirect url="solicitudes_estudiante.jsp">
        <c:param name="error" value="No fue posible consultar su proyecto. Verifique la conexión a la base de datos." />
    </c:redirect>
</c:if>

<c:if test="${empty resProyecto or resProyecto.rowCount == 0}">
    <c:redirect url="solicitudes_estudiante.jsp">
        <c:param name="error" value="No tiene un proyecto de grado registrado sobre el cual radicar solicitudes." />
    </c:redirect>
</c:if>

<c:set var="proy" value="${resProyecto.rows[0]}" />

<%-- Un proyecto cerrado no admite solicitudes nuevas --%>
<c:if test="${proy.estado eq 'CANCELADO' or proy.estado eq 'EXONERADO'
              or proy.estado eq 'APROBADO' or proy.estado eq 'RECHAZADO'}">
    <c:redirect url="solicitudes_estudiante.jsp">
        <c:param name="error" value="Su proyecto está cerrado y no admite solicitudes nuevas." />
    </c:redirect>
</c:if>

<%-- =========================================================
     3) Datos del formulario
     ========================================================= --%>
<c:set var="tipo" value="${param.tipo_solicitud}" />
<c:set var="valorJust" value="${fn:trim(param.justificacion)}" />
<c:set var="valorSoporte" value="${fn:trim(param.soporte_pago)}" />
<c:set var="valorRuta" value="${fn:trim(param.ruta_certificado)}" />
<c:set var="errorValidacion" value="" />
<c:set var="puntajeValido" value="${false}" />

<c:choose>

    <%-- =====================================================
         3.a) RF-23: cambio de director / evaluador
         ===================================================== --%>
    <c:when test="${tipo eq 'CAMBIO_DOCENTE'}">

        <c:if test="${empty param.id_asignacion}">
            <c:set var="errorValidacion" value="Debe seleccionar el docente afectado." />
        </c:if>

        <c:if test="${empty errorValidacion and empty valorJust}">
            <c:set var="errorValidacion" value="Debe justificar el cambio de docente." />
        </c:if>

        <c:if test="${empty errorValidacion and fn:length(valorJust) gt 1000}">
            <c:set var="errorValidacion" value="La justificación no puede superar los 1000 caracteres." />
        </c:if>

        <%-- La asignación debe pertenecer al proyecto del estudiante --%>
        <c:if test="${empty errorValidacion}">
            <c:catch var="errorAsignacion">
                <sql:query var="resAsignacionSel" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT a.id_asignacion,
                                 a.id_docente,
                                 a.subrol,
                                 a.id_proyecto
                            FROM ASIGNACIONES_DOCENTES a
                           WHERE a.id_asignacion = ?
                             AND a.id_proyecto = ?
                      ) t
                    <sql:param value="${param.id_asignacion}" />
                    <sql:param value="${proy.id_proyecto}" />
                </sql:query>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorAsignacion}">
                    <c:set var="errorValidacion" value="No fue posible validar el docente seleccionado. Verifique la conexión a la base de datos." />
                </c:when>
                <c:when test="${empty resAsignacionSel or resAsignacionSel.rowCount == 0}">
                    <c:set var="errorValidacion" value="El docente seleccionado no está asignado a su proyecto." />
                </c:when>
                <c:otherwise>
                    <c:set var="asignacionSel" value="${resAsignacionSel.rows[0]}" />
                </c:otherwise>
            </c:choose>
        </c:if>

        <%-- Una sola solicitud pendiente por subrol --%>
        <c:if test="${empty errorValidacion}">
            <c:catch var="errorDuplicado">
                <sql:query var="resDuplicado" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT COUNT(*) AS pendientes
                            FROM SOLICITUDES_CAMBIO_DOCENTE c
                           WHERE c.id_proyecto = ?
                             AND c.subrol_afectado = ?
                             AND c.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${proy.id_proyecto}" />
                    <sql:param value="${asignacionSel.subrol}" />
                </sql:query>
            </c:catch>

            <c:if test="${empty errorDuplicado and resDuplicado.rows[0].pendientes gt 0}">
                <c:set var="errorValidacion" value="Ya tiene una solicitud de cambio pendiente para ese docente. Espere la decisión del comité." />
            </c:if>
        </c:if>

    </c:when>

    <%-- =====================================================
         3.b) RF-25: prórroga con soporte de pago
         ===================================================== --%>
    <c:when test="${tipo eq 'PRORROGA'}">

        <c:if test="${empty valorJust}">
            <c:set var="errorValidacion" value="Debe justificar la solicitud de prórroga." />
        </c:if>

        <c:if test="${empty errorValidacion and fn:length(valorJust) gt 1000}">
            <c:set var="errorValidacion" value="La justificación no puede superar los 1000 caracteres." />
        </c:if>

        <c:if test="${empty errorValidacion and empty valorSoporte}">
            <c:set var="errorValidacion" value="Debe indicar la ruta del soporte de pago de la prórroga en PDF." />
        </c:if>

        <c:if test="${empty errorValidacion and fn:length(valorSoporte) gt 255}">
            <c:set var="errorValidacion" value="La ruta del soporte de pago no puede superar los 255 caracteres." />
        </c:if>

        <c:if test="${empty errorValidacion}">
            <c:catch var="errorDuplicado">
                <sql:query var="resDuplicado" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT COUNT(*) AS pendientes
                            FROM SOLICITUDES_PRORROGA p
                           WHERE p.id_proyecto = ?
                             AND p.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${proy.id_proyecto}" />
                </sql:query>
            </c:catch>

            <c:if test="${empty errorDuplicado and resDuplicado.rows[0].pendientes gt 0}">
                <c:set var="errorValidacion" value="Ya tiene una solicitud de prórroga pendiente de revisión." />
            </c:if>
        </c:if>

    </c:when>

    <%-- =====================================================
         3.c) RF-28: exoneración por pruebas Saber (Fase 4)
         ===================================================== --%>
    <c:when test="${tipo eq 'EXONERACION_SABER'}">

        <c:if test="${proy.fase_actual lt 4}">
            <c:set var="errorValidacion" value="La exoneración por pruebas Saber solo se puede solicitar a partir de la Fase 4." />
        </c:if>

        <c:if test="${empty errorValidacion and param.tipo_prueba ne 'SABER_TYT' and param.tipo_prueba ne 'SABER_PRO'}">
            <c:set var="errorValidacion" value="Debe seleccionar la prueba: Saber TyT o Saber Pro." />
        </c:if>

        <%-- Conversión segura: si el puntaje no es numérico, EL lanza
             ELException y <c:catch> lo convierte en error de validación. --%>
        <c:catch var="errorPuntaje">
            <c:if test="${param.puntaje ge 1 and param.puntaje le 500}">
                <c:set var="puntajeValido" value="${true}" />
            </c:if>
        </c:catch>

        <c:if test="${empty errorValidacion and not puntajeValido}">
            <c:set var="errorValidacion" value="El puntaje debe ser un número entre 1 y 500." />
        </c:if>

        <c:if test="${empty errorValidacion and empty valorRuta}">
            <c:set var="errorValidacion" value="Debe indicar la ruta del certificado PDF de la prueba Saber." />
        </c:if>

        <c:if test="${empty errorValidacion and fn:length(valorRuta) gt 255}">
            <c:set var="errorValidacion" value="La ruta del certificado no puede superar los 255 caracteres." />
        </c:if>

        <c:if test="${empty errorValidacion}">
            <c:catch var="errorDuplicado">
                <sql:query var="resDuplicado" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT COUNT(*) AS pendientes
                            FROM SOLICITUDES_EXONERACION_SABER e
                           WHERE e.id_proyecto = ?
                             AND e.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${proy.id_proyecto}" />
                </sql:query>
            </c:catch>

            <c:if test="${empty errorDuplicado and resDuplicado.rows[0].pendientes gt 0}">
                <c:set var="errorValidacion" value="Ya tiene una solicitud de exoneración pendiente de revisión." />
            </c:if>
        </c:if>

    </c:when>

    <%-- =====================================================
         3.d) RF-27: cancelación definitiva
         ===================================================== --%>
    <c:when test="${tipo eq 'CANCELACION'}">

        <c:if test="${param.confirmo ne 'SI'}">
            <c:set var="errorValidacion" value="Debe confirmar que desea cancelar definitivamente el proyecto." />
        </c:if>

    </c:when>

    <%-- =====================================================
         3.e) Tipo desconocido
         ===================================================== --%>
    <c:otherwise>
        <c:set var="errorValidacion" value="Tipo de solicitud no reconocido." />
    </c:otherwise>

</c:choose>

<%-- =========================================================
     4) Errores: de vuelta al formulario sin perder lo escrito
        (nombres fijos y valores condicionales; un <c:param> con
        nombre dinámico vacío generaría basura en la URL)
     ========================================================= --%>
<c:if test="${not empty errorValidacion}">
    <c:redirect url="solicitudes_estudiante.jsp">
        <c:param name="error" value="${errorValidacion}" />
        <c:param name="just_cambio" value="${tipo eq 'CAMBIO_DOCENTE' ? valorJust : ''}" />
        <c:param name="just_prorroga" value="${tipo eq 'PRORROGA' ? valorJust : ''}" />
        <c:param name="soporte_pago" value="${tipo eq 'PRORROGA' ? valorSoporte : ''}" />
        <c:param name="tipo_prueba" value="${tipo eq 'EXONERACION_SABER' ? param.tipo_prueba : ''}" />
        <c:param name="puntaje" value="${tipo eq 'EXONERACION_SABER' ? param.puntaje : ''}" />
        <c:param name="ruta_certificado" value="${tipo eq 'EXONERACION_SABER' ? valorRuta : ''}" />
    </c:redirect>
</c:if>

<%-- =========================================================
     5) Registro
     ========================================================= --%>
<c:catch var="errorRegistro">

    <c:choose>

        <%-- ---------- RF-23: cambio de docente ---------- --%>
        <c:when test="${tipo eq 'CAMBIO_DOCENTE'}">
            <sql:update var="resInsCambio" dataSource="${db}">
                INSERT INTO SOLICITUDES_CAMBIO_DOCENTE
                       (id_proyecto, id_docente_actual, subrol_afectado, justificacion, estado)
                VALUES (?, ?, ?, ?, 'PENDIENTE')
                <sql:param value="${proy.id_proyecto}" />
                <sql:param value="${asignacionSel.id_docente}" />
                <sql:param value="${asignacionSel.subrol}" />
                <sql:param value="${valorJust}" />
            </sql:update>
            <c:set var="mensajeExito" value="Solicitud de cambio de docente radicada. Quedó PENDIENTE de revisión por el comité." />
        </c:when>

        <%-- ---------- RF-25: prórroga ---------- --%>
        <c:when test="${tipo eq 'PRORROGA'}">

            <%-- Paso 1: el soporte de pago (simulación de PDF) ---------- --%>
            <sql:update var="resPagoProrroga" dataSource="${db}">
                INSERT INTO PAGOS_PROYECTO
                       (id_estudiante, tipo_pago, ruta_comprobante_pdf, estado_pago)
                VALUES (?, 'PRORROGA', ?, 'PENDIENTE')
                <sql:param value="${u.id_usuario}" />
                <sql:param value="${valorSoporte}" />
            </sql:update>

            <%-- Paso 2: id del pago recién creado (LAST_INSERT_ID no es fiable) --%>
            <sql:query var="resIdPago" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT MAX(p.id_pago) AS id_pago
                        FROM PAGOS_PROYECTO p
                       WHERE p.id_estudiante = ?
                         AND p.tipo_pago = 'PRORROGA'
                  ) t
                <sql:param value="${u.id_usuario}" />
            </sql:query>

            <%-- Paso 3: la solicitud, que exige id_pago (FK NOT NULL) ------ --%>
            <sql:update var="resInsProrroga" dataSource="${db}">
                INSERT INTO SOLICITUDES_PRORROGA
                       (id_proyecto, id_pago, justificacion, estado)
                VALUES (?, ?, ?, 'PENDIENTE')
                <sql:param value="${proy.id_proyecto}" />
                <sql:param value="${resIdPago.rows[0].id_pago}" />
                <sql:param value="${valorJust}" />
            </sql:update>
            <c:set var="mensajeExito" value="Solicitud de prórroga radicada con su soporte de pago. Quedó PENDIENTE de revisión por el comité." />
        </c:when>

        <%-- ---------- RF-28: exoneración Saber ---------- --%>
        <c:when test="${tipo eq 'EXONERACION_SABER'}">
            <sql:update var="resInsExoneracion" dataSource="${db}">
                INSERT INTO SOLICITUDES_EXONERACION_SABER
                       (id_proyecto, tipo_prueba, puntaje_obtenido, ruta_certificado_pdf, estado)
                VALUES (?, ?, ?, ?, 'PENDIENTE')
                <sql:param value="${proy.id_proyecto}" />
                <sql:param value="${param.tipo_prueba}" />
                <sql:param value="${param.puntaje}" />
                <sql:param value="${valorRuta}" />
            </sql:update>
            <c:set var="mensajeExito" value="Solicitud de exoneración por pruebas Saber radicada. Quedó PENDIENTE de revisión por el comité." />
        </c:when>

        <%-- ---------- RF-27: cancelación definitiva ---------- --%>
        <c:when test="${tipo eq 'CANCELACION'}">
            <sql:update var="resCancelacion" dataSource="${db}">
                UPDATE PROYECTOS_GRADO
                   SET estado = 'CANCELADO'
                 WHERE id_proyecto = ?
                   AND estado = 'EN_PROCESO'
                <sql:param value="${proy.id_proyecto}" />
            </sql:update>
            <c:set var="mensajeExito" value="El proyecto fue cancelado definitivamente. No se puede reactivar." />
        </c:when>

    </c:choose>

</c:catch>

<%-- =========================================================
     6) Resultado
     ========================================================= --%>
<c:choose>

    <c:when test="${empty errorRegistro}">
        <c:redirect url="solicitudes_estudiante.jsp">
            <c:param name="msg" value="${mensajeExito}" />
        </c:redirect>
    </c:when>

    <c:otherwise>
        <c:redirect url="solicitudes_estudiante.jsp">
            <c:param name="error" value="No fue posible registrar la solicitud. Verifique la conexión a la base de datos e intente de nuevo." />
        </c:redirect>
    </c:otherwise>

</c:choose>
