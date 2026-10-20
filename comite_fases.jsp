<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     BLOQUE 3 - COMITE_FASES.JSP
     RF-16: Comité da visto bueno final a entregables aprobados
     por director y evaluador, y avanza la fase del proyecto.
     
     Flujo: Director aprueba → Evaluador aprueba → Comité revisa
     → Comité aprueba → Avanza fase (+1)
     
     PRG pattern: procesa POST arriba, render abajo.
     ========================================================= --%>

<%-- Guard de sesión y rol --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp?error=Debe iniciar sesión" />
</c:if>
<c:if test="${sessionScope.usuario.rol ne 'COMITE' and sessionScope.usuario.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp?error=Solo el comité puede avanzar fases" />
</c:if>

<%-- =========================================================
     PROCESAMIENTO (POST): Visto bueno del comité
     ========================================================= --%>
<c:if test="${not empty param.accion and (param.accion eq 'aprobar' or param.accion eq 'rechazar')}">
    <c:set var="errorValidacion" value="" />
    
    <%-- Validar parámetros --%>
    <c:if test="${empty param.id_entregable}">
        <c:set var="errorValidacion" value="Falta el ID del entregable" />
    </c:if>
    
    <%-- Obtener el entregable y su proyecto --%>
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
    
    <%-- Validar que director y evaluador hayan aprobado --%>
    <c:if test="${empty errorValidacion}">
        <sql:query var="aprobaciones" dataSource="${db}">
            SELECT 
                SUM(CASE WHEN string_revisor = 'DIRECTOR' AND estado_evaluacion = 'APROBADO' THEN 1 ELSE 0 END) as director_aprobo,
                SUM(CASE WHEN string_revisor = 'EVALUADOR' AND estado_evaluacion = 'APROBADO' THEN 1 ELSE 0 END) as evaluador_aprobo,
                SUM(CASE WHEN string_revisor = 'COMITE' THEN 1 ELSE 0 END) as ya_revision_comite
            FROM REVISIONES_ENTREGABLE
            WHERE id_entregable = ?
            <sql:param value="${param.id_entregable}" />
        </sql:query>
        
        <c:if test="${aprobaciones.rows[0].director_aprobo eq 0 or aprobaciones.rows[0].evaluador_aprobo eq 0}">
            <c:set var="errorValidacion" value="El entregable no ha sido aprobado por director y evaluador" />
        </c:if>
        
        <c:if test="${aprobaciones.rows[0].ya_revision_comite gt 0}">
            <c:set var="errorValidacion" value="El comité ya ha revisado este entregable" />
        </c:if>
    </c:if>
    
    <c:choose>
        <c:when test="${empty errorValidacion}">
            <%-- Determinar el estado de la revisión del comité --%>
            <c:set var="estadoRevision" value="${param.accion eq 'aprobar' ? 'APROBADO' : 'RECHAZADO'}" />
            
            <%-- Registrar revisión del comité --%>
            <sql:update dataSource="${db}">
                INSERT INTO REVISIONES_ENTREGABLE (id_entregable, id_revisor, string_revisor, estado_evaluacion, observaciones)
                VALUES (?, ?, 'COMITE', ?, ?)
                <sql:param value="${param.id_entregable}" />
                <sql:param value="${sessionScope.usuario.id_usuario}" />
                <sql:param value="${estadoRevision}" />
                <sql:param value="${param.observaciones}" />
            </sql:update>
            
            <%-- Si se aprueba, avanzar la fase --%>
            <c:if test="${param.accion eq 'aprobar'}">
                <c:set var="nuevaFase" value="${entregable.rows[0].fase_actual + 1}" />
                
                <%-- Si llega a fase 6, el proyecto queda APROBADO (listo para sustentación) --%>
                <c:choose>
                    <c:when test="${nuevaFase ge 6}">
                        <sql:update dataSource="${db}">
                            UPDATE PROYECTOS_GRADO
                            SET fase_actual = 6, estado = 'APROBADO'
                            WHERE id_proyecto = ?
                            <sql:param value="${entregable.rows[0].id_proyecto}" />
                        </sql:update>
                    </c:when>
                    <c:otherwise>
                        <sql:update dataSource="${db}">
                            UPDATE PROYECTOS_GRADO
                            SET fase_actual = ?
                            WHERE id_proyecto = ?
                            <sql:param value="${nuevaFase}" />
                            <sql:param value="${entregable.rows[0].id_proyecto}" />
                        </sql:update>
                    </c:otherwise>
                </c:choose>
            </c:if>

            <%-- El mensaje se construye con <c:choose>: en EL el signo "+" es
                 suma aritmética, no concatenación de texto (lanzaba
                 NumberFormatException y la página respondía 500). --%>
            <c:choose>
                <c:when test="${param.accion eq 'aprobar'}">
                    <c:set var="mensajeComite" value="Revisión del comité registrada. La fase avanzó a la ${nuevaFase}." />
                </c:when>
                <c:otherwise>
                    <c:set var="mensajeComite" value="Revisión del comité registrada. El entregable quedó rechazado." />
                </c:otherwise>
            </c:choose>

            <c:redirect url="comite_fases.jsp">
                <c:param name="msg" value="${mensajeComite}" />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:redirect url="comite_fases.jsp?error=${errorValidacion}" />
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =========================================================
     RENDER (GET)
     ========================================================= --%>
<c:set var="pageTitle" value="Visto Bueno del Comité - Avance de Fases" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="container mt-4">
    <h1 class="mb-4"><i class="bi bi-shield-check"></i> Visto Bueno del Comité</h1>
    
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
    
    
    <%-- Entregables pendientes del comité (director y evaluador aprobaron) --%>
    <sql:query var="pendientesComite" dataSource="${db}">
        SELECT 
            e.id_entregable,
            e.numero_entregable,
            e.fase_asociada,
            e.ruta_pdf,
            e.fecha_subida,
            g.id_proyecto,
            g.titulo AS proyecto_titulo,
            g.fase_actual AS proyecto_fase,
            u.nombres AS estudiante_nombres,
            u.apellidos AS estudiante_apellidos,
            r_dir.observaciones AS obs_director,
            r_dir.fecha_revision AS fecha_revision_director,
            r_eva.observaciones AS obs_evaluador,
            r_eva.fecha_revision AS fecha_revision_evaluador
        FROM ENTREGABLES e
        INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = e.id_proyecto
        INNER JOIN INTEGRANTES_PROYECTO ip ON ip.id_proyecto = g.id_proyecto AND ip.es_lider = 1
        INNER JOIN USUARIOS u ON u.id_usuario = ip.id_estudiante
        INNER JOIN REVISIONES_ENTREGABLE r_dir ON r_dir.id_entregable = e.id_entregable 
            AND r_dir.string_revisor = 'DIRECTOR' AND r_dir.estado_evaluacion = 'APROBADO'
        INNER JOIN REVISIONES_ENTREGABLE r_eva ON r_eva.id_entregable = e.id_entregable 
            AND r_eva.string_revisor = 'EVALUADOR' AND r_eva.estado_evaluacion = 'APROBADO'
        WHERE g.estado = 'EN_PROCESO'
          AND NOT EXISTS (
              SELECT 1 FROM REVISIONES_ENTREGABLE r
              WHERE r.id_entregable = e.id_entregable
                AND r.string_revisor = 'COMITE'
          )
        ORDER BY e.fecha_subida ASC
    </sql:query>
    
    <c:choose>
        <c:when test="${pendientesComite.rowCount eq 0}">
            <div class="alert alert-info">
                <i class="bi bi-inbox"></i> No hay entregables pendientes de visto bueno del comité.
            </div>
        </c:when>
        <c:otherwise>
            <div class="card shadow-sm border-warning">
                <div class="card-header bg-warning text-dark">
                    <h5 class="mb-0"><i class="bi bi-exclamation-triangle"></i> Pendientes de Visto Bueno (${pendientesComite.rowCount})</h5>
                </div>
                <div class="card-body">
                    <c:forEach var="e" items="${pendientesComite.rows}" varStatus="loop">
                        <div class="card mb-3 ${not loop.last ? 'border-bottom' : ''}">
                            <div class="card-body">
                                <h6 class="card-title">
                                    <c:out value="${e.proyecto_titulo}" />
                                    <span class="badge bg-info ms-2">Fase <c:out value="${e.fase_asociada}" /></span>
                                </h6>
                                <p class="card-text mb-1">
                                    <small class="text-muted">
                                        <i class="bi bi-person"></i> <c:out value="${e.estudiante_nombres} ${e.estudiante_apellidos}" />
                                        &nbsp;|&nbsp;
                                        <i class="bi bi-folder"></i> Entregable #<c:out value="${e.numero_entregable}" />
                                        &nbsp;|&nbsp;
                                        <i class="bi bi-calendar"></i> <fmt:formatDate value="${e.fecha_subida}" pattern="dd/MM/yyyy" />
                                    </small>
                                </p>
                                <p class="card-text mb-2">
                                    <small><i class="bi bi-file-pdf"></i> <code><c:out value="${e.ruta_pdf}" /></code></small>
                                </p>
                                
                                <%-- Observaciones del director --%>
                                <c:if test="${not empty e.obs_director}">
                                    <div class="alert alert-primary py-2 mb-2">
                                        <small>
                                            <i class="bi bi-person-badge"></i> <strong>Director:</strong>
                                            <c:out value="${e.obs_director}" />
                                            <span class="text-muted ms-2">(<fmt:formatDate value="${e.fecha_revision_director}" pattern="dd/MM/yyyy HH:mm" />)</span>
                                        </small>
                                    </div>
                                </c:if>
                                
                                <%-- Observaciones del evaluador --%>
                                <c:if test="${not empty e.obs_evaluador}">
                                    <div class="alert alert-success py-2 mb-2">
                                        <small>
                                            <i class="bi bi-person-check"></i> <strong>Evaluador:</strong>
                                            <c:out value="${e.obs_evaluador}" />
                                            <span class="text-muted ms-2">(<fmt:formatDate value="${e.fecha_revision_evaluador}" pattern="dd/MM/yyyy HH:mm" />)</span>
                                        </small>
                                    </div>
                                </c:if>
                                
                                <%-- Formulario del comité --%>
                                <form method="post" action="comite_fases.jsp" class="mt-2">
                                    <input type="hidden" name="id_entregable" value="${e.id_entregable}" />
                                    <div class="row g-2">
                                        <div class="col-md-8">
                                            <input type="text" name="observaciones" class="form-control form-control-sm" 
                                                   placeholder="Observaciones del comité (opcional)" />
                                        </div>
                                        <div class="col-md-2">
                                            <button type="submit" name="accion" value="aprobar" class="btn btn-success btn-sm w-100">
                                                <i class="bi bi-check-circle"></i> Aprobar
                                            </button>
                                        </div>
                                        <div class="col-md-2">
                                            <button type="submit" name="accion" value="rechazar" class="btn btn-danger btn-sm w-100">
                                                <i class="bi bi-x-circle"></i> Rechazar
                                            </button>
                                        </div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </c:forEach>
                </div>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
