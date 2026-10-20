<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     BLOQUE 3 - EVALUACION_DOCENTE.JSP
     RF-14/RF-15: Docentes revisan entregables (Director → Evaluador)
     
     Flujo jerárquico:
     1. Director revisa primero (si no hay revisión de director)
     2. Evaluador revisa después (si director aprobó)
     
     PRG pattern: procesa POST arriba, render abajo.
     ========================================================= --%>

<%-- Guard de sesión y rol --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp?error=Debe iniciar sesión" />
</c:if>
<c:if test="${sessionScope.usuario.rol ne 'DOCENTE'}">
    <c:redirect url="dashboard.jsp?error=Solo los docentes pueden evaluar entregables" />
</c:if>

<%-- =========================================================
     PROCESAMIENTO (POST): Registrar revisión
     ========================================================= --%>
<c:if test="${not empty param.accion and param.accion eq 'revisar'}">
    <c:set var="errorValidacion" value="" />
    
    <%-- Validar parámetros --%>
    <c:if test="${empty param.id_entregable or empty param.estado_evaluacion}">
        <c:set var="errorValidacion" value="Faltan datos obligatorios" />
    </c:if>

    <%-- Solo dos decisiones posibles: aprobar o rechazar --%>
    <c:if test="${empty errorValidacion and param.estado_evaluacion ne 'APROBADO'
                  and param.estado_evaluacion ne 'RECHAZADO'}">
        <c:set var="errorValidacion" value="Decisión no válida" />
    </c:if>
    
    <%-- Obtener el entregable --%>
    <sql:query var="entregable" dataSource="${db}">
        SELECT e.*, g.id_proyecto, g.fase_actual, g.estado
        FROM ENTREGABLES e
        INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
        WHERE e.id_entregable = ?
        <sql:param value="${param.id_entregable}" />
    </sql:query>
    
    <c:if test="${entregable.rowCount eq 0}">
        <c:set var="errorValidacion" value="Entregable no encontrado" />
    </c:if>
    
    <%-- Determinar el rol del docente en este proyecto --%>
    <c:if test="${empty errorValidacion}">
        <sql:query var="miAsignacion" dataSource="${db}">
            SELECT ad.subrol
            FROM ASIGNACIONES_DOCENTES ad
            WHERE ad.id_proyecto = ?
              AND ad.id_docente = ?
            <sql:param value="${entregable.rows[0].id_proyecto}" />
            <sql:param value="${sessionScope.usuario.id_usuario}" />
        </sql:query>
        
        <c:if test="${miAsignacion.rowCount eq 0}">
            <c:set var="errorValidacion" value="No estás asignado a este proyecto" />
        </c:if>
    </c:if>
    
    <%-- Validar que pueda revisar según su rol --%>
    <c:if test="${empty errorValidacion}">
        <c:set var="miRol" value="${miAsignacion.rows[0].subrol}" />
        
        <c:choose>
            <%-- Director: puede revisar si no hay revisión de director --%>
            <c:when test="${miRol eq 'DIRECTOR'}">
                <sql:query var="revisionDirector" dataSource="${db}">
                    SELECT COUNT(*) as total
                    FROM REVISIONES_ENTREGABLE
                    WHERE id_entregable = ?
                      AND string_revisor = 'DIRECTOR'
                    <sql:param value="${param.id_entregable}" />
                </sql:query>
                <c:if test="${revisionDirector.rows[0].total gt 0}">
                    <c:set var="errorValidacion" value="Ya existe una revisión del director para este entregable" />
                </c:if>
            </c:when>
            
            <%-- Evaluador: puede revisar solo si director aprobó --%>
            <c:when test="${miRol eq 'EVALUADOR'}">
                <sql:query var="revisionDirector" dataSource="${db}">
                    SELECT COUNT(*) as total
                    FROM REVISIONES_ENTREGABLE
                    WHERE id_entregable = ?
                      AND string_revisor = 'DIRECTOR'
                      AND estado_evaluacion = 'APROBADO'
                    <sql:param value="${param.id_entregable}" />
                </sql:query>
                <c:if test="${revisionDirector.rows[0].total eq 0}">
                    <c:set var="errorValidacion" value="El director aún no ha aprobado este entregable" />
                </c:if>
                
                <sql:query var="revisionEvaluador" dataSource="${db}">
                    SELECT COUNT(*) as total
                    FROM REVISIONES_ENTREGABLE
                    WHERE id_entregable = ?
                      AND string_revisor = 'EVALUADOR'
                    <sql:param value="${param.id_entregable}" />
                </sql:query>
                <c:if test="${revisionEvaluador.rows[0].total gt 0}">
                    <c:set var="errorValidacion" value="Ya existe una revisión del evaluador para este entregable" />
                </c:if>
            </c:when>
        </c:choose>
    </c:if>
    
    <c:choose>
        <c:when test="${empty errorValidacion}">
            <sql:update dataSource="${db}">
                INSERT INTO REVISIONES_ENTREGABLE (id_entregable, id_revisor, string_revisor, estado_evaluacion, observaciones)
                VALUES (?, ?, ?, ?, ?)
                <sql:param value="${param.id_entregable}" />
                <sql:param value="${sessionScope.usuario.id_usuario}" />
                <sql:param value="${miRol}" />
                <sql:param value="${param.estado_evaluacion}" />
                <sql:param value="${param.observaciones}" />
            </sql:update>
            <c:redirect url="evaluacion_docente.jsp?msg=Revisión registrada correctamente" />
        </c:when>
        <c:otherwise>
            <c:redirect url="evaluacion_docente.jsp?error=${errorValidacion}" />
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =========================================================
     RENDER (GET)
     ========================================================= --%>
<c:set var="pageTitle" value="Evaluación de Entregables" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="container mt-4">
    <h1 class="mb-4"><i class="bi bi-clipboard-check"></i> Evaluación de Entregables</h1>
    
    <%-- Mensajes --%>
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
    
    <%-- Como DIRECTOR: entregables sin revisión de director --%>
    <sql:query var="pendientesDirector" dataSource="${db}">
        SELECT 
            e.id_entregable,
            e.numero_entregable,
            e.fase_asociada,
            e.ruta_pdf,
            e.fecha_subida,
            g.titulo AS proyecto_titulo,
            u.nombres AS estudiante_nombres,
            u.apellidos AS estudiante_apellidos
        FROM ENTREGABLES e
        INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
        INNER JOIN ASIGNACIONES_DOCENTES ad ON ad.id_proyecto = g.id_proyecto AND ad.subrol = 'DIRECTOR'
        INNER JOIN INTEGRANTES_PROYECTO ip ON ip.id_proyecto = g.id_proyecto AND ip.es_lider = 1
        INNER JOIN USUARIOS u ON u.id_usuario = ip.id_estudiante
        WHERE ad.id_docente = ?
          AND g.estado = 'EN_PROCESO'
          AND NOT EXISTS (
              SELECT 1 FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.string_revisor = 'DIRECTOR'
          )
        ORDER BY e.fecha_subida ASC
        <sql:param value="${sessionScope.usuario.id_usuario}" />
    </sql:query>
    
    <c:if test="${pendientesDirector.rowCount gt 0}">
        <div class="card shadow-sm mb-4 border-primary">
            <div class="card-header bg-primary text-white">
                <h5 class="mb-0"><i class="bi bi-person-badge"></i> Pendientes de Revisión como Director (${pendientesDirector.rowCount})</h5>
            </div>
            <div class="card-body">
                <c:forEach var="e" items="${pendientesDirector.rows}" varStatus="loop">
                    <div class="card mb-3 ${not loop.last ? 'border-bottom' : ''}">
                        <div class="card-body">
                            <h6 class="card-title"><c:out value="${e.proyecto_titulo}" /></h6>
                            <p class="card-text mb-1">
                                <small class="text-muted">
                                    <i class="bi bi-person"></i> <c:out value="${e.estudiante_nombres} ${e.estudiante_apellidos}" />
                                    &nbsp;|&nbsp;
                                    <i class="bi bi-folder"></i> Fase <c:out value="${e.fase_asociada}" /> - Entregable #<c:out value="${e.numero_entregable}" />
                                    &nbsp;|&nbsp;
                                    <i class="bi bi-calendar"></i> <fmt:formatDate value="${e.fecha_subida}" pattern="dd/MM/yyyy" />
                                </small>
                            </p>
                            <p class="card-text mb-2">
                                <small><i class="bi bi-file-pdf"></i> <code><c:out value="${e.ruta_pdf}" /></code></small>
                            </p>
                            <form method="post" action="evaluacion_docente.jsp" class="mt-2">
                                <input type="hidden" name="accion" value="revisar" />
                                <input type="hidden" name="id_entregable" value="${e.id_entregable}" />
                                <div class="row g-2">
                                    <div class="col-md-3">
                                        <select name="estado_evaluacion" class="form-select form-select-sm" required>
                                            <option value="">-- Decisión --</option>
                                            <option value="APROBADO">Aprobar</option>
                                            <option value="RECHAZADO">Rechazar</option>
                                        </select>
                                    </div>
                                    <div class="col-md-7">
                                        <input type="text" name="observaciones" class="form-control form-control-sm" 
                                               placeholder="Observaciones (opcional)" />
                                    </div>
                                    <div class="col-md-2">
                                        <button type="submit" class="btn btn-primary btn-sm w-100">
                                            <i class="bi bi-send"></i> Enviar
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>
    </c:if>
    
    <%-- Como EVALUADOR: entregables donde director aprobó, sin revisión de evaluador --%>
    <sql:query var="pendientesEvaluador" dataSource="${db}">
        SELECT 
            e.id_entregable,
            e.numero_entregable,
            e.fase_asociada,
            e.ruta_pdf,
            e.fecha_subida,
            g.titulo AS proyecto_titulo,
            u.nombres AS estudiante_nombres,
            u.apellidos AS estudiante_apellidos,
            r_dir.observaciones AS obs_director,
            r_dir.fecha_revision AS fecha_revision_director
        FROM ENTREGABLES e
        INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
        INNER JOIN ASIGNACIONES_DOCENTES ad ON ad.id_proyecto = g.id_proyecto AND ad.subrol = 'EVALUADOR'
        INNER JOIN INTEGRANTES_PROYECTO ip ON ip.id_proyecto = g.id_proyecto AND ip.es_lider = 1
        INNER JOIN USUARIOS u ON u.id_usuario = ip.id_estudiante
        INNER JOIN REVISIONES_ENTREGABLE r_dir ON r_dir.id_entregable = e.id_entregable 
            AND r_dir.string_revisor = 'DIRECTOR' AND r_dir.estado_evaluacion = 'APROBADO'
        WHERE ad.id_docente = ?
          AND g.estado = 'EN_PROCESO'
          AND NOT EXISTS (
              SELECT 1 FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.string_revisor = 'EVALUADOR'
          )
        ORDER BY e.fecha_subida ASC
        <sql:param value="${sessionScope.usuario.id_usuario}" />
    </sql:query>
    
    <c:if test="${pendientesEvaluador.rowCount gt 0}">
        <div class="card shadow-sm mb-4 border-success">
            <div class="card-header bg-success text-white">
                <h5 class="mb-0"><i class="bi bi-person-check"></i> Pendientes de Revisión como Evaluador (${pendientesEvaluador.rowCount})</h5>
            </div>
            <div class="card-body">
                <c:forEach var="e" items="${pendientesEvaluador.rows}" varStatus="loop">
                    <div class="card mb-3 ${not loop.last ? 'border-bottom' : ''}">
                        <div class="card-body">
                            <h6 class="card-title"><c:out value="${e.proyecto_titulo}" /></h6>
                            <p class="card-text mb-1">
                                <small class="text-muted">
                                    <i class="bi bi-person"></i> <c:out value="${e.estudiante_nombres} ${e.estudiante_apellidos}" />
                                    &nbsp;|&nbsp;
                                    <i class="bi bi-folder"></i> Fase <c:out value="${e.fase_asociada}" /> - Entregable #<c:out value="${e.numero_entregable}" />
                                    &nbsp;|&nbsp;
                                    <i class="bi bi-calendar"></i> <fmt:formatDate value="${e.fecha_subida}" pattern="dd/MM/yyyy" />
                                </small>
                            </p>
                            <p class="card-text mb-2">
                                <small><i class="bi bi-file-pdf"></i> <code><c:out value="${e.ruta_pdf}" /></code></small>
                            </p>
                            <c:if test="${not empty e.obs_director}">
                                <div class="alert alert-info py-2 mb-2">
                                    <small><i class="bi bi-chat-left-text"></i> <strong>Observaciones del Director:</strong> <c:out value="${e.obs_director}" /></small>
                                </div>
                            </c:if>
                            <form method="post" action="evaluacion_docente.jsp" class="mt-2">
                                <input type="hidden" name="accion" value="revisar" />
                                <input type="hidden" name="id_entregable" value="${e.id_entregable}" />
                                <div class="row g-2">
                                    <div class="col-md-3">
                                        <select name="estado_evaluacion" class="form-select form-select-sm" required>
                                            <option value="">-- Decisión --</option>
                                            <option value="APROBADO">Aprobar</option>
                                            <option value="RECHAZADO">Rechazar</option>
                                        </select>
                                    </div>
                                    <div class="col-md-7">
                                        <input type="text" name="observaciones" class="form-control form-control-sm" 
                                               placeholder="Observaciones (opcional)" />
                                    </div>
                                    <div class="col-md-2">
                                        <button type="submit" class="btn btn-success btn-sm w-100">
                                            <i class="bi bi-send"></i> Enviar
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>
    </c:if>
    
    <%-- Si no hay nada pendiente --%>
    <c:if test="${pendientesDirector.rowCount eq 0 and pendientesEvaluador.rowCount eq 0}">
        <div class="alert alert-info">
            <i class="bi bi-check-circle"></i> No tienes entregables pendientes de revisión.
        </div>
    </c:if>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
