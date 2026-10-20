<%--
    =====================================================================
    admin_suplantar.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Selector de usuarios para que el ADMINISTRADOR pueda "entrar como"
    un estudiante o un docente.

    La suplantación cambia ${sessionScope.usuario} por el usuario elegido
    y guarda el administrador original en ${sessionScope.adminOriginal}.
    El header muestra un aviso con el botón "Volver al panel admin".

    Solo se listan cuentas activas. El administrador no puede suplantar a
    otro administrador.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para entrar como otro usuario." />
    </c:redirect>
</c:if>

<c:if test="${sessionScope.usuario.rol ne 'ADMINISTRADOR' or not empty sessionScope.adminOriginal}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La suplantación de usuarios es exclusiva del rol ADMINISTRADOR." />
    </c:redirect>
</c:if>

<c:set var="pageTitle" value="Entrar como usuario - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-person-badge-fill text-success me-2"></i>Entrar como estudiante o docente
        </h1>
        <p class="text-muted small mb-0">
            Seleccione una cuenta para operar el sistema con su vista. Al terminar, use el botón
            <strong>Volver al panel admin</strong> que aparece en la parte superior.
        </p>
    </div>
    <a href="dashboard_admin.jsp" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left me-1"></i>Volver al panel
    </a>
</div>

<c:if test="${not empty param.error}">
    <div class="alert alert-danger d-flex align-items-start" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
        <div><c:out value="${param.error}" /></div>
    </div>
</c:if>

<%-- =========================================================
     2) Estudiantes activos
     ========================================================= --%>
<c:set var="errorEstudiantes" value="" />
<c:catch var="errorEstudiantes">
    <sql:query var="resEstudiantes" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT u.id_usuario,
                     u.documento_identidad,
                     u.nombres,
                     u.apellidos,
                     u.correo_institucional,
                     ep.codigo_estudiantil,
                     pa.nivel_formacion,
                     g.id_proyecto,
                     g.titulo AS proyecto,
                     g.fase_actual,
                     g.estado AS estado_proyecto
                FROM USUARIOS u
                     INNER JOIN ROLES r ON r.id_rol = u.id_rol
                     LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
                     LEFT JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                     LEFT JOIN INTEGRANTES_PROYECTO i ON i.id_estudiante = u.id_usuario
                     LEFT JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
               WHERE r.nombre = 'ESTUDIANTE'
                 AND u.estado_activo = 1
          ) t
         ORDER BY t.apellidos, t.nombres
    </sql:query>
</c:catch>

<h2 class="h5 mb-3">
    <i class="bi bi-mortarboard-fill text-primary me-2"></i>Estudiantes
</h2>

<c:choose>
    <c:when test="${not empty errorEstudiantes}">
        <div class="alert alert-danger" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            No fue posible consultar los estudiantes.
        </div>
    </c:when>
    <c:when test="${empty resEstudiantes or resEstudiantes.rowCount eq 0}">
        <div class="alert alert-info" role="alert">
            <i class="bi bi-info-circle-fill me-2"></i>
            No hay estudiantes activos para mostrar.
        </div>
    </c:when>
    <c:otherwise>
        <div class="card shadow-sm border-0 mb-4">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th scope="col">Estudiante</th>
                            <th scope="col">Nivel / Código</th>
                            <th scope="col">Proyecto</th>
                            <th scope="col" class="text-end">Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="est" items="${resEstudiantes.rows}">
                            <tr>
                                <td>
                                    <div class="fw-semibold">
                                        <c:out value="${est.nombres}" /> <c:out value="${est.apellidos}" />
                                    </div>
                                    <div class="small text-muted"><c:out value="${est.correo_institucional}" /></div>
                                </td>
                                <td class="small">
                                    <c:out value="${empty est.nivel_formacion ? 'Sin nivel' : est.nivel_formacion}" />
                                    <c:if test="${not empty est.codigo_estudiantil}">
                                        <span class="text-muted">· <c:out value="${est.codigo_estudiantil}" /></span>
                                    </c:if>
                                </td>
                                <td class="small">
                                    <c:choose>
                                        <c:when test="${not empty est.id_proyecto}">
                                            <div class="fw-semibold"><c:out value="${est.proyecto}" /></div>
                                            <span class="badge bg-success">Fase <c:out value="${est.fase_actual}" /></span>
                                            <span class="badge bg-light text-dark border"><c:out value="${est.estado_proyecto}" /></span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-muted">Sin proyecto</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end">
                                    <form method="post" action="admin_impersonar.jsp" class="d-inline">
                                        <input type="hidden" name="id_usuario" value="${est.id_usuario}" />
                                        <button type="submit" class="btn btn-sm btn-primary">
                                            <i class="bi bi-box-arrow-in-right me-1"></i>Entrar como
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>
    </c:otherwise>
</c:choose>

<%-- =========================================================
     3) Docentes activos
     ========================================================= --%>
<c:set var="errorDocentes" value="" />
<c:catch var="errorDocentes">
    <sql:query var="resDocentes" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT u.id_usuario,
                     u.documento_identidad,
                     u.nombres,
                     u.apellidos,
                     u.correo_institucional,
                     dp.especialidad,
                     dp.es_evaluador,
                     (SELECT COUNT(*) FROM ASIGNACIONES_DOCENTES a
                       WHERE a.id_docente = u.id_usuario) AS asignaciones
                FROM USUARIOS u
                     INNER JOIN ROLES r ON r.id_rol = u.id_rol
                     LEFT JOIN DOCENTES_PERFIL dp ON dp.id_docente = u.id_usuario
               WHERE r.nombre = 'DOCENTE'
                 AND u.estado_activo = 1
          ) t
         ORDER BY t.apellidos, t.nombres
    </sql:query>
</c:catch>

<h2 class="h5 mb-3">
    <i class="bi bi-person-workspace text-info me-2"></i>Docentes
</h2>

<c:choose>
    <c:when test="${not empty errorDocentes}">
        <div class="alert alert-danger" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            No fue posible consultar los docentes.
        </div>
    </c:when>
    <c:when test="${empty resDocentes or resDocentes.rowCount eq 0}">
        <div class="alert alert-info" role="alert">
            <i class="bi bi-info-circle-fill me-2"></i>
            No hay docentes activos para mostrar.
        </div>
    </c:when>
    <c:otherwise>
        <div class="card shadow-sm border-0 mb-4">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th scope="col">Docente</th>
                            <th scope="col">Especialidad</th>
                            <th scope="col">Asignaciones</th>
                            <th scope="col" class="text-end">Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="doc" items="${resDocentes.rows}">
                            <tr>
                                <td>
                                    <div class="fw-semibold">
                                        <c:out value="${doc.nombres}" /> <c:out value="${doc.apellidos}" />
                                    </div>
                                    <div class="small text-muted"><c:out value="${doc.correo_institucional}" /></div>
                                </td>
                                <td class="small">
                                    <c:out value="${empty doc.especialidad ? 'Sin especialidad' : doc.especialidad}" />
                                    <c:if test="${doc.es_evaluador}">
                                        <span class="badge bg-light text-dark border ms-1">Evaluador</span>
                                    </c:if>
                                </td>
                                <td class="small">
                                    <c:choose>
                                        <c:when test="${doc.asignaciones gt 0}">
                                            <span class="badge bg-success"><c:out value="${doc.asignaciones}" /></span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-muted">Sin asignaciones</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end">
                                    <form method="post" action="admin_impersonar.jsp" class="d-inline">
                                        <input type="hidden" name="id_usuario" value="${doc.id_usuario}" />
                                        <button type="submit" class="btn btn-sm btn-info text-dark">
                                            <i class="bi bi-box-arrow-in-right me-1"></i>Entrar como
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>
    </c:otherwise>
</c:choose>

<div class="alert alert-light border" role="alert">
    <i class="bi bi-info-circle text-success me-2"></i>
    El módulo de comité ya está disponible directamente en su panel; no necesita suplantar a un usuario de comité.
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
