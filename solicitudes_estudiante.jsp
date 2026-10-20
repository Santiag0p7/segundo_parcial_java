<%--
    =====================================================================
    solicitudes_estudiante.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 7 (Módulo 5)
    ---------------------------------------------------------------------
    Vista del ESTUDIANTE para gestionar sus solicitudes extraordinarias:

      Formulario A  RF-23: cambio de Director / Evaluador
      Formulario B  RF-25: prórroga con soporte de pago (simulación de PDF)
      Formulario C  RF-28: exoneración Saber TyT / Saber Pro (solo Fase >= 4)
      Formulario D  RF-27: cancelación definitiva del proyecto

    Además muestra el historial (UNION ALL de las tres tablas de
    solicitudes) con su estado PENDIENTE / APROBADA / RECHAZADA.

    NOTAS DE ESQUEMA:
      * SOLICITUDES_PRORROGA exige id_pago (FK NOT NULL): la ruta que escribe
        el estudiante se guarda en PAGOS_PROYECTO (tipo PRORROGA) y la
        solicitud apunta a ese pago. Lo hace procesar_solicitud.jsp.
      * El historial normaliza las tres tablas con UNION ALL y una columna
        `tipo` con un código ASCII (CAMBIO_DOCENTE / PRORROGA /
        EXONERACION_SABER); la tilde se pone al mostrar, con <c:choose>.
      * El selector de docente usa id_asignacion: así no se puede enviar un
        docente que no esté realmente asignado al proyecto, porque el
        servidor vuelve a leer la asignación.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para gestionar sus solicitudes." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'ESTUDIANTE'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="Las solicitudes extraordinarias las radica el estudiante." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Proyecto del estudiante y sus docentes asignados
     ========================================================= --%>
<c:catch var="errorProyecto">
    <sql:query var="resProyecto" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT g.id_proyecto,
                     g.titulo,
                     g.fase_actual,
                     g.estado,
                     g.fecha_registro,
                     f.nombre_fase AS nombre_fase,
                     i.es_lider    AS soy_lider
                FROM INTEGRANTES_PROYECTO i
                     INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
                     LEFT  JOIN FASES_CICLO f     ON f.numero_fase = g.fase_actual
               WHERE i.id_estudiante = ?
               LIMIT 1
          ) t
        <sql:param value="${u.id_usuario}" />
    </sql:query>
</c:catch>

<c:set var="tieneProyecto" value="${empty errorProyecto and not empty resProyecto and resProyecto.rowCount gt 0}" />
<c:if test="${tieneProyecto}">
    <c:set var="proy" value="${resProyecto.rows[0]}" />
</c:if>

<%-- El proyecto está cerrado: no admite solicitudes nuevas --%>
<c:set var="proyectoCerrado" value="${tieneProyecto and (proy.estado eq 'CANCELADO' or proy.estado eq 'EXONERADO' or proy.estado eq 'APROBADO' or proy.estado eq 'RECHAZADO')}" />
<c:set var="puedeSolicitar" value="${tieneProyecto and not proyectoCerrado}" />

<c:if test="${tieneProyecto}">
    <c:catch var="errorAsignaciones">
        <sql:query var="resAsignaciones" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT a.id_asignacion,
                         a.subrol,
                         a.id_docente,
                         u2.nombres    AS nombres_docente,
                         u2.apellidos  AS apellidos_docente,
                         d.especialidad AS especialidad
                    FROM ASIGNACIONES_DOCENTES a
                         INNER JOIN USUARIOS u2 ON u2.id_usuario = a.id_docente
                         LEFT  JOIN DOCENTES_PERFIL d ON d.id_docente = a.id_docente
                   WHERE a.id_proyecto = ?
                   ORDER BY a.subrol
              ) t
            <sql:param value="${proy.id_proyecto}" />
        </sql:query>
    </c:catch>
    <c:set var="hayAsignaciones" value="${empty errorAsignaciones and not empty resAsignaciones and resAsignaciones.rowCount gt 0}" />
</c:if>

<%-- =========================================================
     3) Historial de solicitudes (UNION ALL normalizado)
     ========================================================= --%>
<c:if test="${tieneProyecto}">
    <c:catch var="errorHistorial">
        <sql:query var="resHistorial" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT 'CAMBIO_DOCENTE'        AS tipo,
                         c.id_solicitud          AS id_referencia,
                         c.estado                AS estado,
                         c.fecha_solicitud       AS fecha,
                         c.subrol_afectado       AS detalle
                    FROM SOLICITUDES_CAMBIO_DOCENTE c
                   WHERE c.id_proyecto = ?
                  UNION ALL
                  SELECT 'PRORROGA', p.id_prorroga, p.estado, p.fecha_solicitud,
                         NULL
                    FROM SOLICITUDES_PRORROGA p
                   WHERE p.id_proyecto = ?
                  UNION ALL
                  SELECT 'EXONERACION_SABER', e.id_exoneracion, e.estado,
                         e.fecha_solicitud,
                         CONCAT(e.tipo_prueba, ' / ', e.puntaje_obtenido, ' pts')
                    FROM SOLICITUDES_EXONERACION_SABER e
                   WHERE e.id_proyecto = ?
              ) t
             ORDER BY t.fecha DESC
            <sql:param value="${proy.id_proyecto}" />
            <sql:param value="${proy.id_proyecto}" />
            <sql:param value="${proy.id_proyecto}" />
        </sql:query>
    </c:catch>
</c:if>

<c:set var="pageTitle" value="Solicitudes especiales - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb small">
        <li class="breadcrumb-item"><a href="dashboard.jsp">Panel</a></li>
        <li class="breadcrumb-item"><a href="mi_proyecto.jsp">Mi proyecto</a></li>
        <li class="breadcrumb-item active" aria-current="page">Solicitudes especiales</li>
    </ol>
</nav>

<%-- =========================================================
     4) Mensajes
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

<c:if test="${not empty errorProyecto}">
    <div class="alert alert-warning d-flex align-items-start" role="alert">
        <i class="bi bi-plug-fill me-2 mt-1"></i>
        <div>
            <strong>No fue posible consultar su proyecto.</strong><br />
            <span class="small">Verifique el servicio de base de datos e intente de nuevo.</span>
        </div>
    </div>
</c:if>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-file-earmark-medical text-success me-2"></i>
            Solicitudes extraordinarias
        </h1>
    </div>
    <a href="mi_proyecto.jsp" class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-arrow-left me-1"></i>Volver a mi proyecto
    </a>
</div>

<c:choose>

    <%-- =====================================================
         5.a) Sin proyecto registrado
         ===================================================== --%>
    <c:when test="${not tieneProyecto}">
        <div class="card shadow-sm border-0">
            <div class="card-body text-center py-5">
                <i class="bi bi-folder2-open text-warning display-4"></i>
                <h2 class="h5 mt-3 mb-1">Todavía no tiene un proyecto de grado</h2>
                <a href="mi_proyecto.jsp" class="btn btn-success">
                    <i class="bi bi-kanban-fill me-1"></i>Ir a mi proyecto
                </a>
            </div>
        </div>
    </c:when>

    <%-- =====================================================
         5.b) Con proyecto
         ===================================================== --%>
    <c:otherwise>

        <%-- -------- Resumen del proyecto -------- --%>
        <c:set var="claseEstado" value="bg-secondary" />
        <c:choose>
            <c:when test="${proy.estado eq 'EN_PROCESO'}"><c:set var="claseEstado" value="bg-primary" /></c:when>
            <c:when test="${proy.estado eq 'EXONERADO'}"><c:set var="claseEstado" value="bg-info text-dark" /></c:when>
            <c:when test="${proy.estado eq 'CANCELADO'}"><c:set var="claseEstado" value="bg-danger" /></c:when>
            <c:when test="${proy.estado eq 'APROBADO'}"><c:set var="claseEstado" value="bg-success" /></c:when>
        </c:choose>

        <div class="card shadow-sm border-0 mb-4">
            <div class="card-header bg-white d-flex justify-content-between align-items-start gap-2">
                <h2 class="h6 mb-0">
                    <i class="bi bi-journal-text text-success me-2"></i>
                    <c:out value="${proy.titulo}" />
                </h2>
                <span class="badge flex-shrink-0 ${claseEstado}">
                    <c:out value="${proy.estado}" />
                </span>
            </div>
            <div class="card-body small py-2">
                <span class="text-muted">Fase actual:</span>
                <strong>
                    Fase <c:out value="${proy.fase_actual}" />
                    <c:if test="${not empty proy.nombre_fase}">
                        — <c:out value="${proy.nombre_fase}" />
                    </c:if>
                </strong>
            </div>
        </div>

        <%-- -------- Aviso si el proyecto está cerrado -------- --%>
        <c:if test="${proyectoCerrado}">
            <div class="alert alert-secondary d-flex align-items-start" role="alert">
                <i class="bi bi-lock-fill me-2 mt-1"></i>
                <div>
                    <strong>Su proyecto está cerrado (<c:out value="${proy.estado}" />).</strong><br />
                    <span class="small">
                        No se pueden radicar solicitudes nuevas. Puede consultar el historial
                        de las que ya envió.
                    </span>
                </div>
            </div>
        </c:if>

        <c:if test="${puedeSolicitar}">

            <div class="row row-cols-1 row-cols-lg-2 g-4 mb-4">

                <%-- ================= FORMULARIO A: cambio de docente (RF-23) ================= --%>
                <div class="col">
                    <div class="card h-100 shadow-sm border-0">
                        <div class="card-header bg-white">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-person-gear text-success me-2"></i>
                                Cambio de director o evaluador <span class="badge bg-light text-dark">RF-23</span>
                            </h2>
                        </div>
                        <div class="card-body">
                            <c:choose>
                                <c:when test="${not hayAsignaciones}">
                                    <div class="alert alert-warning small mb-0" role="alert">
                                        <i class="bi bi-exclamation-triangle me-1"></i>
                                        Su proyecto todavía no tiene docentes asignados, así que no hay
                                        un docente afectado que reemplazar.
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <form action="procesar_solicitud.jsp" method="post" accept-charset="UTF-8">
                                        <input type="hidden" name="tipo_solicitud" value="CAMBIO_DOCENTE" />

                                        <div class="mb-2">
                                            <label for="id_asignacion" class="form-label small fw-semibold">
                                                Docente afectado <span class="text-danger">*</span>
                                            </label>
                                            <select class="form-select form-select-sm" id="id_asignacion"
                                                    name="id_asignacion" required>
                                                <c:forEach var="a" items="${resAsignaciones.rows}">
                                                    <option value="${a.id_asignacion}">
                                                        <c:choose>
                                                            <c:when test="${a.subrol eq 'DIRECTOR'}">Director</c:when>
                                                            <c:otherwise>Evaluador</c:otherwise>
                                                        </c:choose>
                                                        — <c:out value="${a.nombres_docente}" /> <c:out value="${a.apellidos_docente}" />
                                                    </option>
                                                </c:forEach>
                                            </select>
                                        </div>

                                        <div class="mb-2">
                                            <label for="just_cambio" class="form-label small fw-semibold">
                                                Justificación <span class="text-danger">*</span>
                                            </label>
                                            <textarea class="form-control form-control-sm" id="just_cambio"
                                                      name="justificacion" rows="3" maxlength="1000" required
                                                      placeholder="Explique por qué solicita el cambio de docente."><c:out value="${param.just_cambio}" /></textarea>
                                        </div>

                                        <button type="submit" class="btn btn-success btn-sm w-100">
                                            <i class="bi bi-send me-1"></i>Radicar solicitud de cambio
                                        </button>
                                    </form>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>

                <%-- ================= FORMULARIO B: prórroga (RF-25) ================= --%>
                <div class="col">
                    <div class="card h-100 shadow-sm border-0">
                        <div class="card-header bg-white">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-calendar-plus text-success me-2"></i>
                                Prórroga del ciclo <span class="badge bg-light text-dark">RF-25</span>
                            </h2>
                        </div>
                        <div class="card-body">
                            <form action="procesar_solicitud.jsp" method="post" accept-charset="UTF-8">
                                <input type="hidden" name="tipo_solicitud" value="PRORROGA" />

                                <div class="mb-2">
                                    <label for="just_prorroga" class="form-label small fw-semibold">
                                        Justificación <span class="text-danger">*</span>
                                    </label>
                                    <textarea class="form-control form-control-sm" id="just_prorroga"
                                              name="justificacion" rows="3" maxlength="1000" required
                                              placeholder="Motivos académicos, laborales o de fuerza mayor."><c:out value="${param.just_prorroga}" /></textarea>
                                </div>

                                <div class="mb-2">
                                    <label for="soporte_pago" class="form-label small fw-semibold">
                                        Soporte de pago de prórroga (PDF) <span class="text-danger">*</span>
                                    </label>
                                    <input type="text" class="form-control form-control-sm" id="soporte_pago"
                                           name="soporte_pago" maxlength="255" required
                                           value="${fn:escapeXml(param.soporte_pago)}"
                                           placeholder="comprobantes/pago-prorroga-2026-001.pdf" />
                                </div>

                                <button type="submit" class="btn btn-success btn-sm w-100">
                                    <i class="bi bi-send me-1"></i>Radicar solicitud de prórroga
                                </button>
                            </form>
                        </div>
                    </div>
                </div>

                <%-- ================= FORMULARIO C: exoneración Saber (RF-28) ================= --%>
                <div class="col">
                    <div class="card h-100 shadow-sm border-0">
                        <div class="card-header bg-white">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-award text-success me-2"></i>
                                Exoneración por pruebas Saber <span class="badge bg-light text-dark">RF-28</span>
                            </h2>
                        </div>
                        <div class="card-body">
                            <c:choose>
                                <c:when test="${proy.fase_actual lt 4}">
                                    <div class="alert alert-secondary small mb-0" role="alert">
                                        <i class="bi bi-lock me-1"></i>
                                        Disponible a partir de la <strong>Fase 4</strong>.
                                        Su proyecto está en la Fase <c:out value="${proy.fase_actual}" />.
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <form action="procesar_solicitud.jsp" method="post" accept-charset="UTF-8">
                                        <input type="hidden" name="tipo_solicitud" value="EXONERACION_SABER" />

                                        <div class="row g-2 mb-2">
                                            <div class="col-7">
                                                <label for="tipo_prueba" class="form-label small fw-semibold">
                                                    Prueba <span class="text-danger">*</span>
                                                </label>
                                                <select class="form-select form-select-sm" id="tipo_prueba"
                                                        name="tipo_prueba" required>
                                                    <option value="SABER_TYT"
                                                        <c:if test="${param.tipo_prueba eq 'SABER_TYT'}">selected</c:if>>
                                                        Saber TyT
                                                    </option>
                                                    <option value="SABER_PRO"
                                                        <c:if test="${param.tipo_prueba eq 'SABER_PRO'}">selected</c:if>>
                                                        Saber Pro
                                                    </option>
                                                </select>
                                            </div>
                                            <div class="col-5">
                                                <label for="puntaje" class="form-label small fw-semibold">
                                                    Puntaje <span class="text-danger">*</span>
                                                </label>
                                                <input type="number" class="form-control form-control-sm" id="puntaje"
                                                       name="puntaje" min="1" max="500" step="1" required
                                                       value="${fn:escapeXml(param.puntaje)}" />
                                            </div>
                                        </div>

                                        <div class="mb-2">
                                            <label for="ruta_certificado" class="form-label small fw-semibold">
                                                Certificado PDF <span class="text-danger">*</span>
                                            </label>
                                            <input type="text" class="form-control form-control-sm" id="ruta_certificado"
                                                   name="ruta_certificado" maxlength="255" required
                                                   value="${fn:escapeXml(param.ruta_certificado)}"
                                                   placeholder="certificados/saber-tyt-2026.pdf" />
                                        </div>

                                        <button type="submit" class="btn btn-success btn-sm w-100">
                                            <i class="bi bi-send me-1"></i>Radicar solicitud de exoneración
                                        </button>
                                    </form>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>

                <%-- ================= FORMULARIO D: cancelación (RF-27) ================= --%>
                <div class="col">
                    <div class="card h-100 shadow-sm border-0 border-start border-danger border-3">
                        <div class="card-header bg-white">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-x-octagon text-danger me-2"></i>
                                Cancelación definitiva <span class="badge bg-light text-dark">RF-27</span>
                            </h2>
                        </div>
                        <div class="card-body d-flex flex-column">
                            <p class="small text-muted mb-3">
                                La cancelación es <strong>definitiva e inmediata</strong>: el proyecto pasa a
                                estado <code>CANCELADO</code> y no se puede reactivar. Si solo necesita más
                                tiempo, solicite una <strong>prórroga</strong>.
                            </p>
                            <button type="button" class="btn btn-outline-danger btn-sm w-100 mt-auto"
                                    data-bs-toggle="modal" data-bs-target="#modalCancelar">
                                <i class="bi bi-x-octagon me-1"></i>Solicitar cancelación del proyecto
                            </button>
                        </div>
                    </div>
                </div>

            </div>

            <%-- -------- Modal de confirmación de cancelación -------- --%>
            <div class="modal fade" id="modalCancelar" tabindex="-1" aria-labelledby="modalCancelarLabel" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content">
                        <form action="procesar_solicitud.jsp" method="post" accept-charset="UTF-8">
                            <input type="hidden" name="tipo_solicitud" value="CANCELACION" />
                            <div class="modal-header bg-danger text-white">
                                <h5 class="modal-title h6" id="modalCancelarLabel">
                                    <i class="bi bi-exclamation-triangle-fill me-2"></i>
                                    Cancelar definitivamente el proyecto
                                </h5>
                                <button type="button" class="btn-close btn-close-white"
                                        data-bs-dismiss="modal" aria-label="Cerrar"></button>
                            </div>
                            <div class="modal-body small">
                                <p class="mb-2">
                                    Va a cancelar el proyecto
                                    <strong><c:out value="${proy.titulo}" /></strong>.
                                </p>
                                <p class="text-muted mb-3">
                                    Esta acción no se puede deshacer.
                                </p>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" value="SI"
                                           id="confirmo" name="confirmo" required />
                                    <label class="form-check-label" for="confirmo">
                                        Confirmo que deseo cancelar definitivamente mi trabajo de grado.
                                    </label>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-outline-secondary btn-sm"
                                        data-bs-dismiss="modal">Volver</button>
                                <button type="submit" class="btn btn-danger btn-sm">
                                    <i class="bi bi-x-octagon me-1"></i>Sí, cancelar el proyecto
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

        </c:if>

        <%-- =====================================================
             Historial de solicitudes
             ===================================================== --%>
        <h2 class="h5 mt-4 mb-2">
            <i class="bi bi-clock-history text-success me-2"></i>Historial de solicitudes
        </h2>

        <c:choose>
            <c:when test="${not empty errorHistorial}">
                <div class="alert alert-warning small" role="alert">
                    No fue posible consultar el historial. Verifique el servicio de base de datos.
                </div>
            </c:when>
            <c:when test="${empty resHistorial or resHistorial.rowCount == 0}">
                <div class="alert alert-light border small mb-0" role="alert">
                    <i class="bi bi-inbox me-1"></i>
                    Aún no ha radicado solicitudes extraordinarias.
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table table-sm align-middle bg-white shadow-sm">
                        <thead class="table-success">
                            <tr>
                                <th scope="col">Tipo de solicitud</th>
                                <th scope="col">Detalle</th>
                                <th scope="col">Fecha</th>
                                <th scope="col">Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="h" items="${resHistorial.rows}">
                                <tr>
                                    <td>
                                        <c:choose>
                                            <c:when test="${h.tipo eq 'CAMBIO_DOCENTE'}">
                                                <i class="bi bi-person-gear text-success me-1"></i>Cambio de docente
                                            </c:when>
                                            <c:when test="${h.tipo eq 'PRORROGA'}">
                                                <i class="bi bi-calendar-plus text-success me-1"></i>Prórroga
                                            </c:when>
                                            <c:when test="${h.tipo eq 'EXONERACION_SABER'}">
                                                <i class="bi bi-award text-success me-1"></i>Exoneración Saber
                                            </c:when>
                                            <c:otherwise>
                                                <c:out value="${h.tipo}" />
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="small text-muted">
                                        <c:choose>
                                            <c:when test="${h.tipo eq 'CAMBIO_DOCENTE' and h.detalle eq 'DIRECTOR'}">
                                                Director
                                            </c:when>
                                            <c:when test="${h.tipo eq 'CAMBIO_DOCENTE' and h.detalle eq 'EVALUADOR'}">
                                                Evaluador
                                            </c:when>
                                            <c:when test="${not empty h.detalle}">
                                                <c:out value="${h.detalle}" />
                                            </c:when>
                                            <c:otherwise>—</c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="small">
                                        <fmt:formatDate value="${h.fecha}" pattern="dd/MM/yyyy HH:mm" />
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${h.estado eq 'APROBADA'}">
                                                <span class="badge bg-success">APROBADA</span>
                                            </c:when>
                                            <c:when test="${h.estado eq 'RECHAZADA'}">
                                                <span class="badge bg-danger">RECHAZADA</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-warning text-dark">PENDIENTE</span>
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

    </c:otherwise>

</c:choose>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
