<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     BLOQUE 3 - COMITE_ASIGNACIONES.JSP
     RF-10: El comité asigna director y evaluador a proyectos
     en Fase 2 (después de aprobar el pago).
     
     PRG pattern: procesa POST arriba, render abajo.
     ========================================================= --%>

<%-- Guard de sesión y rol --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp?error=Debe iniciar sesión" />
</c:if>
<c:if test="${sessionScope.usuario.rol ne 'COMITE' and sessionScope.usuario.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp?error=Solo el comité puede asignar docentes" />
</c:if>

<%-- =========================================================
     PROCESAMIENTO (POST)
     ========================================================= --%>
<c:if test="${not empty param.accion and param.accion eq 'asignar'}">
    <c:set var="errorValidacion" value="" />
    
    <%-- Validar parámetros --%>
    <c:if test="${empty param.id_proyecto or empty param.id_director or empty param.id_evaluador}">
        <c:set var="errorValidacion" value="Todos los campos son obligatorios" />
    </c:if>
    
    <c:if test="${param.id_director eq param.id_evaluador}">
        <c:set var="errorValidacion" value="El director y evaluador no pueden ser la misma persona" />
    </c:if>
    
    <%-- Validar que ambos sean docentes activos --%>
    <c:if test="${empty errorValidacion}">
        <sql:query var="resDocentes" dataSource="${db}">
            SELECT COUNT(*) as total
            FROM USUARIOS
            WHERE id_usuario IN (?, ?)
              AND id_rol = (SELECT id_rol FROM ROLES WHERE nombre = 'DOCENTE')
              AND estado_activo = 1
            <sql:param value="${param.id_director}" />
            <sql:param value="${param.id_evaluador}" />
        </sql:query>
        <c:if test="${resDocentes.rows[0].total ne 2}">
            <c:set var="errorValidacion" value="Uno o ambos docentes no son válidos" />
        </c:if>
    </c:if>
    
    <%-- Validar que el proyecto esté en Fase 2 sin asignaciones --%>
    <c:if test="${empty errorValidacion}">
        <sql:query var="resProyecto" dataSource="${db}">
            SELECT COUNT(*) as total
            FROM PROYECTOS_GRADO g
            WHERE g.id_proyecto = ?
              AND g.fase_actual = 2
              AND g.estado = 'EN_PROCESO'
              AND NOT EXISTS (
                  SELECT 1 FROM ASIGNACIONES_DOCENTES a
                  WHERE a.id_proyecto = g.id_proyecto
              )
            <sql:param value="${param.id_proyecto}" />
        </sql:query>
        <c:if test="${resProyecto.rows[0].total eq 0}">
            <c:set var="errorValidacion" value="El proyecto no está disponible para asignación" />
        </c:if>
    </c:if>
    
    <c:choose>
        <c:when test="${empty errorValidacion}">
            <sql:update dataSource="${db}">
                INSERT INTO ASIGNACIONES_DOCENTES (id_proyecto, id_docente, subrol)
                VALUES (?, ?, 'DIRECTOR')
                <sql:param value="${param.id_proyecto}" />
                <sql:param value="${param.id_director}" />
            </sql:update>
            <sql:update dataSource="${db}">
                INSERT INTO ASIGNACIONES_DOCENTES (id_proyecto, id_docente, subrol)
                VALUES (?, ?, 'EVALUADOR')
                <sql:param value="${param.id_proyecto}" />
                <sql:param value="${param.id_evaluador}" />
            </sql:update>
            <c:redirect url="comite_asignaciones.jsp?msg=Asignación registrada correctamente" />
        </c:when>
        <c:otherwise>
            <c:redirect url="comite_asignaciones.jsp?error=${errorValidacion}" />
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =========================================================
     RENDER (GET)
     ========================================================= --%>
<c:set var="pageTitle" value="Asignación de Docentes - Comité" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="container mt-4">
    <h1 class="mb-4"><i class="bi bi-person-check"></i> Asignación de Director y Evaluador</h1>
    
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
    
    <%-- Lista de proyectos en Fase 2 sin asignar --%>
    <sql:query var="proyectos" dataSource="${db}">
        SELECT 
            g.id_proyecto,
            g.titulo,
            g.fase_actual,
            g.estado,
            u.nombres AS estudiante_nombres,
            u.apellidos AS estudiante_apellidos,
            u.correo_institucional,
            ep.codigo_estudiantil
        FROM PROYECTOS_GRADO g
        INNER JOIN INTEGRANTES_PROYECTO ip ON ip.id_proyecto = g.id_proyecto AND ip.es_lider = 1
        INNER JOIN USUARIOS u ON u.id_usuario = ip.id_estudiante
        LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
        WHERE g.fase_actual = 2
          AND g.estado = 'EN_PROCESO'
          AND NOT EXISTS (
              SELECT 1 FROM ASIGNACIONES_DOCENTES a
              WHERE a.id_proyecto = g.id_proyecto
          )
        ORDER BY g.fecha_registro DESC
    </sql:query>
    
    <c:choose>
        <c:when test="${proyectos.rowCount eq 0}">
            <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> No hay proyectos pendientes de asignación en Fase 2.
            </div>
        </c:when>
        <c:otherwise>
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0"><i class="bi bi-list-check"></i> Proyectos Pendientes (${proyectos.rowCount})</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>ID</th>
                                    <th>Título</th>
                                    <th>Estudiante Líder</th>
                                    <th>Código</th>
                                    <th colspan="3">Asignación de Docentes</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%-- Cargar lista de docentes una vez --%>
                                <sql:query var="docentes" dataSource="${db}">
                                    SELECT id_usuario, nombres, apellidos, correo_institucional
                                    FROM USUARIOS
                                    WHERE id_rol = (SELECT id_rol FROM ROLES WHERE nombre = 'DOCENTE')
                                      AND estado_activo = 1
                                    ORDER BY nombres
                                </sql:query>
                                
                                <c:forEach var="p" items="${proyectos.rows}">
                                    <tr>
                                        <td><c:out value="${p.id_proyecto}" /></td>
                                        <td><c:out value="${p.titulo}" /></td>
                                        <td><c:out value="${p.estudiante_nombres} ${p.estudiante_apellidos}" /></td>
                                        <td><c:out value="${p.codigo_estudiantil}" /></td>
                                        <td colspan="3">
                                            <form method="post" action="comite_asignaciones.jsp" class="d-flex gap-2 align-items-center flex-wrap">
                                                <input type="hidden" name="accion" value="asignar" />
                                                <input type="hidden" name="id_proyecto" value="${p.id_proyecto}" />
                                                <div class="input-group input-group-sm" style="max-width:260px;">
                                                    <span class="input-group-text">Director</span>
                                                    <select name="id_director" class="form-select" required>
                                                        <option value="">-- Seleccionar --</option>
                                                        <c:forEach var="d" items="${docentes.rows}">
                                                            <option value="${d.id_usuario}">
                                                                <c:out value="${d.nombres} ${d.apellidos}" />
                                                            </option>
                                                        </c:forEach>
                                                    </select>
                                                </div>
                                                <div class="input-group input-group-sm" style="max-width:260px;">
                                                    <span class="input-group-text">Evaluador</span>
                                                    <select name="id_evaluador" class="form-select" required>
                                                        <option value="">-- Seleccionar --</option>
                                                        <c:forEach var="d" items="${docentes.rows}">
                                                            <option value="${d.id_usuario}">
                                                                <c:out value="${d.nombres} ${d.apellidos}" />
                                                            </option>
                                                        </c:forEach>
                                                    </select>
                                                </div>
                                                <button type="submit" class="btn btn-success btn-sm">
                                                    <i class="bi bi-check-lg"></i> Asignar
                                                </button>
                                            </form>
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
    
    <%-- Proyectos ya asignados (referencia) --%>
    <sql:query var="asignados" dataSource="${db}">
        SELECT 
            g.id_proyecto,
            g.titulo,
            g.fase_actual,
            dir.nombres AS director_nombres,
            dir.apellidos AS director_apellidos,
            eva.nombres AS evaluador_nombres,
            eva.apellidos AS evaluador_apellidos
        FROM PROYECTOS_GRADO g
        INNER JOIN ASIGNACIONES_DOCENTES ad_dir ON ad_dir.id_proyecto = g.id_proyecto AND ad_dir.subrol = 'DIRECTOR'
        INNER JOIN USUARIOS dir ON dir.id_usuario = ad_dir.id_docente
        INNER JOIN ASIGNACIONES_DOCENTES ad_eva ON ad_eva.id_proyecto = g.id_proyecto AND ad_eva.subrol = 'EVALUADOR'
        INNER JOIN USUARIOS eva ON eva.id_usuario = ad_eva.id_docente
        WHERE g.estado = 'EN_PROCESO'
        ORDER BY g.id_proyecto DESC
        LIMIT 10
    </sql:query>
    
    <c:if test="${asignados.rowCount gt 0}">
        <div class="card shadow-sm mt-4">
            <div class="card-header bg-secondary text-white">
                <h5 class="mb-0"><i class="bi bi-clock-history"></i> Asignaciones Recientes</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Título</th>
                                <th>Fase</th>
                                <th>Director</th>
                                <th>Evaluador</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="a" items="${asignados.rows}">
                                <tr>
                                    <td><c:out value="${a.id_proyecto}" /></td>
                                    <td><c:out value="${a.titulo}" /></td>
                                    <td><span class="badge bg-info">Fase <c:out value="${a.fase_actual}" /></span></td>
                                    <td><c:out value="${a.director_nombres} ${a.director_apellidos}" /></td>
                                    <td><c:out value="${a.evaluador_nombres} ${a.evaluador_apellidos}" /></td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </c:if>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
