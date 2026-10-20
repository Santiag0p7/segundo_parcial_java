<%--
    =====================================================================
    admin_usuarios.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Listado y búsqueda de usuarios para el rol ADMINISTRADOR.

    Acciones disponibles:
      * Buscar por nombre, apellido, correo, documento o código.
      * Filtrar por rol y estado.
      * Crear un usuario nuevo.
      * Editar datos, rol, estado y perfil académico/laboral.
      * Activar o desactivar una cuenta.
      * Restablecer la clave a uts2026.

    La eliminación física no se ofrece: los usuarios están referenciados
    por proyectos, pagos, asignaciones y revisiones. Se usa estado_activo.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso: solo el administrador real
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para administrar usuarios." />
    </c:redirect>
</c:if>

<c:if test="${sessionScope.usuario.rol ne 'ADMINISTRADOR' or not empty sessionScope.adminOriginal}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La gestión de usuarios es exclusiva del rol ADMINISTRADOR." />
    </c:redirect>
</c:if>

<c:set var="pageTitle" value="Gestión de usuarios - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- =========================================================
     2) Filtros (lista blanca)
     ========================================================= --%>
<c:set var="fBuscar" value="${fn:trim(param.buscar)}" />

<c:set var="fRol" value="${param.rol}" />
<c:if test="${fRol ne 'ESTUDIANTE' and fRol ne 'DOCENTE'
              and fRol ne 'COMITE' and fRol ne 'ADMINISTRADOR'}">
    <c:set var="fRol" value="" />
</c:if>

<c:set var="fEstado" value="${param.estado}" />
<c:if test="${fEstado ne '1' and fEstado ne '0'}">
    <c:set var="fEstado" value="" />
</c:if>

<c:set var="hayFiltros" value="${not empty fBuscar or not empty fRol or not empty fEstado}" />

<%-- =========================================================
     3) Consulta de usuarios
     ========================================================= --%>
<c:set var="errorUsuarios" value="" />
<c:catch var="errorUsuarios">
    <sql:query var="resUsuarios" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT u.id_usuario,
                     u.documento_identidad,
                     u.nombres,
                     u.apellidos,
                     u.correo_institucional,
                     u.estado_activo,
                     r.nombre AS rol,
                     ep.codigo_estudiantil,
                     pa.nivel_formacion,
                     dp.especialidad,
                     dp.es_evaluador,
                     (SELECT COUNT(*) FROM INTEGRANTES_PROYECTO i
                       WHERE i.id_estudiante = u.id_usuario) AS proyectos,
                     (SELECT COUNT(*) FROM ASIGNACIONES_DOCENTES a
                       WHERE a.id_docente = u.id_usuario) AS asignaciones
                FROM USUARIOS u
                     INNER JOIN ROLES r ON r.id_rol = u.id_rol
                     LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
                     LEFT JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                     LEFT JOIN DOCENTES_PERFIL dp ON dp.id_docente = u.id_usuario
          ) t
         WHERE (? = '' OR CONCAT_WS(' ', t.nombres, t.apellidos,
                                    t.correo_institucional, t.documento_identidad,
                                    COALESCE(t.codigo_estudiantil, ''))
                           LIKE CONCAT('%', ?, '%'))
           AND (? = '' OR t.rol = ?)
           AND (? = '' OR t.estado_activo = ?)
         ORDER BY t.rol, t.apellidos, t.nombres
        <sql:param value="${fBuscar}" />
        <sql:param value="${fBuscar}" />
        <sql:param value="${fRol}" />
        <sql:param value="${fRol}" />
        <sql:param value="${fEstado}" />
        <sql:param value="${fEstado}" />
    </sql:query>
</c:catch>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-people-fill text-success me-2"></i>Gestión de usuarios
        </h1>
        <p class="text-muted small mb-0">
            Cree cuentas, actualice datos, cambie roles y controle el acceso al sistema.
        </p>
    </div>
    <a href="admin_usuario_form.jsp" class="btn btn-success">
        <i class="bi bi-person-plus-fill me-1"></i>Nuevo usuario
    </a>
</div>

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

<%-- =========================================================
     4) Formulario de búsqueda
     ========================================================= --%>
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body">
        <form method="get" action="admin_usuarios.jsp" class="row g-3 align-items-end">
            <div class="col-12 col-lg-4">
                <label for="buscar" class="form-label small">Buscar</label>
                <input type="text" class="form-control" id="buscar" name="buscar"
                       value="${fn:escapeXml(fBuscar)}"
                       placeholder="Nombre, correo, documento o código" />
            </div>
            <div class="col-6 col-lg-2">
                <label for="rol" class="form-label small">Rol</label>
                <select class="form-select" id="rol" name="rol">
                    <option value="">Todos</option>
                    <option value="ESTUDIANTE" ${fRol eq 'ESTUDIANTE' ? 'selected' : ''}>Estudiante</option>
                    <option value="DOCENTE" ${fRol eq 'DOCENTE' ? 'selected' : ''}>Docente</option>
                    <option value="COMITE" ${fRol eq 'COMITE' ? 'selected' : ''}>Comité</option>
                    <option value="ADMINISTRADOR" ${fRol eq 'ADMINISTRADOR' ? 'selected' : ''}>Administrador</option>
                </select>
            </div>
            <div class="col-6 col-lg-2">
                <label for="estado" class="form-label small">Estado</label>
                <select class="form-select" id="estado" name="estado">
                    <option value="">Todos</option>
                    <option value="1" ${fEstado eq '1' ? 'selected' : ''}>Activo</option>
                    <option value="0" ${fEstado eq '0' ? 'selected' : ''}>Inactivo</option>
                </select>
            </div>
            <div class="col-12 col-lg-4 d-flex gap-2">
                <button type="submit" class="btn btn-success">
                    <i class="bi bi-search me-1"></i>Buscar
                </button>
                <a href="admin_usuarios.jsp" class="btn btn-outline-secondary">
                    <i class="bi bi-eraser me-1"></i>Limpiar
                </a>
            </div>
        </form>
    </div>
</div>

<%-- =========================================================
     5) Resultados
     ========================================================= --%>
<c:choose>

    <c:when test="${not empty errorUsuarios}">
        <div class="alert alert-danger" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            No fue posible consultar los usuarios. Verifique la conexión a la base de datos.
        </div>
    </c:when>

    <c:when test="${empty resUsuarios or resUsuarios.rowCount eq 0}">
        <div class="alert alert-info d-flex align-items-center" role="alert">
            <i class="bi bi-info-circle-fill fs-4 me-3"></i>
            <div>
                <strong>No hay usuarios que coincidan con la búsqueda.</strong><br />
                <span class="small">Cambie los filtros o cree un usuario nuevo.</span>
            </div>
        </div>
    </c:when>

    <c:otherwise>

        <div class="card shadow-sm border-0">
            <div class="card-header bg-white d-flex flex-wrap justify-content-between align-items-center gap-2">
                <span class="fw-semibold">
                    <i class="bi bi-list-ul me-1"></i>
                    <c:out value="${resUsuarios.rowCount}" /> usuario(s)
                </span>
                <c:if test="${hayFiltros}">
                    <span class="badge bg-light text-dark border">Filtros aplicados</span>
                </c:if>
            </div>

            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th scope="col">Documento</th>
                            <th scope="col">Usuario</th>
                            <th scope="col">Rol</th>
                            <th scope="col">Perfil</th>
                            <th scope="col">Estado</th>
                            <th scope="col">Vinculaciones</th>
                            <th scope="col" class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="us" items="${resUsuarios.rows}">

                            <c:set var="claseRol" value="bg-secondary" />
                            <c:choose>
                                <c:when test="${us.rol eq 'ESTUDIANTE'}"><c:set var="claseRol" value="bg-primary" /></c:when>
                                <c:when test="${us.rol eq 'DOCENTE'}"><c:set var="claseRol" value="bg-info text-dark" /></c:when>
                                <c:when test="${us.rol eq 'COMITE'}"><c:set var="claseRol" value="bg-success" /></c:when>
                                <c:when test="${us.rol eq 'ADMINISTRADOR'}"><c:set var="claseRol" value="bg-dark" /></c:when>
                            </c:choose>

                            <tr>
                                <td class="small"><c:out value="${us.documento_identidad}" /></td>
                                <td>
                                    <div class="fw-semibold">
                                        <c:out value="${us.nombres}" /> <c:out value="${us.apellidos}" />
                                    </div>
                                    <div class="small text-muted"><c:out value="${us.correo_institucional}" /></div>
                                </td>
                                <td>
                                    <span class="badge ${claseRol}"><c:out value="${us.rol}" /></span>
                                </td>
                                <td class="small">
                                    <c:choose>
                                        <c:when test="${us.rol eq 'ESTUDIANTE'}">
                                            <c:out value="${empty us.nivel_formacion ? 'Sin nivel' : us.nivel_formacion}" />
                                            <c:if test="${not empty us.codigo_estudiantil}">
                                                <span class="text-muted">· <c:out value="${us.codigo_estudiantil}" /></span>
                                            </c:if>
                                        </c:when>
                                        <c:when test="${us.rol eq 'DOCENTE'}">
                                            <c:out value="${empty us.especialidad ? 'Sin especialidad' : us.especialidad}" />
                                            <c:if test="${us.es_evaluador}">
                                                <span class="badge bg-light text-dark border ms-1">Evaluador</span>
                                            </c:if>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-muted">—</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${us.estado_activo}">
                                            <span class="badge bg-success">Activo</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-secondary">Inactivo</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="small text-muted">
                                    <c:if test="${us.proyectos gt 0}">
                                        <div><i class="bi bi-kanban me-1"></i><c:out value="${us.proyectos}" /> proyecto(s)</div>
                                    </c:if>
                                    <c:if test="${us.asignaciones gt 0}">
                                        <div><i class="bi bi-person-check me-1"></i><c:out value="${us.asignaciones}" /> asignación(es)</div>
                                    </c:if>
                                    <c:if test="${us.proyectos eq 0 and us.asignaciones eq 0}">
                                        <span>—</span>
                                    </c:if>
                                </td>
                                <td class="text-end">
                                    <div class="d-flex flex-wrap justify-content-end gap-1">
                                        <a href="admin_usuario_form.jsp?id_usuario=${us.id_usuario}"
                                           class="btn btn-sm btn-outline-success">
                                            <i class="bi bi-pencil-square me-1"></i>Editar
                                        </a>

                                        <c:choose>
                                            <c:when test="${us.id_usuario eq sessionScope.usuario.id_usuario}">
                                                <span class="badge bg-info text-dark align-self-center">Sesión actual</span>
                                            </c:when>
                                            <c:otherwise>
                                                <form method="post" action="admin_usuario_procesar.jsp" class="d-inline">
                                                    <input type="hidden" name="accion" value="toggle" />
                                                    <input type="hidden" name="id_usuario" value="${us.id_usuario}" />
                                                    <button type="submit"
                                                            class="btn btn-sm ${us.estado_activo ? 'btn-outline-warning' : 'btn-outline-success'}">
                                                        <i class="bi ${us.estado_activo ? 'bi-pause-circle' : 'bi-play-circle'} me-1"></i>
                                                        <c:out value="${us.estado_activo ? 'Desactivar' : 'Activar'}" />
                                                    </button>
                                                </form>
                                            </c:otherwise>
                                        </c:choose>

                                        <form method="post" action="admin_usuario_procesar.jsp" class="d-inline">
                                            <input type="hidden" name="accion" value="reset_clave" />
                                            <input type="hidden" name="id_usuario" value="${us.id_usuario}" />
                                            <button type="submit" class="btn btn-sm btn-outline-secondary">
                                                <i class="bi bi-key me-1"></i>Clave
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>

    </c:otherwise>

</c:choose>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
