<%--
    =====================================================================
    admin_usuario_form.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Formulario de creación y edición de usuarios para el ADMINISTRADOR.

    * Sin id_usuario: crea una cuenta nueva.
    * Con id_usuario: edita una cuenta existente.
    * El rol determina qué perfil se diligencia:
        ESTUDIANTE -> programa académico + código estudiantil.
        DOCENTE    -> especialidad + si puede evaluar.
        COMITE / ADMINISTRADOR -> sin perfil adicional.
    * La contraseña es opcional al editar: si se deja vacía se conserva.
      En creación es obligatoria.
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

<%-- =========================================================
     2) Modo creación / edición
     ========================================================= --%>
<c:set var="idUsuario" value="${fn:trim(param.id_usuario)}" />
<c:set var="esEdicion" value="${not empty idUsuario}" />

<c:set var="rolActual" value="ESTUDIANTE" />
<c:set var="estadoActual" value="${true}" />
<c:set var="idProgramaActual" value="" />
<c:set var="codigoActual" value="" />
<c:set var="especialidadActual" value="" />
<c:set var="esEvaluadorActual" value="${false}" />

<c:if test="${esEdicion}">
    <c:set var="errorUsuario" value="" />
    <c:catch var="errorUsuario">
        <sql:query var="resUsuario" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT u.id_usuario,
                         u.id_rol,
                         u.documento_identidad,
                         u.nombres,
                         u.apellidos,
                         u.correo_institucional,
                         u.estado_activo,
                         r.nombre AS rol,
                         ep.id_programa,
                         ep.codigo_estudiantil,
                         pa.nivel_formacion,
                         dp.especialidad,
                         dp.es_evaluador
                    FROM USUARIOS u
                         INNER JOIN ROLES r ON r.id_rol = u.id_rol
                         LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
                         LEFT JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                         LEFT JOIN DOCENTES_PERFIL dp ON dp.id_docente = u.id_usuario
                   WHERE u.id_usuario = ?
              ) t
            <sql:param value="${idUsuario}" />
        </sql:query>
    </c:catch>

    <c:choose>
        <c:when test="${not empty errorUsuario}">
            <c:redirect url="admin_usuarios.jsp">
                <c:param name="error" value="No fue posible consultar el usuario solicitado." />
            </c:redirect>
        </c:when>
        <c:when test="${empty resUsuario or resUsuario.rowCount eq 0}">
            <c:redirect url="admin_usuarios.jsp">
                <c:param name="error" value="El usuario solicitado no existe." />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:set var="fila" value="${resUsuario.rows[0]}" />
            <c:set var="rolActual" value="${fila.rol}" />
            <c:set var="estadoActual" value="${fila.estado_activo}" />
            <c:set var="idProgramaActual" value="${fila.id_programa}" />
            <c:set var="codigoActual" value="${fila.codigo_estudiantil}" />
            <c:set var="especialidadActual" value="${fila.especialidad}" />
            <c:set var="esEvaluadorActual" value="${fila.es_evaluador}" />
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =========================================================
     3) Catálogos para los selects
     ========================================================= --%>
<c:set var="errorCatalogos" value="" />
<c:catch var="errorCatalogos">
    <sql:query var="resProgramas" dataSource="${db}">
        SELECT id_programa, nombre_programa, nivel_formacion
          FROM PROGRAMAS_ACADEMICOS
         ORDER BY nivel_formacion, nombre_programa
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="${esEdicion ? 'Editar usuario' : 'Nuevo usuario'} - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi ${esEdicion ? 'bi-pencil-square' : 'bi-person-plus-fill'} text-success me-2"></i>
            <c:out value="${esEdicion ? 'Editar usuario' : 'Nuevo usuario'}" />
        </h1>
        <p class="text-muted small mb-0">
            <c:choose>
                <c:when test="${esEdicion}">
                    Actualice los datos de <strong><c:out value="${fila.nombres}" /> <c:out value="${fila.apellidos}" /></strong>.
                </c:when>
                <c:otherwise>
                    Cree una cuenta y asigne su rol y perfil.
                </c:otherwise>
            </c:choose>
        </p>
    </div>
    <a href="admin_usuarios.jsp" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left me-1"></i>Volver al listado
    </a>
</div>

<c:if test="${not empty param.error}">
    <div class="alert alert-danger d-flex align-items-start" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
        <div><c:out value="${param.error}" /></div>
    </div>
</c:if>

<c:if test="${not empty errorCatalogos}">
    <div class="alert alert-danger" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2"></i>
        No fue posible cargar los programas académicos.
    </div>
</c:if>

<div class="card shadow-sm border-0">
    <div class="card-body">
        <form method="post" action="admin_usuario_procesar.jsp" class="row g-3">

            <input type="hidden" name="accion" value="${esEdicion ? 'actualizar' : 'crear'}" />
            <c:if test="${esEdicion}">
                <input type="hidden" name="id_usuario" value="${idUsuario}" />
            </c:if>

            <div class="col-12">
                <h2 class="h6 text-success border-bottom pb-2 mb-1">
                    <i class="bi bi-person-vcard me-1"></i>Datos de la cuenta
                </h2>
            </div>

            <div class="col-12 col-md-4">
                <label for="documento_identidad" class="form-label">Documento de identidad <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="documento_identidad" name="documento_identidad"
                       maxlength="20" required
                       value="${fn:escapeXml(esEdicion ? fila.documento_identidad : '')}" />
            </div>

            <div class="col-12 col-md-4">
                <label for="nombres" class="form-label">Nombres <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="nombres" name="nombres"
                       maxlength="100" required
                       value="${fn:escapeXml(esEdicion ? fila.nombres : '')}" />
            </div>

            <div class="col-12 col-md-4">
                <label for="apellidos" class="form-label">Apellidos <span class="text-danger">*</span></label>
                <input type="text" class="form-control" id="apellidos" name="apellidos"
                       maxlength="100" required
                       value="${fn:escapeXml(esEdicion ? fila.apellidos : '')}" />
            </div>

            <div class="col-12 col-md-6">
                <label for="correo_institucional" class="form-label">Correo institucional <span class="text-danger">*</span></label>
                <input type="email" class="form-control" id="correo_institucional" name="correo_institucional"
                       maxlength="100" required
                       value="${fn:escapeXml(esEdicion ? fila.correo_institucional : '')}" />
            </div>

            <div class="col-12 col-md-3">
                <label for="rol" class="form-label">Rol <span class="text-danger">*</span></label>
                <select class="form-select" id="rol" name="rol" required>
                    <option value="ESTUDIANTE" ${rolActual eq 'ESTUDIANTE' ? 'selected' : ''}>Estudiante</option>
                    <option value="DOCENTE" ${rolActual eq 'DOCENTE' ? 'selected' : ''}>Docente</option>
                    <option value="COMITE" ${rolActual eq 'COMITE' ? 'selected' : ''}>Comité</option>
                    <option value="ADMINISTRADOR" ${rolActual eq 'ADMINISTRADOR' ? 'selected' : ''}>Administrador</option>
                </select>
            </div>

            <div class="col-12 col-md-3">
                <label for="estado" class="form-label">Estado <span class="text-danger">*</span></label>
                <select class="form-select" id="estado" name="estado" required>
                    <option value="1" ${estadoActual ? 'selected' : ''}>Activo</option>
                    <option value="0" ${estadoActual ? '' : 'selected'}>Inactivo</option>
                </select>
            </div>

            <div class="col-12 col-md-6">
                <label for="contrasena" class="form-label">
                    Contraseña
                    <c:if test="${not esEdicion}"><span class="text-danger">*</span></c:if>
                </label>
                <input type="password" class="form-control" id="contrasena" name="contrasena"
                       maxlength="255" ${esEdicion ? '' : 'required'}
                       autocomplete="new-password"
                       placeholder="${esEdicion ? 'Dejar en blanco para conservar la actual' : 'Clave de acceso'}" />
                <c:if test="${esEdicion}">
                    <div class="form-text">Solo se cambia si escribe una clave nueva.</div>
                </c:if>
            </div>

            <div class="col-12">
                <h2 class="h6 text-success border-bottom pb-2 mb-1 mt-2">
                    <i class="bi bi-mortarboard me-1"></i>Perfil de estudiante
                </h2>
                <p class="text-muted small mb-2">Solo se aplica si el rol seleccionado es ESTUDIANTE.</p>
            </div>

            <div class="col-12" id="camposEstudiante">
                <div class="row g-3">
                    <div class="col-12 col-md-6">
                        <label for="id_programa" class="form-label">Programa académico</label>
                        <select class="form-select" id="id_programa" name="id_programa">
                            <option value="">Seleccione un programa</option>
                            <c:forEach var="prog" items="${resProgramas.rows}">
                                <option value="${prog.id_programa}"
                                        ${prog.id_programa eq idProgramaActual ? 'selected' : ''}>
                                    <c:out value="${prog.nombre_programa}" />
                                    (<c:out value="${prog.nivel_formacion}" />)
                                </option>
                            </c:forEach>
                        </select>
                    </div>
                    <div class="col-12 col-md-6">
                        <label for="codigo_estudiantil" class="form-label">Código estudiantil</label>
                        <input type="text" class="form-control" id="codigo_estudiantil" name="codigo_estudiantil"
                               maxlength="20"
                               value="${fn:escapeXml(codigoActual)}" />
                    </div>
                </div>
            </div>

            <div class="col-12">
                <h2 class="h6 text-success border-bottom pb-2 mb-1 mt-2">
                    <i class="bi bi-person-workspace me-1"></i>Perfil de docente
                </h2>
                <p class="text-muted small mb-2">Solo se aplica si el rol seleccionado es DOCENTE.</p>
            </div>

            <div class="col-12" id="camposDocente">
                <div class="row g-3">
                    <div class="col-12 col-md-8">
                        <label for="especialidad" class="form-label">Especialidad</label>
                        <input type="text" class="form-control" id="especialidad" name="especialidad"
                               maxlength="150"
                               value="${fn:escapeXml(especialidadActual)}" />
                    </div>
                    <div class="col-12 col-md-4">
                        <label for="es_evaluador" class="form-label">¿Puede evaluar?</label>
                        <select class="form-select" id="es_evaluador" name="es_evaluador">
                            <option value="0" ${esEvaluadorActual ? '' : 'selected'}>No</option>
                            <option value="1" ${esEvaluadorActual ? 'selected' : ''}>Sí</option>
                        </select>
                    </div>
                </div>
            </div>

            <div class="col-12 d-flex flex-wrap gap-2 pt-2">
                <button type="submit" class="btn btn-success">
                    <i class="bi bi-save me-1"></i>
                    <c:out value="${esEdicion ? 'Guardar cambios' : 'Crear usuario'}" />
                </button>
                <a href="admin_usuarios.jsp" class="btn btn-outline-secondary">
                    <i class="bi bi-x-circle me-1"></i>Cancelar
                </a>
            </div>

        </form>
    </div>
</div>

<%-- Mostrar/ocultar los perfiles según el rol seleccionado --%>
<script>
    (function () {
        function actualizarPerfiles() {
            var rol = document.getElementById('rol').value;
            var est = document.getElementById('camposEstudiante');
            var doc = document.getElementById('camposDocente');
            if (est) { est.classList.toggle('d-none', rol !== 'ESTUDIANTE'); }
            if (doc) { doc.classList.toggle('d-none', rol !== 'DOCENTE'); }
        }
        document.addEventListener('DOMContentLoaded', function () {
            var rol = document.getElementById('rol');
            if (rol) {
                rol.addEventListener('change', actualizarPerfiles);
                actualizarPerfiles();
            }
        });
    })();
</script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
