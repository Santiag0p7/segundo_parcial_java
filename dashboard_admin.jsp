<%--
    =====================================================================
    dashboard_admin.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Panel exclusivo del rol ADMINISTRADOR.

    Desde aquí el administrador puede:
      * Gestionar usuarios (crear, editar, activar/desactivar y
        restablecer claves).
      * Entrar como estudiante o docente para operar sus vistas con el
        mismo código JSP (suplantación controlada).
      * Usar todos los módulos del comité.
      * Publicar propuestas y consultar el calendario académico.

    El panel NO se muestra mientras el administrador está suplantando a
    otro usuario: en ese momento ${sessionScope.adminOriginal} no está
    vacío y el sistema redirige al panel del usuario suplantado.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso: solo el administrador real
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para acceder al panel de administración." />
    </c:redirect>
</c:if>

<%-- Si está suplantando a otro usuario, primero se restaura su sesión --%>
<c:if test="${not empty sessionScope.adminOriginal}">
    <c:redirect url="admin_volver.jsp" />
</c:if>

<c:if test="${sessionScope.usuario.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="El panel de administración es exclusivo del rol ADMINISTRADOR." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />
<c:set var="pageTitle" value="Panel de administración - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- Estilos del sidebar compartidos con dashboard.jsp --%>
<style>
    .uts-sidebar { top: 1rem; }
    .uts-nav-link {
        display: flex;
        align-items: flex-start;
        gap: .55rem;
        padding: .55rem .75rem;
        border-radius: .5rem;
        border-left: 3px solid transparent;
        color: #212529;
        font-size: .95rem;
        line-height: 1.25;
        transition: background-color .15s ease, color .15s ease, border-color .15s ease;
    }
    .uts-nav-link:hover,
    .uts-nav-link:focus {
        background-color: #e8f3ee;
        color: #198754;
    }
    .uts-nav-link.active {
        background-color: #198754;
        border-left-color: #146c43;
        color: #fff;
        font-weight: 600;
    }
    .uts-nav-link i { font-size: 1rem; margin-top: .1rem; }
    @media (min-width: 768px) { .uts-sidebar { position: sticky; } }
</style>

<div class="row g-4">

    <%-- =========================================================
         2) BARRA LATERAL
         ========================================================= --%>
    <aside class="col-12 col-md-3 col-lg-3 col-xl-2">
        <div class="uts-sidebar card bg-white border-0 shadow-sm">

            <div class="card-body pb-2">
                <div class="d-flex align-items-center gap-2 mb-2">
                    <span class="d-inline-flex align-items-center justify-content-center rounded-circle bg-success bg-opacity-10 text-success"
                          style="width: 40px; height: 40px;">
                        <i class="bi bi-shield-lock-fill fs-5"></i>
                    </span>
                    <div class="small lh-sm">
                        <div class="fw-semibold text-truncate" style="max-width: 130px;">
                            <c:out value="${u.nombres}" />
                        </div>
                        <div class="text-muted text-truncate" style="max-width: 130px;">
                            <c:out value="${u.apellidos}" />
                        </div>
                    </div>
                </div>
                <span class="badge bg-dark w-100">
                    <i class="bi bi-shield-check me-1"></i><c:out value="${u.rol}" />
                </span>
            </div>

            <hr class="my-0" />

            <c:set var="menuRol"
                   value="dashboard_admin.jsp|bi-speedometer2|Panel Admin;admin_usuarios.jsp|bi-people|Usuarios;admin_suplantar.jsp|bi-person-badge|Entrar como;comite_fase1.jsp|bi-cash-coin|Fase 1 y Pagos;comite_asignaciones.jsp|bi-person-check|Asignar Docentes;comite_fases.jsp|bi-diagram-3|Gestión de Fases;comite_solicitudes.jsp|bi-inbox|Solicitudes;programar_sustentacion.jsp|bi-mic|Sustentaciones;comite_informes.jsp|bi-graph-up-arrow|Informes;banco_ideas.jsp|bi-lightbulb|Banco de Propuestas;consultas_transversales.jsp|bi-calendar3|Calendario" />

            <nav class="card-body pt-2" aria-label="Navegación del administrador">
                <ul class="nav flex-column gap-1 mb-0">
                    <c:forEach var="item" items="${fn:split(menuRol, ';')}">
                        <c:set var="campos" value="${fn:split(item, '|')}" />
                        <li class="nav-item">
                            <a class="uts-nav-link ${campos[0] eq 'dashboard_admin.jsp' ? 'active' : ''}"
                               href="${campos[0]}">
                                <i class="bi ${campos[1]}"></i>
                                <span><c:out value="${campos[2]}" /></span>
                            </a>
                        </li>
                    </c:forEach>
                </ul>
            </nav>

        </div>
    </aside>

    <%-- =========================================================
         3) ÁREA PRINCIPAL
         ========================================================= --%>
    <section class="col-12 col-md-9 col-lg-9 col-xl-10">

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

        <div class="card shadow-sm border-0 mb-4">
            <div class="card-body">
                <div class="row align-items-center gy-3">
                    <div class="col-lg-8">
                        <h1 class="h4 mb-1">
                            <i class="bi bi-shield-lock-fill text-success me-2"></i>
                            Panel de administración
                        </h1>
                        <p class="text-muted small mb-0">
                            Bienvenido(a), <c:out value="${u.nombres}" /> <c:out value="${u.apellidos}" />.
                            Desde aquí puede administrar usuarios y operar todos los módulos del sistema.
                        </p>
                    </div>
                    <div class="col-lg-4 text-lg-end">
                        <span class="badge bg-dark fs-6">
                            <i class="bi bi-shield-check me-1"></i><c:out value="${u.rol}" />
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <%-- =====================================================
             3.a) Indicadores generales
             ===================================================== --%>
        <c:set var="errorKpi" value="" />
        <c:catch var="errorKpi">
            <sql:query var="resKpi" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT
                          (SELECT COUNT(*) FROM USUARIOS) AS usuarios,
                          (SELECT COUNT(*) FROM USUARIOS WHERE estado_activo = 1) AS usuariosActivos,
                          (SELECT COUNT(*) FROM USUARIOS u INNER JOIN ROLES r ON r.id_rol = u.id_rol WHERE r.nombre = 'ESTUDIANTE') AS estudiantes,
                          (SELECT COUNT(*) FROM USUARIOS u INNER JOIN ROLES r ON r.id_rol = u.id_rol WHERE r.nombre = 'DOCENTE') AS docentes,
                          (SELECT COUNT(*) FROM PROYECTOS_GRADO) AS proyectos,
                          (SELECT COUNT(*) FROM PROYECTOS_GRADO WHERE estado = 'EN_PROCESO') AS proyectosActivos,
                          (SELECT COUNT(*) FROM PAGOS_PROYECTO WHERE estado_pago = 'PENDIENTE' AND tipo_pago = 'DERECHOS_GRADO') AS pagosPendientes,
                          (SELECT COUNT(*) FROM SOLICITUDES_CAMBIO_DOCENTE WHERE estado = 'PENDIENTE')
                        + (SELECT COUNT(*) FROM SOLICITUDES_PRORROGA WHERE estado = 'PENDIENTE')
                        + (SELECT COUNT(*) FROM SOLICITUDES_EXONERACION_SABER WHERE estado = 'PENDIENTE') AS solicitudesPendientes,
                          (SELECT COUNT(*) FROM ENTREGABLES e
                            WHERE NOT EXISTS (
                                SELECT 1 FROM REVISIONES_ENTREGABLE r
                                 WHERE r.id_entregable = e.id_entregable
                                   AND r.string_revisor = 'COMITE'
                            )) AS entregablesComite,
                          (SELECT COUNT(*) FROM SUSTENTACIONES) AS sustentaciones
                  ) t
            </sql:query>
        </c:catch>

        <c:choose>
            <c:when test="${not empty errorKpi}">
                <div class="alert alert-warning" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i>
                    No fue posible consultar los indicadores.
                </div>
            </c:when>
            <c:when test="${resKpi.rowCount gt 0}">
                <c:set var="k" value="${resKpi.rows[0]}" />
                <div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3 mb-4">

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Usuarios activos</div>
                                        <div class="fs-3 fw-bold text-success"><c:out value="${k.usuariosActivos}" /></div>
                                        <div class="small text-muted">de <c:out value="${k.usuarios}" /> registrados</div>
                                    </div>
                                    <i class="bi bi-people-fill fs-2 text-success opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Estudiantes</div>
                                        <div class="fs-3 fw-bold text-primary"><c:out value="${k.estudiantes}" /></div>
                                        <div class="small text-muted">con perfil académico</div>
                                    </div>
                                    <i class="bi bi-mortarboard-fill fs-2 text-primary opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Docentes</div>
                                        <div class="fs-3 fw-bold text-info"><c:out value="${k.docentes}" /></div>
                                        <div class="small text-muted">directores y evaluadores</div>
                                    </div>
                                    <i class="bi bi-person-workspace fs-2 text-info opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Proyectos activos</div>
                                        <div class="fs-3 fw-bold text-dark"><c:out value="${k.proyectosActivos}" /></div>
                                        <div class="small text-muted">de <c:out value="${k.proyectos}" /> registrados</div>
                                    </div>
                                    <i class="bi bi-kanban-fill fs-2 text-dark opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Pagos pendientes</div>
                                        <div class="fs-3 fw-bold text-warning"><c:out value="${k.pagosPendientes}" /></div>
                                        <div class="small text-muted">Fase 1 por aprobar</div>
                                    </div>
                                    <i class="bi bi-cash-coin fs-2 text-warning opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Solicitudes pendientes</div>
                                        <div class="fs-3 fw-bold text-danger"><c:out value="${k.solicitudesPendientes}" /></div>
                                        <div class="small text-muted">por dictaminar</div>
                                    </div>
                                    <i class="bi bi-inbox-fill fs-2 text-danger opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Entregables por comité</div>
                                        <div class="fs-3 fw-bold text-secondary"><c:out value="${k.entregablesComite}" /></div>
                                        <div class="small text-muted">sin visto bueno final</div>
                                    </div>
                                    <i class="bi bi-clipboard2-check-fill fs-2 text-secondary opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <div class="text-muted small">Sustentaciones</div>
                                        <div class="fs-3 fw-bold text-success"><c:out value="${k.sustentaciones}" /></div>
                                        <div class="small text-muted">programadas</div>
                                    </div>
                                    <i class="bi bi-mic-fill fs-2 text-success opacity-50"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </c:when>
        </c:choose>

        <%-- =====================================================
             3.b) Administración de usuarios y suplantación
             ===================================================== --%>
        <h2 class="h5 mb-3">
            <i class="bi bi-gear-fill text-success me-2"></i>Administración
        </h2>

        <div class="row row-cols-1 row-cols-md-2 g-3 mb-4">
            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6">
                            <i class="bi bi-people-fill fs-4 text-success me-2"></i>Gestión de usuarios
                        </h3>
                        <p class="text-muted small mb-0">
                            Crear usuarios, editar sus datos, cambiar roles, activar o desactivar cuentas y restablecer claves.
                        </p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="admin_usuarios.jsp" class="btn btn-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Administrar usuarios
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6">
                            <i class="bi bi-person-badge-fill fs-4 text-primary me-2"></i>Entrar como estudiante o docente
                        </h3>
                        <p class="text-muted small mb-0">
                            Opere el sistema con la vista del usuario seleccionado y regrese al panel de administración cuando termine.
                        </p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="admin_suplantar.jsp" class="btn btn-primary btn-sm w-100">
                            <i class="bi bi-box-arrow-in-right me-1"></i>Seleccionar usuario
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <%-- =====================================================
             3.c) Módulos del comité
             ===================================================== --%>
        <h2 class="h5 mb-3">
            <i class="bi bi-diagram-3-fill text-success me-2"></i>Módulos del comité
        </h2>

        <div class="row row-cols-1 row-cols-md-2 row-cols-xxl-3 g-3">

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-cash-coin fs-4 text-warning me-2"></i>Fase 1: Pagos e Ideas</h3>
                        <p class="text-muted small mb-0">Aprobar pagos pendientes y avanzar los proyectos a la Fase 2.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="comite_fase1.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-person-check-fill fs-4 text-success me-2"></i>Asignar Docentes</h3>
                        <p class="text-muted small mb-0">Asignar director y evaluador a proyectos en Fase 2.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="comite_asignaciones.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-diagram-3-fill fs-4 text-primary me-2"></i>Gestión de Fases</h3>
                        <p class="text-muted small mb-0">Dar visto bueno o rechazar entregables y avanzar la fase del proyecto.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="comite_fases.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-inbox-fill fs-4 text-warning me-2"></i>Atender Solicitudes</h3>
                        <p class="text-muted small mb-0">Aprobar o rechazar cambio de docente, prórroga y exoneración Saber.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="comite_solicitudes.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-mic-fill fs-4 text-success me-2"></i>Programar Sustentación</h3>
                        <p class="text-muted small mb-0">Programar o reprogramar la sustentación de proyectos en Fase 6.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="programar_sustentacion.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-graph-up-arrow fs-4 text-primary me-2"></i>Informes y Reportes</h3>
                        <p class="text-muted small mb-0">Consultar avance por estudiante y carga de directores y evaluadores.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="comite_informes.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-lightbulb-fill fs-4 text-warning me-2"></i>Banco de Propuestas</h3>
                        <p class="text-muted small mb-0">Consultar el banco y publicar nuevas propuestas de grado.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="banco_ideas.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h3 class="h6"><i class="bi bi-calendar3 fs-4 text-info me-2"></i>Calendario Académico</h3>
                        <p class="text-muted small mb-0">Consultar los hitos institucionales y las fases del ciclo.</p>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="consultas_transversales.jsp" class="btn btn-outline-success btn-sm w-100">
                            <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                        </a>
                    </div>
                </div>
            </div>

        </div>

    </section>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
