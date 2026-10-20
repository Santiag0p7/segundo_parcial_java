<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     BLOQUE 3 - ENTREGABLES_ESTUDIANTE.JSP
     RF-13: el estudiante sube el entregable de la fase actual.

     ESTADOS DEL ENTREGABLE (solo tres):
       * En espera  -> subido, aún sin dictamen final
       * Rechazado  -> algún revisor lo rechazó
       * Validado   -> el comité dio el visto bueno

     REGLA DE RE-SUBIDA: se puede subir otro archivo para la misma
     fase únicamente cuando el último entregable de esa fase quedó
     RECHAZADO. Si está «en espera» o «validado» no se permite.

     La ruta del PDF es simulada (se guarda el texto), como en el
     resto del parcial.

     PRG pattern: procesa el POST arriba, renderiza abajo.
     ========================================================= --%>

<%-- Guard de sesión y rol --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp?error=Debe iniciar sesión" />
</c:if>
<c:if test="${sessionScope.usuario.rol ne 'ESTUDIANTE'}">
    <c:redirect url="dashboard.jsp?error=Solo los estudiantes pueden subir entregables" />
</c:if>

<%-- Proyecto del estudiante (líder) --%>
<sql:query var="miProyecto" dataSource="${db}">
    SELECT g.id_proyecto, g.titulo, g.fase_actual, g.estado
    FROM INTEGRANTES_PROYECTO ip
    INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = ip.id_proyecto
    WHERE ip.id_estudiante = ?
      AND ip.es_lider = 1
    <sql:param value="${sessionScope.usuario.id_usuario}" />
</sql:query>

<c:if test="${miProyecto.rowCount eq 0}">
    <c:redirect url="mi_proyecto.jsp?error=No tienes un proyecto activo" />
</c:if>

<c:set var="proyecto" value="${miProyecto.rows[0]}" />

<%--
    Estado del ÚLTIMO entregable de la fase actual.
    Si no hay fila -> no hay entregable en esa fase.
--%>
<sql:query var="estadoFase" dataSource="${db}">
    SELECT t.*
      FROM (
          SELECT e.id_entregable,
                 e.numero_entregable,
                 (SELECT COUNT(*)
                    FROM REVISIONES_ENTREGABLE r
                   WHERE r.id_entregable = e.id_entregable
                     AND r.string_revisor = 'COMITE'
                     AND r.estado_evaluacion = 'APROBADO') AS comite_ok,
                 (SELECT COUNT(*)
                    FROM REVISIONES_ENTREGABLE r
                   WHERE r.id_entregable = e.id_entregable
                     AND r.estado_evaluacion = 'RECHAZADO') AS rechazos
            FROM ENTREGABLES e
           WHERE e.id_proyecto = ?
             AND e.fase_asociada = ?
           ORDER BY e.id_entregable DESC
           LIMIT 1
      ) t
    <sql:param value="${proyecto.id_proyecto}" />
    <sql:param value="${proyecto.fase_actual}" />
</sql:query>

<%-- ¿Puede subir? (misma regla en el POST y en el render) --%>
<c:set var="puedeSubir" value="${false}" />
<c:set var="motivoBloqueo" value="" />
<c:choose>
    <c:when test="${estadoFase.rowCount eq 0}">
        <c:set var="puedeSubir" value="${true}" />
    </c:when>
    <c:when test="${estadoFase.rows[0].comite_ok gt 0}">
        <c:set var="motivoBloqueo" value="El entregable de la Fase ${proyecto.fase_actual} ya fue validado por el comité." />
    </c:when>
    <c:when test="${estadoFase.rows[0].rechazos gt 0}">
        <c:set var="puedeSubir" value="${true}" />
    </c:when>
    <c:otherwise>
        <c:set var="motivoBloqueo" value="El entregable de la Fase ${proyecto.fase_actual} está en revisión. Espere el dictamen del director y del evaluador." />
    </c:otherwise>
</c:choose>

<%-- =========================================================
     PROCESAMIENTO (POST): subir / re-subir entregable
     ========================================================= --%>
<c:if test="${not empty param.accion and param.accion eq 'subir'}">
    <c:set var="errorValidacion" value="" />

    <c:if test="${empty param.ruta_pdf}">
        <c:set var="errorValidacion" value="Debe proporcionar la ruta del PDF" />
    </c:if>

    <c:if test="${empty errorValidacion and proyecto.estado ne 'EN_PROCESO'}">
        <c:set var="errorValidacion" value="El proyecto no está en estado activo" />
    </c:if>

    <c:if test="${empty errorValidacion and not puedeSubir}">
        <c:set var="errorValidacion" value="${motivoBloqueo}" />
    </c:if>

    <c:choose>
        <c:when test="${empty errorValidacion}">
            <%-- Número consecutivo del entregable para el proyecto --%>
            <sql:query var="maxNumero" dataSource="${db}">
                SELECT COALESCE(MAX(numero_entregable), 0) + 1 AS siguiente
                  FROM ENTREGABLES
                 WHERE id_proyecto = ?
                <sql:param value="${proyecto.id_proyecto}" />
            </sql:query>

            <sql:update dataSource="${db}">
                INSERT INTO ENTREGABLES (id_proyecto, fase_asociada, numero_entregable, ruta_pdf)
                VALUES (?, ?, ?, ?)
                <sql:param value="${proyecto.id_proyecto}" />
                <sql:param value="${proyecto.fase_actual}" />
                <sql:param value="${maxNumero.rows[0].siguiente}" />
                <sql:param value="${param.ruta_pdf}" />
            </sql:update>

            <c:redirect url="entregables_estudiante.jsp?msg=Entregable subido. Quedó en espera de revisión." />
        </c:when>
        <c:otherwise>
            <c:redirect url="entregables_estudiante.jsp">
                <c:param name="error" value="${errorValidacion}" />
            </c:redirect>
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =========================================================
     RENDER (GET)
     ========================================================= --%>
<c:set var="pageTitle" value="Mis Entregables" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="container mt-4">
    <h1 class="mb-4"><i class="bi bi-file-earmark-arrow-up"></i> Mis Entregables</h1>

    <c:if test="${not empty param.msg}">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle"></i> <c:out value="${param.msg}" />
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </c:if>
    <c:if test="${not empty param.error}">
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle"></i> <c:out value="${param.error}" />
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </c:if>

    <%-- Info del proyecto --%>
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-info text-white">
            <h5 class="mb-0"><i class="bi bi-folder-fill"></i> Proyecto: <c:out value="${proyecto.titulo}" /></h5>
        </div>
        <div class="card-body">
            <p class="mb-1"><strong>Fase actual:</strong> <span class="badge bg-primary">Fase <c:out value="${proyecto.fase_actual}" /></span></p>
            <p class="mb-0"><strong>Estado:</strong> <span class="badge bg-success"><c:out value="${proyecto.estado}" /></span></p>
        </div>
    </div>

    <c:choose>
        <%-- Sin entregable en la fase o rechazado: puede subir --%>
        <c:when test="${puedeSubir and proyecto.estado eq 'EN_PROCESO'}">
            <div class="card shadow-sm mb-4 border-primary">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0">
                        <i class="bi bi-upload"></i>
                        <c:choose>
                            <c:when test="${estadoFase.rowCount gt 0}">Subir corrección - Fase <c:out value="${proyecto.fase_actual}" /></c:when>
                            <c:otherwise>Subir entregable - Fase <c:out value="${proyecto.fase_actual}" /></c:otherwise>
                        </c:choose>
                    </h5>
                </div>
                <div class="card-body">
                    <form method="post" action="entregables_estudiante.jsp">
                        <input type="hidden" name="accion" value="subir" />
                        <div class="mb-3">
                            <label for="ruta_pdf" class="form-label">Ruta del PDF:</label>
                            <input type="text" class="form-control" id="ruta_pdf" name="ruta_pdf"
                                   placeholder="documentos/entregable_fase${proyecto.fase_actual}.pdf" required />
                        </div>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-cloud-upload"></i> Subir Entregable
                        </button>
                    </form>
                </div>
            </div>
        </c:when>

        <%-- En espera --%>
        <c:when test="${not empty motivoBloqueo and estadoFase.rows[0].rechazos eq 0}">
            <div class="alert alert-warning d-flex align-items-start" role="alert">
                <i class="bi bi-hourglass-split me-2 mt-1"></i>
                <div><c:out value="${motivoBloqueo}" /></div>
            </div>
        </c:when>
    </c:choose>

    <%-- Historial de entregables --%>
    <sql:query var="entregables" dataSource="${db}">
        SELECT
            e.id_entregable,
            e.fase_asociada,
            e.numero_entregable,
            e.ruta_pdf,
            e.fecha_subida,
            (SELECT COUNT(*)
               FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.string_revisor = 'COMITE'
                AND r.estado_evaluacion = 'APROBADO') AS comite_ok,
            (SELECT COUNT(*)
               FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.estado_evaluacion = 'RECHAZADO') AS rechazos,
            (SELECT r.observaciones
               FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.estado_evaluacion = 'RECHAZADO'
              ORDER BY r.id_revision DESC
              LIMIT 1) AS motivo_rechazo
        FROM ENTREGABLES e
        WHERE e.id_proyecto = ?
        ORDER BY e.fase_asociada DESC, e.numero_entregable DESC
        <sql:param value="${proyecto.id_proyecto}" />
    </sql:query>

    <c:choose>
        <c:when test="${entregables.rowCount eq 0}">
            <div class="alert alert-info">
                <i class="bi bi-inbox"></i> Aún no has subido ningún entregable.
            </div>
        </c:when>
        <c:otherwise>
            <div class="card shadow-sm">
                <div class="card-header bg-secondary text-white">
                    <h5 class="mb-0"><i class="bi bi-list-check"></i> Historial de Entregables</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th>Fase</th>
                                    <th>Ruta PDF</th>
                                    <th>Fecha de Subida</th>
                                    <th>Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="e" items="${entregables.rows}">
                                    <tr>
                                        <td><c:out value="${e.numero_entregable}" /></td>
                                        <td><span class="badge bg-info">Fase <c:out value="${e.fase_asociada}" /></span></td>
                                        <td><code><c:out value="${e.ruta_pdf}" /></code></td>
                                        <td><fmt:formatDate value="${e.fecha_subida}" pattern="dd/MM/yyyy HH:mm" /></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${e.comite_ok gt 0}">
                                                    <span class="badge bg-success"><i class="bi bi-check-circle-fill"></i> Validado</span>
                                                </c:when>
                                                <c:when test="${e.rechazos gt 0}">
                                                    <span class="badge bg-danger"><i class="bi bi-x-circle-fill"></i> Rechazado</span>
                                                    <c:if test="${not empty e.motivo_rechazo}">
                                                        <span class="d-block small text-muted mt-1">
                                                            <c:out value="${e.motivo_rechazo}" />
                                                        </span>
                                                    </c:if>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split"></i> En espera</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </c:otherwise>
    </c:choose>

    <div class="mt-4">
        <a href="mi_proyecto.jsp" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left me-1"></i>Volver a mi proyecto
        </a>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
