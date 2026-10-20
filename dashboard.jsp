<%--
    =====================================================================
    dashboard.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Panel principal con LAYOUT DE DOS COLUMNAS:

      * Barra lateral izquierda (col-12 col-md-3 col-lg-2):
        menú vertical de navegación construido dinámicamente según
        ${sessionScope.usuario.rol}, con los colores institucionales.
      * Área principal (col-12 col-md-9 col-lg-10):
        bienvenida, indicadores (KPIs) y tarjetas de módulos del rol.

    RNF-01 (RBAC): si ${sessionScope.usuario} está vacío se redirige al
    login antes de emitir cualquier salida.

    RF-02: para el rol ESTUDIANTE se detecta el nivel de formación
    (TECNOLOGIA / INGENIERIA) y se adapta el panel.

    DECISIONES DE DISEÑO:
      * El menú se declara como una cadena "href|icono|texto" separada por
        ";" y se recorre con fn:split. Evita duplicar 20 líneas de <ul> por
        cada rol y no usa scriptlets.
      * El enlace activo se marca comparando el href con "dashboard.jsp":
        esta vista es la única que pinta el sidebar, así que el ítem
        "Panel" siempre es el activo. Si el sidebar se extrae a un .jspf
        compartido (ver AGENTS.md), esa comparación debe hacerse contra
        ${pageContext.request.servletPath}.
      * Los KPIs usan subconsultas escalares dentro de una tabla derivada
        para que las claves del row existan (trampa 5). Nunca se comparan
        columnas BOOLEAN con 1/0 en EL (trampa 12).
      * El CSS propio es mínimo y está acotado a .uts-sidebar / .uts-nav-link:
        Bootstrap 5 no trae un componente de barra lateral.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) RNF-01: control de acceso (vista protegida)
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para acceder al panel." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<%-- El administrador tiene su propio panel; si está suplantando a otro
     usuario, u.rol ya es el rol del suplantado y no se redirige. --%>
<c:if test="${u.rol eq 'ADMINISTRADOR' and empty sessionScope.adminOriginal}">
    <c:redirect url="dashboard_admin.jsp" />
</c:if>

<c:set var="pageTitle" value="Panel de trabajo - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- Estilos puntuales del sidebar (no hay componente nativo en Bootstrap 5) --%>
<style>
    .uts-sidebar {
        top: 1rem;
    }
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
    .uts-nav-link i {
        font-size: 1rem;
        margin-top: .1rem;
    }
    @media (min-width: 768px) {
        .uts-sidebar {
            position: sticky;
        }
    }
</style>

<div class="row g-4">

    <%-- =========================================================
         2) BARRA LATERAL IZQUIERDA
         ========================================================= --%>
    <aside class="col-12 col-md-3 col-lg-3 col-xl-2">

        <div class="uts-sidebar card bg-white border-0 shadow-sm">

            <%-- -------- Identidad del usuario -------- --%>
            <div class="card-body pb-2">
                <div class="d-flex align-items-center gap-2 mb-2">
                    <span class="d-inline-flex align-items-center justify-content-center rounded-circle bg-success bg-opacity-10 text-success"
                          style="width: 40px; height: 40px;">
                        <i class="bi bi-person-fill fs-5"></i>
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

                <span class="badge bg-success w-100">
                    <i class="bi bi-shield-check me-1"></i><c:out value="${u.rol}" />
                </span>

                <c:choose>
                    <c:when test="${u.nivelFormacion eq 'INGENIERIA'}">
                        <span class="badge bg-primary w-100 mt-1">
                            <i class="bi bi-gear-wide-connected me-1"></i>INGENIERÍA
                        </span>
                    </c:when>
                    <c:when test="${u.nivelFormacion eq 'TECNOLOGIA'}">
                        <span class="badge bg-info text-dark w-100 mt-1">
                            <i class="bi bi-tools me-1"></i>TECNOLOGÍA
                        </span>
                    </c:when>
                </c:choose>
            </div>

            <hr class="my-0" />

            <%-- -------- Menú vertical según el rol --------
                 Formato de cada ítem:  href|icono|texto           --%>
            <c:choose>
                <c:when test="${u.rol eq 'ESTUDIANTE'}">
                    <c:set var="menuRol"
                           value="dashboard.jsp|bi-speedometer2|Panel Principal;banco_ideas.jsp|bi-lightbulb|Banco de Ideas;mi_proyecto.jsp|bi-kanban|Mi Proyecto;entregables_estudiante.jsp|bi-file-earmark-arrow-up|Entregables;solicitudes_estudiante.jsp|bi-file-earmark-medical|Solicitudes Extraordinarias" />
                </c:when>
                <c:when test="${u.rol eq 'DOCENTE'}">
                    <c:set var="menuRol"
                           value="dashboard.jsp|bi-speedometer2|Panel Docente;evaluacion_docente.jsp|bi-clipboard2-check|Evaluar Entregables;banco_ideas.jsp|bi-lightbulb|Mis Propuestas" />
                </c:when>
                <c:when test="${u.rol eq 'COMITE' or u.rol eq 'ADMINISTRADOR'}">
                    <c:set var="menuRol"
                           value="dashboard.jsp|bi-speedometer2|Panel Comité;comite_fase1.jsp|bi-cash-coin|Fase 1 y Pagos;comite_asignaciones.jsp|bi-person-check|Asignar Docentes;comite_fases.jsp|bi-diagram-3|Gestión de Fases;comite_solicitudes.jsp|bi-inbox|Atención de Solicitudes;programar_sustentacion.jsp|bi-mic|Programar Sustentación;comite_informes.jsp|bi-graph-up-arrow|Informes y Reportes" />
                </c:when>
                <c:otherwise>
                    <c:set var="menuRol" value="dashboard.jsp|bi-speedometer2|Panel Principal" />
                </c:otherwise>
            </c:choose>

            <nav class="card-body pt-2" aria-label="Navegación principal">
                <ul class="nav flex-column gap-1 mb-0">
                    <c:forEach var="item" items="${fn:split(menuRol, ';')}">
                        <c:set var="campos" value="${fn:split(item, '|')}" />
                        <li class="nav-item">
                            <a class="uts-nav-link ${campos[0] eq 'dashboard.jsp' ? 'active' : ''}"
                               href="${campos[0]}">
                                <i class="bi ${campos[1]}"></i>
                                <span><c:out value="${campos[2]}" /></span>
                            </a>
                        </li>
                    </c:forEach>
                </ul>

                <hr class="my-3" />

                <%-- -------- Enlace global (todos los roles) -------- --%>
                <ul class="nav flex-column mb-0">
                    <li class="nav-item">
                        <a class="uts-nav-link" href="consultas_transversales.jsp">
                            <i class="bi bi-calendar3"></i>
                            <span>Calendario Académico</span>
                        </a>
                    </li>
                </ul>
            </nav>

        </div>
    </aside>

    <%-- =========================================================
         3) ÁREA PRINCIPAL
         ========================================================= --%>
    <section class="col-12 col-md-9 col-lg-9 col-xl-10">

        <%-- -------- Mensajes de las páginas de proceso -------- --%>
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

        <%-- -------- Bienvenida -------- --%>
        <div class="card shadow-sm border-0 mb-4">
            <div class="card-body">
                <div class="row align-items-center gy-3">
                    <div class="col-lg-8">
                        <h1 class="h4 mb-1">
                            <i class="bi bi-person-workspace text-success me-2"></i>
                            Bienvenido(a), <c:out value="${u.nombres}" /> <c:out value="${u.apellidos}" />
                        </h1>
                        <p class="text-muted small mb-0">
                            <i class="bi bi-envelope me-1"></i><c:out value="${u.correo_institucional}" />
                            &nbsp;·&nbsp;
                            <i class="bi bi-person-vcard me-1"></i>Documento <c:out value="${u.documento_identidad}" />
                        </p>
                    </div>
                    <div class="col-lg-4 text-lg-end">
                        <span class="badge bg-success fs-6 me-1">
                            <i class="bi bi-shield-check me-1"></i><c:out value="${u.rol}" />
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <%-- =====================================================
             3.a) ESTUDIANTE
             ===================================================== --%>
        <c:if test="${u.rol eq 'ESTUDIANTE'}">

            <%-- RF-02: detección automática del nivel de formación --%>
            <c:choose>
                <c:when test="${u.nivelFormacion eq 'INGENIERIA'}">
                    <div class="alert alert-primary d-flex align-items-center" role="alert">
                        <i class="bi bi-gear-wide-connected fs-3 me-3"></i>
                        <div>
                            <strong>Nivel de formación detectado: INGENIERÍA</strong><br />
                            <span class="small">
                                Código estudiantil
                                <c:out value="${empty u.codigoEstudiantil ? 'no registrado' : u.codigoEstudiantil}" />.

                            </span>
                        </div>
                    </div>
                </c:when>
                <c:when test="${u.nivelFormacion eq 'TECNOLOGIA'}">
                    <div class="alert alert-info d-flex align-items-center" role="alert">
                        <i class="bi bi-tools fs-3 me-3"></i>
                        <div>
                            <strong>Nivel de formación detectado: TECNOLOGÍA</strong><br />
                            <span class="small">
                                Código estudiantil
                                <c:out value="${empty u.codigoEstudiantil ? 'no registrado' : u.codigoEstudiantil}" />.

                            </span>
                        </div>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="alert alert-secondary d-flex align-items-center" role="alert">
                        <i class="bi bi-exclamation-circle fs-3 me-3"></i>
                        <div>
                            <strong>Nivel de formación no definido</strong><br />
                            <span class="small">
                                Su perfil no tiene programa académico asociado. Contacte a la coordinación.
                            </span>
                        </div>
                    </div>
                </c:otherwise>
            </c:choose>

            <%-- -------- KPIs del estudiante -------- --%>
            <c:catch var="errorKpi">
                <sql:query var="resKpi" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT g.id_proyecto,
                                 g.fase_actual,
                                 g.estado,
                                 (SELECT COUNT(*)
                                    FROM ENTREGABLES e
                                   WHERE e.id_proyecto = g.id_proyecto) AS entregables,
                                 (SELECT COUNT(*) FROM SOLICITUDES_CAMBIO_DOCENTE c
                                   WHERE c.id_proyecto = g.id_proyecto AND c.estado = 'PENDIENTE')
                               + (SELECT COUNT(*) FROM SOLICITUDES_PRORROGA p
                                   WHERE p.id_proyecto = g.id_proyecto AND p.estado = 'PENDIENTE')
                               + (SELECT COUNT(*) FROM SOLICITUDES_EXONERACION_SABER x
                                   WHERE x.id_proyecto = g.id_proyecto AND x.estado = 'PENDIENTE') AS solicitudes
                            FROM INTEGRANTES_PROYECTO i
                                 INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
                           WHERE i.id_estudiante = ?
                           LIMIT 1
                      ) t
                    <sql:param value="${u.id_usuario}" />
                </sql:query>
            </c:catch>

            <c:choose>
                <%-- Sin proyecto: llamada a la acción --%>
                <c:when test="${empty errorKpi and (empty resKpi or resKpi.rowCount == 0)}">
                    <div class="card shadow-sm border-0 mb-4">
                        <div class="card-body">
                            <h2 class="h6 mb-1">
                                <i class="bi bi-rocket-takeoff text-success me-2"></i>
                                Aún no tienes proyecto de grado
                            </h2>
                            <p class="text-muted small">
                                Elija una propuesta del banco o registre su propia idea.
                            </p>
                            <div class="d-flex flex-wrap gap-2">
                                <a href="banco_ideas.jsp" class="btn btn-success btn-sm">
                                    <i class="bi bi-lightbulb me-1"></i>Ir al Banco de Ideas
                                </a>
                                <a href="fase1_registro.jsp" class="btn btn-outline-success btn-sm">
                                    <i class="bi bi-pencil-square me-1"></i>Registrar Idea Propia
                                </a>
                            </div>
                        </div>
                    </div>
                </c:when>

                <c:when test="${empty errorKpi and not empty resKpi and resKpi.rowCount gt 0}">
                    <c:set var="kpi" value="${resKpi.rows[0]}" />
                    <div class="row row-cols-2 row-cols-xl-4 g-3 mb-4">

                        <div class="col">
                            <div class="card h-100 border-0 shadow-sm">
                                <div class="card-body">
                                    <div class="text-muted small">Fase actual</div>
                                    <div class="d-flex align-items-center gap-2 mt-1">
                                        <i class="bi bi-diagram-3-fill text-success fs-4"></i>
                                        <span class="display-6 lh-1">
                                            <c:out value="${kpi.fase_actual}" />
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="col">
                            <div class="card h-100 border-0 shadow-sm">
                                <div class="card-body">
                                    <div class="text-muted small">Estado del proyecto</div>
                                    <div class="mt-2">
                                        <c:choose>
                                            <c:when test="${kpi.estado eq 'EN_PROCESO'}">
                                                <span class="badge bg-primary">EN PROCESO</span>
                                            </c:when>
                                            <c:when test="${kpi.estado eq 'APROBADO'}">
                                                <span class="badge bg-success">APROBADO</span>
                                            </c:when>
                                            <c:when test="${kpi.estado eq 'EXONERADO'}">
                                                <span class="badge bg-info text-dark">EXONERADO</span>
                                            </c:when>
                                            <c:when test="${kpi.estado eq 'CANCELADO'}">
                                                <span class="badge bg-danger">CANCELADO</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">
                                                    <c:out value="${kpi.estado}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="col">
                            <div class="card h-100 border-0 shadow-sm">
                                <div class="card-body">
                                    <div class="text-muted small">Entregables subidos</div>
                                    <div class="d-flex align-items-center gap-2 mt-1">
                                        <i class="bi bi-file-earmark-arrow-up text-success fs-4"></i>
                                        <span class="display-6 lh-1"><c:out value="${kpi.entregables}" /></span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="col">
                            <div class="card h-100 border-0 shadow-sm">
                                <div class="card-body">
                                    <div class="text-muted small">Solicitudes pendientes</div>
                                    <div class="d-flex align-items-center gap-2 mt-1">
                                        <i class="bi bi-inbox text-success fs-4"></i>
                                        <span class="display-6 lh-1"><c:out value="${kpi.solicitudes}" /></span>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                </c:when>
            </c:choose>
        </c:if>

        <%-- =====================================================
             3.b) DOCENTE
             ===================================================== --%>
        <c:if test="${u.rol eq 'DOCENTE'}">

            <div class="alert alert-success d-flex align-items-center" role="alert">
                <i class="bi bi-person-badge-fill fs-3 me-3"></i>
                <div>
                    <strong>Perfil docente</strong><br />
                    <span class="small">
                        Especialidad:
                        <c:out value="${empty u.especialidad ? 'no registrada' : u.especialidad}" />
                    </span>
                </div>
            </div>

            <c:catch var="errorKpi">
                <sql:query var="resKpi" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT
                            (SELECT COUNT(*)
                               FROM ASIGNACIONES_DOCENTES a
                                    INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = a.id_proyecto
                              WHERE a.id_docente = ?
                                AND a.subrol = 'DIRECTOR'
                                AND g.estado = 'EN_PROCESO') AS como_director,
                            (SELECT COUNT(*)
                               FROM ASIGNACIONES_DOCENTES a
                                    INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = a.id_proyecto
                              WHERE a.id_docente = ?
                                AND a.subrol = 'EVALUADOR'
                                AND g.estado = 'EN_PROCESO') AS como_evaluador,
                            (SELECT COUNT(*)
                               FROM REVISIONES_ENTREGABLE r
                              WHERE r.id_revisor = ?
                                AND r.string_revisor IN ('DIRECTOR', 'EVALUADOR')) AS revisiones,
                            (SELECT COUNT(*)
                               FROM PROPUESTAS_PROYECTO p
                              WHERE p.id_creador = ?) AS propuestas
                      ) t
                    <sql:param value="${u.id_usuario}" />
                    <sql:param value="${u.id_usuario}" />
                    <sql:param value="${u.id_usuario}" />
                    <sql:param value="${u.id_usuario}" />
                </sql:query>
            </c:catch>

            <c:if test="${empty errorKpi and not empty resKpi and resKpi.rowCount gt 0}">
                <c:set var="kpi" value="${resKpi.rows[0]}" />
                <div class="row row-cols-2 row-cols-xl-4 g-3 mb-4">

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Como director</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-person-badge text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.como_director}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Como evaluador</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-person-check text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.como_evaluador}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Revisiones realizadas</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-clipboard2-check text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.revisiones}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Propuestas publicadas</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-lightbulb text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.propuestas}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </c:if>
        </c:if>

        <%-- =====================================================
             3.c) COMITE / ADMINISTRADOR
             ===================================================== --%>
        <c:if test="${u.rol eq 'COMITE' or u.rol eq 'ADMINISTRADOR'}">

            <div class="alert alert-success d-flex align-items-center" role="alert">
                <i class="bi bi-people-fill fs-3 me-3"></i>
                <div>
                    <strong>Comité de trabajos de grado</strong><br />
                    <span class="small">
                        <c:catch var="errorFases">
                            <sql:query var="resFases" dataSource="${db}">
                                SELECT numero_fase, nombre_fase FROM FASES_CICLO ORDER BY numero_fase
                            </sql:query>
                        </c:catch>
                        <c:choose>
                            <c:when test="${empty errorFases}">
                                Fases del ciclo configuradas: <c:out value="${resFases.rowCount}" />.
                            </c:when>
                            <c:otherwise>
                                No fue posible consultar las fases del ciclo.
                            </c:otherwise>
                        </c:choose>
                    </span>
                </div>
            </div>

            <c:catch var="errorKpi">
                <sql:query var="resKpi" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT
                            (SELECT COUNT(*) FROM PROYECTOS_GRADO
                              WHERE estado = 'EN_PROCESO') AS en_proceso,
                            (SELECT COUNT(*) FROM PROYECTOS_GRADO
                              WHERE fase_actual = 1 AND estado = 'EN_PROCESO') AS en_fase1,
                            (SELECT COUNT(*) FROM SOLICITUDES_CAMBIO_DOCENTE WHERE estado = 'PENDIENTE')
                          + (SELECT COUNT(*) FROM SOLICITUDES_PRORROGA WHERE estado = 'PENDIENTE')
                          + (SELECT COUNT(*) FROM SOLICITUDES_EXONERACION_SABER WHERE estado = 'PENDIENTE') AS solicitudes,
                            (SELECT COUNT(*) FROM PROYECTOS_GRADO
                              WHERE fase_actual = 6 AND estado = 'EN_PROCESO') AS en_fase6
                      ) t
                </sql:query>
            </c:catch>

            <c:if test="${empty errorKpi and not empty resKpi and resKpi.rowCount gt 0}">
                <c:set var="kpi" value="${resKpi.rows[0]}" />
                <div class="row row-cols-2 row-cols-xl-4 g-3 mb-4">

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Proyectos en proceso</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-kanban text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.en_proceso}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Pendientes de pago (Fase 1)</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-cash-coin text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.en_fase1}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">Solicitudes pendientes</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-inbox text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.solicitudes}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-body">
                                <div class="text-muted small">En Fase 6 (sustentación)</div>
                                <div class="d-flex align-items-center gap-2 mt-1">
                                    <i class="bi bi-mic text-success fs-4"></i>
                                    <span class="display-6 lh-1"><c:out value="${kpi.en_fase6}" /></span>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </c:if>
        </c:if>

        <%-- =====================================================
             4) TARJETAS DE MÓDULOS DEL ROL
             ===================================================== --%>
        <h2 class="h5 mb-3">
            <i class="bi bi-boxes me-2 text-success"></i>Mis módulos
        </h2>

        <c:choose>

            <%-- -------- ESTUDIANTE -------- --%>
            <c:when test="${u.rol eq 'ESTUDIANTE'}">
                <div class="row row-cols-1 row-cols-md-2 row-cols-xxl-3 g-3">

                    <div class="col">
                        <div class="card h-100 shadow-sm border-0">
                            <div class="card-body">
                                <h3 class="h6">
                                    <i class="bi bi-kanban-fill fs-4 text-success me-2"></i>Mi Proyecto de Grado
                                </h3>
                            </div>
                            <div class="card-footer bg-transparent border-0 pt-0">
                                <a href="mi_proyecto.jsp" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 shadow-sm border-0">
                            <div class="card-body">
                                <h3 class="h6">
                                    <i class="bi bi-lightbulb-fill fs-4 text-warning me-2"></i>Banco de Ideas
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-file-earmark-medical fs-4 text-danger me-2"></i>Solicitudes Especiales
                                </h3>
                            </div>
                            <div class="card-footer bg-transparent border-0 pt-0">
                                <a href="solicitudes_estudiante.jsp" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                                </a>
                            </div>
                        </div>
                    </div>

                </div>
            </c:when>

            <%-- -------- DOCENTE -------- --%>
            <c:when test="${u.rol eq 'DOCENTE'}">
                <div class="row row-cols-1 row-cols-md-2 g-3">

                    <div class="col">
                        <div class="card h-100 shadow-sm border-0">
                            <div class="card-body">
                                <h3 class="h6">
                                    <i class="bi bi-clipboard2-check-fill fs-4 text-success me-2"></i>Evaluar Entregables
                                </h3>
                            </div>
                            <div class="card-footer bg-transparent border-0 pt-0">
                                <a href="evaluacion_docente.jsp" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card h-100 shadow-sm border-0">
                            <div class="card-body">
                                <h3 class="h6">
                                    <i class="bi bi-plus-square-fill fs-4 text-primary me-2"></i>Registrar Propuesta
                                </h3>
                            </div>
                            <div class="card-footer bg-transparent border-0 pt-0">
                                <a href="crear_propuesta.jsp" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                                </a>
                            </div>
                        </div>
                    </div>

                </div>
            </c:when>

            <%-- -------- COMITE / ADMINISTRADOR -------- --%>
            <c:when test="${u.rol eq 'COMITE' or u.rol eq 'ADMINISTRADOR'}">
                <div class="row row-cols-1 row-cols-md-2 row-cols-xxl-3 g-3">

                    <div class="col">
                        <div class="card h-100 shadow-sm border-0">
                            <div class="card-body">
                                <h3 class="h6">
                                    <i class="bi bi-cash-coin fs-4 text-warning me-2"></i>Fase 1: Pagos e Ideas
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-person-check-fill fs-4 text-success me-2"></i>Asignar Docentes
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-diagram-3-fill fs-4 text-primary me-2"></i>Gestión de Fases
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-inbox-fill fs-4 text-warning me-2"></i>Atender Solicitudes
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-mic-fill fs-4 text-success me-2"></i>Programar Sustentación
                                </h3>
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
                                <h3 class="h6">
                                    <i class="bi bi-graph-up-arrow fs-4 text-primary me-2"></i>Informes y Reportes
                                </h3>
                            </div>
                            <div class="card-footer bg-transparent border-0 pt-0">
                                <a href="comite_informes.jsp" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-arrow-right-circle me-1"></i>Ingresar
                                </a>
                            </div>
                        </div>
                    </div>

                </div>
            </c:when>

            <%-- -------- Otros roles -------- --%>
            <c:otherwise>
                <div class="alert alert-warning d-flex align-items-center" role="alert">
                    <i class="bi bi-cone-striped fs-3 me-3"></i>
                    <div>
                        <strong>Rol sin panel configurado</strong><br />
                        <span class="small">
                            Su rol es <c:out value="${u.rol}" />. Comuníquese con el comité de trabajos
                            de grado para habilitar sus módulos.
                        </span>
                    </div>
                </div>
            </c:otherwise>

        </c:choose>

    </section>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
