<%--
    =====================================================================
    comite_solicitudes.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 7 (Módulo 5)
    ---------------------------------------------------------------------
    Vista del COMITE: evalúa y dictamina las solicitudes extraordinarias.

      Sección 1  RF-23 / RF-24: cambio de Director o Evaluador.
                 Al aprobar, reasigna ASIGNACIONES_DOCENTES al docente
                 elegido en el <select>.
      Sección 2  RF-25 / RF-26: prórroga. Permite revisar el comprobante
                 (ruta simulada del PDF) antes de aprobar.
      Sección 3  RF-28 / RF-29: exoneración Saber TyT / Saber Pro. Al
                 aprobar, el proyecto pasa a estado EXONERADO.
      Sección 4  Historial reciente (solo lectura), para que el comité vea
                 el efecto de sus dictámenes.

    PATRÓN: procesa arriba, antes de cualquier salida, y TODO el render
    queda dentro de <c:if test="${empty param.accion}">. Así, cuando se
    atiende un POST, la página solo redirige y no emite ni un byte: escribir
    HTML después de <c:redirect> arriesga IllegalStateException (respuesta
    ya confirmada).

    SEGURIDAD: cada acción revalida en la base de datos que la solicitud
    exista, siga PENDIENTE y pertenezca a la tabla del tipo; los ids del
    formulario no se creen a ciegas.
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
        <c:param name="error" value="Debe iniciar sesión para dictaminar solicitudes." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'COMITE' and u.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="El dictamen de solicitudes corresponde al comité de trabajos de grado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Acciones del comité (solo cuando llega un POST)
     ========================================================= --%>
<c:if test="${not empty param.accion}">

    <c:set var="errorAccion" value="" />
    <c:set var="okAccion" value="${false}" />
    <c:set var="mensajeAccion" value="" />

    <c:choose>

        <%-- =================================================
             2.a) APROBAR cambio de docente (RF-24)
             ================================================= --%>
        <c:when test="${param.accion eq 'aprobar_cambio'}">

            <c:catch var="errorSol">
                <sql:query var="resSol" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT c.id_solicitud, c.id_proyecto, c.id_docente_actual,
                                 c.subrol_afectado
                            FROM SOLICITUDES_CAMBIO_DOCENTE c
                           WHERE c.id_solicitud = ?
                             AND c.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${param.id_solicitud}" />
                </sql:query>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorSol}">
                    <c:set var="errorAccion" value="No fue posible validar la solicitud. Verifique la conexión a la base de datos." />
                </c:when>
                <c:when test="${empty resSol or resSol.rowCount == 0}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>

                    <c:set var="sol" value="${resSol.rows[0]}" />

                    <%-- El docente nuevo debe ser un DOCENTE activo --%>
                    <c:catch var="errorDocente">
                        <sql:query var="resDocenteNuevo" dataSource="${db}">
                            SELECT t.*
                              FROM (
                                  SELECT us.id_usuario
                                    FROM USUARIOS us
                                         INNER JOIN ROLES r ON r.id_rol = us.id_rol
                                         INNER JOIN DOCENTES_PERFIL d ON d.id_docente = us.id_usuario
                                   WHERE us.id_usuario = ?
                                     AND r.nombre = 'DOCENTE'
                                     AND us.estado_activo = 1
                              ) t
                            <sql:param value="${param.id_docente_nuevo}" />
                        </sql:query>
                    </c:catch>

                    <c:choose>
                        <c:when test="${not empty errorDocente}">
                            <c:set var="errorAccion" value="No fue posible validar el docente seleccionado." />
                        </c:when>
                        <c:when test="${empty resDocenteNuevo or resDocenteNuevo.rowCount == 0}">
                            <c:set var="errorAccion" value="Debe seleccionar un docente activo para la reasignación." />
                        </c:when>
                        <c:when test="${resDocenteNuevo.rows[0].id_usuario eq sol.id_docente_actual}">
                            <c:set var="errorAccion" value="El docente seleccionado es el mismo que está asignado actualmente." />
                        </c:when>
                        <c:otherwise>

                            <c:catch var="errorUpdates">
                                <sql:update var="resReasignacion" dataSource="${db}">
                                    UPDATE ASIGNACIONES_DOCENTES
                                       SET id_docente = ?
                                     WHERE id_proyecto = ?
                                       AND subrol = ?
                                    <sql:param value="${resDocenteNuevo.rows[0].id_usuario}" />
                                    <sql:param value="${sol.id_proyecto}" />
                                    <sql:param value="${sol.subrol_afectado}" />
                                </sql:update>

                                <%-- Sin fila previa (proyecto sin asignación de ese
                                     subrol): se crea la asignación. --%>
                                <c:if test="${resReasignacion eq 0}">
                                    <sql:update var="resNuevaAsignacion" dataSource="${db}">
                                        INSERT INTO ASIGNACIONES_DOCENTES
                                               (id_proyecto, id_docente, subrol)
                                        VALUES (?, ?, ?)
                                        <sql:param value="${sol.id_proyecto}" />
                                        <sql:param value="${resDocenteNuevo.rows[0].id_usuario}" />
                                        <sql:param value="${sol.subrol_afectado}" />
                                    </sql:update>
                                </c:if>

                                <sql:update var="resSolAprobada" dataSource="${db}">
                                    UPDATE SOLICITUDES_CAMBIO_DOCENTE
                                       SET estado = 'APROBADA'
                                     WHERE id_solicitud = ?
                                       AND estado = 'PENDIENTE'
                                    <sql:param value="${sol.id_solicitud}" />
                                </sql:update>
                            </c:catch>

                            <c:choose>
                                <c:when test="${empty errorUpdates}">
                                    <c:set var="okAccion" value="${true}" />
                                    <c:set var="mensajeAccion" value="Cambio de docente aprobado y asignación actualizada." />
                                </c:when>
                                <c:otherwise>
                                    <c:set var="errorAccion" value="No fue posible reasignar el docente. Verifique la base de datos." />
                                </c:otherwise>
                            </c:choose>

                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>

        </c:when>

        <%-- =================================================
             2.b) APROBAR prórroga (RF-26)
             ================================================= --%>
        <c:when test="${param.accion eq 'aprobar_prorroga'}">

            <c:catch var="errorSol">
                <sql:query var="resSol" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT p.id_prorroga AS id_solicitud, p.id_proyecto, p.id_pago
                            FROM SOLICITUDES_PRORROGA p
                           WHERE p.id_prorroga = ?
                             AND p.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${param.id_solicitud}" />
                </sql:query>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorSol}">
                    <c:set var="errorAccion" value="No fue posible validar la solicitud. Verifique la conexión a la base de datos." />
                </c:when>
                <c:when test="${empty resSol or resSol.rowCount == 0}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>
                    <c:catch var="errorUpdates">
                        <sql:update var="resProrrogaAprobada" dataSource="${db}">
                            UPDATE SOLICITUDES_PRORROGA
                               SET estado = 'APROBADA'
                             WHERE id_prorroga = ?
                               AND estado = 'PENDIENTE'
                            <sql:param value="${resSol.rows[0].id_solicitud}" />
                        </sql:update>

                        <%-- Aprobar la prórroga implica aceptar el comprobante --%>
                        <sql:update var="resPagoProrroga" dataSource="${db}">
                            UPDATE PAGOS_PROYECTO
                               SET estado_pago = 'APROBADO'
                             WHERE id_pago = ?
                            <sql:param value="${resSol.rows[0].id_pago}" />
                        </sql:update>
                    </c:catch>

                    <c:choose>
                        <c:when test="${empty errorUpdates}">
                            <c:set var="okAccion" value="${true}" />
                            <c:set var="mensajeAccion" value="Prórroga aprobada y pago de prórroga aceptado." />
                        </c:when>
                        <c:otherwise>
                            <c:set var="errorAccion" value="No fue posible aprobar la prórroga. Verifique la base de datos." />
                        </c:otherwise>
                    </c:choose>
                </c:otherwise>
            </c:choose>

        </c:when>

        <%-- =================================================
             2.c) APROBAR exoneración Saber (RF-29)
             ================================================= --%>
        <c:when test="${param.accion eq 'aprobar_exoneracion'}">

            <c:catch var="errorSol">
                <sql:query var="resSol" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT e.id_exoneracion AS id_solicitud, e.id_proyecto
                            FROM SOLICITUDES_EXONERACION_SABER e
                           WHERE e.id_exoneracion = ?
                             AND e.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${param.id_solicitud}" />
                </sql:query>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorSol}">
                    <c:set var="errorAccion" value="No fue posible validar la solicitud. Verifique la conexión a la base de datos." />
                </c:when>
                <c:when test="${empty resSol or resSol.rowCount == 0}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>
                    <c:catch var="errorUpdates">
                        <sql:update var="resExoneracionAprobada" dataSource="${db}">
                            UPDATE SOLICITUDES_EXONERACION_SABER
                               SET estado = 'APROBADA'
                             WHERE id_exoneracion = ?
                               AND estado = 'PENDIENTE'
                            <sql:param value="${resSol.rows[0].id_solicitud}" />
                        </sql:update>

                        <%-- RF-29: el proyecto queda exonerado --%>
                        <sql:update var="resProyectoExonerado" dataSource="${db}">
                            UPDATE PROYECTOS_GRADO
                               SET estado = 'EXONERADO'
                             WHERE id_proyecto = ?
                            <sql:param value="${resSol.rows[0].id_proyecto}" />
                        </sql:update>
                    </c:catch>

                    <c:choose>
                        <c:when test="${empty errorUpdates}">
                            <c:set var="okAccion" value="${true}" />
                            <c:set var="mensajeAccion" value="Exoneración aprobada: el proyecto quedó marcado como EXONERADO." />
                        </c:when>
                        <c:otherwise>
                            <c:set var="errorAccion" value="No fue posible aprobar la exoneración. Verifique la base de datos." />
                        </c:otherwise>
                    </c:choose>
                </c:otherwise>
            </c:choose>

        </c:when>

        <%-- =================================================
             2.d) RECHAZAR (los tres tipos)
             ================================================= --%>
        <c:when test="${param.accion eq 'rechazar_cambio'}">
            <c:catch var="errorUpdates">
                <sql:update var="resRechazo" dataSource="${db}">
                    UPDATE SOLICITUDES_CAMBIO_DOCENTE
                       SET estado = 'RECHAZADA'
                     WHERE id_solicitud = ?
                       AND estado = 'PENDIENTE'
                    <sql:param value="${param.id_solicitud}" />
                </sql:update>
            </c:catch>
            <c:choose>
                <c:when test="${empty errorUpdates and resRechazo gt 0}">
                    <c:set var="okAccion" value="${true}" />
                    <c:set var="mensajeAccion" value="Solicitud de cambio de docente rechazada." />
                </c:when>
                <c:when test="${empty errorUpdates}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>
                    <c:set var="errorAccion" value="No fue posible rechazar la solicitud." />
                </c:otherwise>
            </c:choose>
        </c:when>

        <c:when test="${param.accion eq 'rechazar_prorroga'}">
            <c:catch var="errorSol">
                <sql:query var="resSolPago" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT p.id_prorroga AS id_solicitud, p.id_pago
                            FROM SOLICITUDES_PRORROGA p
                           WHERE p.id_prorroga = ?
                             AND p.estado = 'PENDIENTE'
                      ) t
                    <sql:param value="${param.id_solicitud}" />
                </sql:query>
            </c:catch>
            <c:choose>
                <c:when test="${not empty errorSol or empty resSolPago or resSolPago.rowCount == 0}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>
                    <c:catch var="errorUpdates">
                        <sql:update var="resRechazo" dataSource="${db}">
                            UPDATE SOLICITUDES_PRORROGA
                               SET estado = 'RECHAZADA'
                             WHERE id_prorroga = ?
                               AND estado = 'PENDIENTE'
                            <sql:param value="${resSolPago.rows[0].id_solicitud}" />
                        </sql:update>
                        <sql:update var="resPagoRechazado" dataSource="${db}">
                            UPDATE PAGOS_PROYECTO
                               SET estado_pago = 'RECHAZADO'
                             WHERE id_pago = ?
                            <sql:param value="${resSolPago.rows[0].id_pago}" />
                        </sql:update>
                    </c:catch>
                    <c:choose>
                        <c:when test="${empty errorUpdates}">
                            <c:set var="okAccion" value="${true}" />
                            <c:set var="mensajeAccion" value="Solicitud de prórroga rechazada." />
                        </c:when>
                        <c:otherwise>
                            <c:set var="errorAccion" value="No fue posible rechazar la solicitud." />
                        </c:otherwise>
                    </c:choose>
                </c:otherwise>
            </c:choose>
        </c:when>

        <c:when test="${param.accion eq 'rechazar_exoneracion'}">
            <c:catch var="errorUpdates">
                <sql:update var="resRechazo" dataSource="${db}">
                    UPDATE SOLICITUDES_EXONERACION_SABER
                       SET estado = 'RECHAZADA'
                     WHERE id_exoneracion = ?
                       AND estado = 'PENDIENTE'
                    <sql:param value="${param.id_solicitud}" />
                </sql:update>
            </c:catch>
            <c:choose>
                <c:when test="${empty errorUpdates and resRechazo gt 0}">
                    <c:set var="okAccion" value="${true}" />
                    <c:set var="mensajeAccion" value="Solicitud de exoneración rechazada." />
                </c:when>
                <c:when test="${empty errorUpdates}">
                    <c:set var="errorAccion" value="La solicitud no existe o ya fue dictaminada." />
                </c:when>
                <c:otherwise>
                    <c:set var="errorAccion" value="No fue posible rechazar la solicitud." />
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- =================================================
             2.e) Acción desconocida
             ================================================= --%>
        <c:otherwise>
            <c:set var="errorAccion" value="Acción no reconocida." />
        </c:otherwise>

    </c:choose>

    <%-- ---------- Desenlace del POST ---------- --%>
    <c:choose>
        <c:when test="${okAccion}">
            <c:redirect url="comite_solicitudes.jsp">
                <c:param name="msg" value="${mensajeAccion}" />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:redirect url="comite_solicitudes.jsp">
                <c:param name="error" value="${errorAccion}" />
            </c:redirect>
        </c:otherwise>
    </c:choose>

</c:if>

<c:if test="${empty param.accion}">

    <%-- =========================================================
         3) Datos para las tres secciones
         ========================================================= --%>

    <%-- ---------- 3.1 Cambios de docente pendientes ---------- --%>
    <c:catch var="errorCambios">
        <sql:query var="resCambios" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT c.id_solicitud,
                         c.id_proyecto,
                         c.subrol_afectado,
                         c.justificacion,
                         c.fecha_solicitud,
                         g.titulo               AS titulo_proyecto,
                         g.fase_actual          AS fase_actual,
                         ud.nombres             AS nombres_docente,
                         ud.apellidos           AS apellidos_docente,
                         d.especialidad         AS especialidad
                    FROM SOLICITUDES_CAMBIO_DOCENTE c
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = c.id_proyecto
                         INNER JOIN USUARIOS ud ON ud.id_usuario = c.id_docente_actual
                         LEFT  JOIN DOCENTES_PERFIL d ON d.id_docente = c.id_docente_actual
                   WHERE c.estado = 'PENDIENTE'
              ) t
             ORDER BY t.fecha_solicitud ASC
        </sql:query>
    </c:catch>

    <%-- ---------- 3.2 Docentes disponibles para reasignar ---------- --%>
    <c:catch var="errorDocentes">
        <sql:query var="resDocentes" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT us.id_usuario,
                         us.nombres,
                         us.apellidos,
                         d.especialidad
                    FROM USUARIOS us
                         INNER JOIN ROLES r ON r.id_rol = us.id_rol
                         INNER JOIN DOCENTES_PERFIL d ON d.id_docente = us.id_usuario
                   WHERE r.nombre = 'DOCENTE'
                     AND us.estado_activo = 1
              ) t
             ORDER BY t.nombres, t.apellidos
        </sql:query>
    </c:catch>

    <%-- ---------- 3.3 Prórrogas pendientes ---------- --%>
    <c:catch var="errorProrrogas">
        <sql:query var="resProrrogas" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT p.id_prorroga  AS id_solicitud,
                         p.id_proyecto,
                         p.id_pago,
                         p.justificacion,
                         p.fecha_solicitud,
                         g.titulo        AS titulo_proyecto,
                         g.fase_actual   AS fase_actual,
                         pa.ruta_comprobante_pdf AS ruta_comprobante_pdf,
                         pa.estado_pago  AS estado_pago,
                         est.nombres     AS nombres_solicitante,
                         est.apellidos   AS apellidos_solicitante
                    FROM SOLICITUDES_PRORROGA p
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = p.id_proyecto
                         INNER JOIN PAGOS_PROYECTO pa ON pa.id_pago = p.id_pago
                         INNER JOIN USUARIOS est ON est.id_usuario = pa.id_estudiante
                   WHERE p.estado = 'PENDIENTE'
              ) t
             ORDER BY t.fecha_solicitud ASC
        </sql:query>
    </c:catch>

    <%-- ---------- 3.4 Exoneraciones pendientes ---------- --%>
    <c:catch var="errorExoneraciones">
        <sql:query var="resExoneraciones" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT e.id_exoneracion AS id_solicitud,
                         e.id_proyecto,
                         e.tipo_prueba,
                         e.puntaje_obtenido,
                         e.ruta_certificado_pdf,
                         e.fecha_solicitud,
                         g.titulo      AS titulo_proyecto,
                         g.fase_actual AS fase_actual,
                         g.estado      AS estado_proyecto
                    FROM SOLICITUDES_EXONERACION_SABER e
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
                   WHERE e.estado = 'PENDIENTE'
              ) t
             ORDER BY t.fecha_solicitud ASC
        </sql:query>
    </c:catch>

    <%-- ---------- 3.5 Historial reciente ---------- --%>
    <c:catch var="errorHistorial">
        <sql:query var="resHistorial" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT 'CAMBIO_DOCENTE' AS tipo,
                         c.id_solicitud   AS id_referencia,
                         c.estado         AS estado,
                         c.fecha_solicitud AS fecha,
                         g.titulo         AS titulo_proyecto,
                         c.subrol_afectado AS detalle
                    FROM SOLICITUDES_CAMBIO_DOCENTE c
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = c.id_proyecto
                   WHERE c.estado IN ('APROBADA', 'RECHAZADA')
                  UNION ALL
                  SELECT 'PRORROGA', p.id_prorroga, p.estado, p.fecha_solicitud,
                         g.titulo, NULL
                    FROM SOLICITUDES_PRORROGA p
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = p.id_proyecto
                   WHERE p.estado IN ('APROBADA', 'RECHAZADA')
                  UNION ALL
                  SELECT 'EXONERACION_SABER', e.id_exoneracion, e.estado,
                         e.fecha_solicitud, g.titulo,
                         CONCAT(e.tipo_prueba, ' / ', e.puntaje_obtenido, ' pts')
                    FROM SOLICITUDES_EXONERACION_SABER e
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
                   WHERE e.estado IN ('APROBADA', 'RECHAZADA')
              ) t
             ORDER BY t.fecha DESC
             LIMIT 10
        </sql:query>
    </c:catch>

    <c:set var="pageTitle" value="Solicitudes del comité - UTS" />
    <%@ include file="/WEB-INF/jspf/header.jspf" %>

    <%-- =========================================================
         4) Mensajes del PRG
         ========================================================= --%>
    <c:if test="${not empty param.msg}">
        <div class="alert alert-success d-flex align-items-start" role="alert">
            <i class="bi bi-check-circle-fill me-2 mt-1"></i>
            <div><c:out value="${param.msg}" /></div>
        </div>
    </c:if>

    <c:if test="${not empty param.error}">
        <div class="alert alert-danger d-flex align-items-start" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
            <div><c:out value="${param.error}" /></div>
        </div>
    </c:if>

    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
        <div>
            <h1 class="h4 mb-1">
                <i class="bi bi-file-earmark-check text-success me-2"></i>
                Solicitudes extraordinarias
            </h1>
            <p class="text-muted small mb-0">
                Dictamen de cambio de docente, prórrogas y exoneraciones por pruebas Saber.
            </p>
        </div>
        <a href="dashboard.jsp" class="btn btn-outline-secondary btn-sm">
            <i class="bi bi-speedometer2 me-1"></i>Volver al panel
        </a>
    </div>

    <c:if test="${not empty errorCambios or not empty errorProrrogas or not empty errorExoneraciones}">
        <div class="alert alert-warning d-flex align-items-start" role="alert">
            <i class="bi bi-plug-fill me-2 mt-1"></i>
            <div>
                <strong>Algunas secciones no se pudieron consultar.</strong><br />
                <span class="small">Verifique el servicio de base de datos e intente de nuevo.</span>
            </div>
        </div>
    </c:if>

    <%-- =========================================================
         5) Sección 1: cambios de docente (RF-23 / RF-24)
         ========================================================= --%>
    <div class="card shadow-sm border-0 mb-4 border-start border-success border-3">
        <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h2 class="h6 mb-0">
                <i class="bi bi-person-gear text-success me-2"></i>
                1. Cambios de director o evaluador
            </h2>
            <span class="badge bg-warning text-dark">
                <c:out value="${empty resCambios ? 0 : resCambios.rowCount}" /> pendiente(s)
            </span>
        </div>

        <div class="card-body">
            <c:choose>
                <c:when test="${not empty errorCambios}">
                    <p class="text-muted small mb-0">No fue posible consultar esta sección.</p>
                </c:when>
                <c:when test="${empty resCambios or resCambios.rowCount == 0}">
                    <p class="text-muted small mb-0">
                        <i class="bi bi-check2-circle me-1"></i>No hay solicitudes de cambio pendientes.
                    </p>
                </c:when>
                <c:otherwise>
                    <c:forEach var="s" items="${resCambios.rows}">
                        <div class="border rounded p-3 mb-3">
                            <div class="d-flex flex-wrap justify-content-between gap-2 mb-2">
                                <div>
                                    <strong><c:out value="${s.titulo_proyecto}" /></strong>
                                    <span class="badge bg-secondary ms-1">Fase <c:out value="${s.fase_actual}" /></span>
                                </div>
                                <span class="small text-muted">
                                    <fmt:formatDate value="${s.fecha_solicitud}" pattern="dd/MM/yyyy HH:mm" />
                                </span>
                            </div>

                            <div class="row g-3 small mb-3">
                                <div class="col-12 col-md-6">
                                    <span class="text-muted d-block">Docente afectado</span>
                                    <c:choose>
                                        <c:when test="${s.subrol_afectado eq 'DIRECTOR'}">
                                            <span class="badge bg-success">Director</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-info text-dark">Evaluador</span>
                                        </c:otherwise>
                                    </c:choose>
                                    <c:out value="${s.nombres_docente}" /> <c:out value="${s.apellidos_docente}" />
                                    <c:if test="${not empty s.especialidad}">
                                        <span class="text-muted d-block">(<c:out value="${s.especialidad}" />)</span>
                                    </c:if>
                                </div>
                                <div class="col-12 col-md-6">
                                    <span class="text-muted d-block">Justificación del estudiante</span>
                                    <span style="white-space: pre-wrap;"><c:out value="${s.justificacion}" /></span>
                                </div>
                            </div>

                            <div class="row g-2">
                                <div class="col-12 col-lg-8">
                                    <form action="comite_solicitudes.jsp" method="post"
                                          class="d-flex flex-column flex-sm-row gap-2">
                                        <input type="hidden" name="id_solicitud" value="${s.id_solicitud}" />
                                        <select class="form-select form-select-sm" name="id_docente_nuevo" required>
                                            <option value="">— Reasignar a… —</option>
                                            <c:forEach var="d" items="${resDocentes.rows}">
                                                <option value="${d.id_usuario}">
                                                    <c:out value="${d.nombres}" /> <c:out value="${d.apellidos}" />
                                                    <c:if test="${not empty d.especialidad}">
                                                        — <c:out value="${d.especialidad}" />
                                                    </c:if>
                                                </option>
                                            </c:forEach>
                                        </select>
                                        <button type="submit" name="accion" value="aprobar_cambio"
                                                class="btn btn-success btn-sm text-nowrap">
                                            <i class="bi bi-check2-circle me-1"></i>Aprobar y reasignar
                                        </button>
                                    </form>
                                </div>
                                <div class="col-12 col-lg-4">
                                    <form action="comite_solicitudes.jsp" method="post"
                                          onsubmit="return confirm('¿Confirma el rechazo de esta solicitud?');">
                                        <input type="hidden" name="id_solicitud" value="${s.id_solicitud}" />
                                        <button type="submit" name="accion" value="rechazar_cambio"
                                                class="btn btn-outline-danger btn-sm w-100">
                                            <i class="bi bi-x-circle me-1"></i>Rechazar
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <%-- =========================================================
         6) Sección 2: prórrogas (RF-25 / RF-26)
         ========================================================= --%>
    <div class="card shadow-sm border-0 mb-4 border-start border-warning border-3">
        <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h2 class="h6 mb-0">
                <i class="bi bi-calendar-plus text-success me-2"></i>
                2. Prórrogas del ciclo
            </h2>
            <span class="badge bg-warning text-dark">
                <c:out value="${empty resProrrogas ? 0 : resProrrogas.rowCount}" /> pendiente(s)
            </span>
        </div>

        <div class="card-body">
            <c:choose>
                <c:when test="${not empty errorProrrogas}">
                    <p class="text-muted small mb-0">No fue posible consultar esta sección.</p>
                </c:when>
                <c:when test="${empty resProrrogas or resProrrogas.rowCount == 0}">
                    <p class="text-muted small mb-0">
                        <i class="bi bi-check2-circle me-1"></i>No hay solicitudes de prórroga pendientes.
                    </p>
                </c:when>
                <c:otherwise>
                    <c:forEach var="s" items="${resProrrogas.rows}">
                        <div class="border rounded p-3 mb-3">
                            <div class="d-flex flex-wrap justify-content-between gap-2 mb-2">
                                <div>
                                    <strong><c:out value="${s.titulo_proyecto}" /></strong>
                                    <span class="badge bg-secondary ms-1">Fase <c:out value="${s.fase_actual}" /></span>
                                </div>
                                <span class="small text-muted">
                                    <fmt:formatDate value="${s.fecha_solicitud}" pattern="dd/MM/yyyy HH:mm" />
                                </span>
                            </div>

                            <div class="row g-3 small mb-3">
                                <div class="col-12 col-md-6">
                                    <span class="text-muted d-block">Justificación</span>
                                    <span style="white-space: pre-wrap;"><c:out value="${s.justificacion}" /></span>
                                </div>
                                <div class="col-12 col-md-6">
                                    <span class="text-muted d-block">Soporte de pago (simulación PDF)</span>
                                    <i class="bi bi-file-earmark-pdf-fill text-danger me-1"></i>
                                    <a href="${fn:escapeXml(fn:startsWith(s.ruta_comprobante_pdf, 'http') ? s.ruta_comprobante_pdf : pdfDemo)}" target="_blank"
                                       title="Comprobante de pago">
                                        <c:out value="${s.ruta_comprobante_pdf}" />
                                    </a>
                                    <span class="text-muted d-block">
                                        Solicitante:
                                        <c:out value="${s.nombres_solicitante}" />
                                        <c:out value="${s.apellidos_solicitante}" />
                                    </span>
                                </div>
                            </div>

                            <form action="comite_solicitudes.jsp" method="post" class="d-flex flex-wrap gap-2">
                                <input type="hidden" name="id_solicitud" value="${s.id_solicitud}" />
                                <button type="submit" name="accion" value="aprobar_prorroga"
                                        class="btn btn-success btn-sm">
                                    <i class="bi bi-check2-circle me-1"></i>Aprobar prórroga
                                </button>
                                <button type="submit" name="accion" value="rechazar_prorroga"
                                        class="btn btn-outline-danger btn-sm"
                                        onclick="return confirm('¿Confirma el rechazo de esta prórroga?');">
                                    <i class="bi bi-x-circle me-1"></i>Rechazar
                                </button>
                            </form>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <%-- =========================================================
         7) Sección 3: exoneraciones Saber (RF-28 / RF-29)
         ========================================================= --%>
    <div class="card shadow-sm border-0 mb-4 border-start border-info border-3">
        <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h2 class="h6 mb-0">
                <i class="bi bi-award text-success me-2"></i>
                3. Exoneraciones por pruebas Saber TyT / Pro
            </h2>
            <span class="badge bg-warning text-dark">
                <c:out value="${empty resExoneraciones ? 0 : resExoneraciones.rowCount}" /> pendiente(s)
            </span>
        </div>

        <div class="card-body">
            <c:choose>
                <c:when test="${not empty errorExoneraciones}">
                    <p class="text-muted small mb-0">No fue posible consultar esta sección.</p>
                </c:when>
                <c:when test="${empty resExoneraciones or resExoneraciones.rowCount == 0}">
                    <p class="text-muted small mb-0">
                        <i class="bi bi-check2-circle me-1"></i>No hay solicitudes de exoneración pendientes.
                    </p>
                </c:when>
                <c:otherwise>
                    <c:forEach var="s" items="${resExoneraciones.rows}">
                        <div class="border rounded p-3 mb-3">
                            <div class="d-flex flex-wrap justify-content-between gap-2 mb-2">
                                <div>
                                    <strong><c:out value="${s.titulo_proyecto}" /></strong>
                                    <span class="badge bg-secondary ms-1">Fase <c:out value="${s.fase_actual}" /></span>
                                    <c:if test="${s.estado_proyecto eq 'EXONERADO'}">
                                        <span class="badge bg-info text-dark ms-1">Ya exonerado</span>
                                    </c:if>
                                </div>
                                <span class="small text-muted">
                                    <fmt:formatDate value="${s.fecha_solicitud}" pattern="dd/MM/yyyy HH:mm" />
                                </span>
                            </div>

                            <div class="row g-3 small mb-3">
                                <div class="col-6 col-md-3">
                                    <span class="text-muted d-block">Prueba</span>
                                    <c:choose>
                                        <c:when test="${s.tipo_prueba eq 'SABER_TYT'}">
                                            <span class="badge bg-primary">Saber TyT</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-primary">Saber Pro</span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                                <div class="col-6 col-md-2">
                                    <span class="text-muted d-block">Puntaje</span>
                                    <strong><c:out value="${s.puntaje_obtenido}" /></strong>
                                </div>
                                <div class="col-12 col-md-7">
                                    <span class="text-muted d-block">Certificado (simulación PDF)</span>
                                    <i class="bi bi-file-earmark-pdf-fill text-danger me-1"></i>
                                    <a href="${fn:escapeXml(fn:startsWith(s.ruta_certificado_pdf, 'http') ? s.ruta_certificado_pdf : pdfDemo)}" target="_blank"
                                       title="Certificado de la prueba Saber">
                                        <c:out value="${s.ruta_certificado_pdf}" />
                                    </a>
                                </div>
                            </div>

                            <form action="comite_solicitudes.jsp" method="post" class="d-flex flex-wrap gap-2">
                                <input type="hidden" name="id_solicitud" value="${s.id_solicitud}" />
                                <button type="submit" name="accion" value="aprobar_exoneracion"
                                        class="btn btn-success btn-sm"
                                        onclick="return confirm('¿Confirma la exoneración? El proyecto quedará marcado como EXONERADO.');">
                                    <i class="bi bi-check2-circle me-1"></i>Aprobar y exonerar
                                </button>
                                <button type="submit" name="accion" value="rechazar_exoneracion"
                                        class="btn btn-outline-danger btn-sm"
                                        onclick="return confirm('¿Confirma el rechazo de esta exoneración?');">
                                    <i class="bi bi-x-circle me-1"></i>Rechazar
                                </button>
                            </form>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <%-- =========================================================
         8) Sección 4: historial reciente (solo lectura)
         ========================================================= --%>
    <h2 class="h5 mb-2">
        <i class="bi bi-clock-history text-success me-2"></i>Historial reciente
    </h2>

    <c:choose>
        <c:when test="${not empty errorHistorial}">
            <div class="alert alert-warning small" role="alert">
                No fue posible consultar el historial.
            </div>
        </c:when>
        <c:when test="${empty resHistorial or resHistorial.rowCount == 0}">
            <div class="alert alert-light border small mb-0" role="alert">
                <i class="bi bi-inbox me-1"></i>Aún no hay solicitudes dictaminadas.
            </div>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table table-sm align-middle bg-white shadow-sm">
                    <thead class="table-success">
                        <tr>
                            <th scope="col">Tipo</th>
                            <th scope="col">Proyecto</th>
                            <th scope="col">Detalle</th>
                            <th scope="col">Fecha</th>
                            <th scope="col">Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="h" items="${resHistorial.rows}">
                            <tr>
                                <td class="small">
                                    <c:choose>
                                        <c:when test="${h.tipo eq 'CAMBIO_DOCENTE'}">Cambio de docente</c:when>
                                        <c:when test="${h.tipo eq 'PRORROGA'}">Prórroga</c:when>
                                        <c:when test="${h.tipo eq 'EXONERACION_SABER'}">Exoneración Saber</c:when>
                                        <c:otherwise><c:out value="${h.tipo}" /></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="small"><c:out value="${h.titulo_proyecto}" /></td>
                                <td class="small text-muted">
                                    <c:choose>
                                        <c:when test="${h.tipo eq 'CAMBIO_DOCENTE' and h.detalle eq 'DIRECTOR'}">Director</c:when>
                                        <c:when test="${h.tipo eq 'CAMBIO_DOCENTE' and h.detalle eq 'EVALUADOR'}">Evaluador</c:when>
                                        <c:when test="${not empty h.detalle}"><c:out value="${h.detalle}" /></c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="small">
                                    <fmt:formatDate value="${h.fecha}" pattern="dd/MM/yyyy" />
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${h.estado eq 'APROBADA'}">
                                            <span class="badge bg-success">APROBADA</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-danger">RECHAZADA</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>

    <%@ include file="/WEB-INF/jspf/footer.jspf" %>

</c:if>
