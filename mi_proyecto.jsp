<%--
    =====================================================================
    mi_proyecto.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 5 (Módulo 3, Fase 1)
    ---------------------------------------------------------------------
    Vista principal del ESTUDIANTE: seguimiento de su trabajo de grado.

      * Si NO tiene proyecto: ofrece las dos formas de iniciar la Fase 1
        (RF-09 / Opción A: banco de ideas, Opción B: idea propia).
      * Si YA tiene proyecto: muestra título, fase actual, estado,
        integrantes (dupla o individual) y el soporte de pago (RF-08).

    NOTA SOBRE EL PAGO: PAGOS_PROYECTO no tiene id_proyecto; se relaciona
    con el proyecto por id_estudiante. Como INTEGRANTES_PROYECTO tiene
    UNIQUE(id_estudiante), el pago del líder identifica al proyecto sin
    ambigüedad.

    NOTA SOBRE LAS CLAVES: las consultas van envueltas en tablas derivadas
    para que los alias (nombre_fase, nombres_lider, ...) existan como claves
    del row (trampa 5).
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) RNF-01: control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para consultar su proyecto de grado." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<%-- Esta vista es del estudiante; los demás roles tienen su propio panel --%>
<c:if test="${u.rol ne 'ESTUDIANTE'}">
    <c:redirect url="banco_ideas.jsp">
        <c:param name="error" value="La vista «Mi Proyecto» es exclusiva del rol ESTUDIANTE." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Proyecto del estudiante (si existe)
     ========================================================= --%>
<c:catch var="errorProyecto">
    <sql:query var="resMiProyecto" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT g.id_proyecto,
                     g.id_propuesta,
                     g.fase_actual,
                     g.titulo,
                     g.estado,
                     g.fecha_registro,
                     f.nombre_fase       AS nombre_fase,
                     p.descripcion       AS descripcion_idea,
                     p.nivel_destinatario AS nivel_idea,
                     i.es_lider          AS soy_lider
                FROM INTEGRANTES_PROYECTO i
                     INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
                     LEFT  JOIN FASES_CICLO f     ON f.numero_fase = g.fase_actual
                     LEFT  JOIN PROPUESTAS_PROYECTO p ON p.id_propuesta = g.id_propuesta
               WHERE i.id_estudiante = ?
               LIMIT 1
          ) t
        <sql:param value="${u.id_usuario}" />
    </sql:query>
</c:catch>

<c:set var="tieneProyecto" value="${not empty resMiProyecto and resMiProyecto.rowCount gt 0}" />
<c:if test="${tieneProyecto}">
    <c:set var="proy" value="${resMiProyecto.rows[0]}" />
</c:if>

<c:set var="pageTitle" value="Mi proyecto de grado - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- =========================================================
     3) Mensajes de las páginas de proceso
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

<h1 class="h4 mb-3">
    <i class="bi bi-kanban-fill text-success me-2"></i>Mi proyecto de grado
</h1>

<c:choose>

    <%-- =====================================================
         4.a) TODAVÍA NO TIENE PROYECTO: iniciar la Fase 1
         ===================================================== --%>
    <c:when test="${not tieneProyecto}">

        <div class="alert alert-info d-flex align-items-start" role="alert">
            <i class="bi bi-info-circle-fill me-2 mt-1"></i>
            <div>
                <strong>Todavía no tiene un proyecto de grado registrado.</strong><br />
            </div>
        </div>

        <div class="row row-cols-1 row-cols-md-2 g-4">

            <%-- Opción A: propuesta del banco de ideas --%>
            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h2 class="h6">
                            <i class="bi bi-lightbulb-fill fs-4 text-warning me-2"></i>
                            Opción A: elegir una propuesta del banco
                        </h2>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="banco_ideas.jsp" class="btn btn-success w-100">
                            <i class="bi bi-lightbulb me-2"></i>Ir al Banco de Ideas
                        </a>
                    </div>
                </div>
            </div>

            <%-- Opción B: idea propia (RF-09) --%>
            <div class="col">
                <div class="card h-100 shadow-sm border-0">
                    <div class="card-body">
                        <h2 class="h6">
                            <i class="bi bi-pencil-square fs-4 text-primary me-2"></i>
                            Opción B: registrar una idea propia
                        </h2>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <a href="fase1_registro.jsp" class="btn btn-outline-success w-100">
                            <i class="bi bi-pencil-square me-2"></i>Registrar Idea Propia
                        </a>
                    </div>
                </div>
            </div>

        </div>

    </c:when>

    <%-- =====================================================
         4.b) YA TIENE PROYECTO: seguimiento
         ===================================================== --%>
    <c:otherwise>

        <%-- -------- Resumen del proyecto -------- --%>
        <div class="card shadow-sm border-0 mb-4">
            <div class="card-header bg-white d-flex justify-content-between align-items-start gap-2">
                <h2 class="h6 mb-0">
                    <i class="bi bi-journal-check text-success me-2"></i>
                    <c:out value="${proy.titulo}" />
                </h2>
                <c:choose>
                    <c:when test="${proy.estado eq 'EN_PROCESO'}">
                        <span class="badge bg-primary flex-shrink-0">EN PROCESO</span>
                    </c:when>
                    <c:when test="${proy.estado eq 'APROBADO'}">
                        <span class="badge bg-success flex-shrink-0">APROBADO</span>
                    </c:when>
                    <c:when test="${proy.estado eq 'EXONERADO'}">
                        <span class="badge bg-info text-dark flex-shrink-0">EXONERADO</span>
                    </c:when>
                    <c:otherwise>
                        <span class="badge bg-secondary flex-shrink-0">
                            <c:out value="${proy.estado}" />
                        </span>
                    </c:otherwise>
                </c:choose>
            </div>

            <div class="card-body">
                <div class="row g-3 small">

                    <div class="col-12 col-md-6">
                        <span class="text-muted d-block">Fase actual del ciclo</span>
                        <strong>
                            Fase <c:out value="${proy.fase_actual}" />
                            <c:if test="${not empty proy.nombre_fase}">
                                — <c:out value="${proy.nombre_fase}" />
                            </c:if>
                        </strong>
                    </div>

                    <div class="col-12 col-md-6">
                        <span class="text-muted d-block">Fecha de registro</span>
                        <strong>
                            <fmt:formatDate value="${proy.fecha_registro}" pattern="dd/MM/yyyy" />
                        </strong>
                    </div>

                    <div class="col-12">
                        <span class="text-muted d-block">Idea / descripción del proyecto</span>
                        <span class="d-block" style="white-space: pre-wrap;"><c:out value="${proy.descripcion_idea}" /></span>
                    </div>

                </div>

                <c:if test="${proy.fase_actual eq 1}">
                    <div class="alert alert-warning d-flex align-items-start mt-3 mb-0" role="alert">
                        <i class="bi bi-hourglass-split me-2 mt-1"></i>
                        <div class="small">
                            Su proyecto está en la <strong>Fase 1</strong> a la espera de que el
                            comité verifique el soporte de pago. Cuando se apruebe, el proyecto
                            avanzará automáticamente a la Fase 2.
                        </div>
                    </div>
                </c:if>
            </div>
        </div>

        <%-- -------- Integrantes (dupla o individual) -------- --%>
        <h2 class="h5 mb-2">
            <i class="bi bi-people-fill text-success me-2"></i>Integrantes del proyecto
        </h2>

        <c:catch var="errorIntegrantes">
            <sql:query var="resIntegrantes" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT u.id_usuario,
                             u.nombres,
                             u.apellidos,
                             u.correo_institucional,
                             ep.codigo_estudiantil AS codigo_estudiantil,
                             i.es_lider            AS es_lider,
                             i.fecha_vinculacion   AS fecha_vinculacion
                        FROM INTEGRANTES_PROYECTO i
                             INNER JOIN USUARIOS u ON u.id_usuario = i.id_estudiante
                             LEFT  JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = u.id_usuario
                       WHERE i.id_proyecto = ?
                       ORDER BY i.es_lider DESC, u.nombres
                  ) t
                <sql:param value="${proy.id_proyecto}" />
            </sql:query>
        </c:catch>

        <c:choose>
            <c:when test="${not empty errorIntegrantes or empty resIntegrantes or resIntegrantes.rowCount == 0}">
                <div class="alert alert-warning small" role="alert">
                    No fue posible consultar los integrantes del proyecto.
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-responsive mb-4">
                    <table class="table table-sm align-middle bg-white shadow-sm">
                        <thead class="table-success">
                            <tr>
                                <th scope="col">Rol en el proyecto</th>
                                <th scope="col">Estudiante</th>
                                <th scope="col">Código</th>
                                <th scope="col">Correo</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="m" items="${resIntegrantes.rows}">
                                <tr>
                                    <td>
                                        <c:choose>
                                            <%-- es_lider es BOOLEAN: se evalúa como valor
                                                 lógico, nunca con eq 1 (ELException). --%>
                                            <c:when test="${m.es_lider}">
                                                <span class="badge bg-success">
                                                    <i class="bi bi-star-fill me-1"></i>Líder
                                                </span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">Compañero(a)</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:out value="${m.nombres}" /> <c:out value="${m.apellidos}" />
                                    </td>
                                    <td>
                                        <c:out value="${empty m.codigo_estudiantil ? '—' : m.codigo_estudiantil}" />
                                    </td>
                                    <td class="small text-muted">
                                        <c:out value="${m.correo_institucional}" />
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>

        <%-- -------- Docentes asignados (RF-11 / RNF-02) -------- --%>
        <h2 class="h5 mb-2">
            <i class="bi bi-person-badge text-success me-2"></i>Docentes asignados
        </h2>

        <c:catch var="errorDocentes">
            <sql:query var="resDocentesProy" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT a.subrol,
                             ud.nombres     AS nombres,
                             ud.apellidos   AS apellidos,
                             d.especialidad AS especialidad
                        FROM ASIGNACIONES_DOCENTES a
                             INNER JOIN USUARIOS ud ON ud.id_usuario = a.id_docente
                             LEFT  JOIN DOCENTES_PERFIL d ON d.id_docente = a.id_docente
                       WHERE a.id_proyecto = ?
                       ORDER BY a.subrol
                  ) t
                <sql:param value="${proy.id_proyecto}" />
            </sql:query>
        </c:catch>

        <div class="row row-cols-1 row-cols-md-2 g-3 mb-4">
            <c:choose>
                <c:when test="${not empty errorDocentes or empty resDocentesProy or resDocentesProy.rowCount == 0}">
                    <div class="col">
                        <div class="alert alert-light border small mb-0" role="alert">
                            <i class="bi bi-info-circle me-1"></i>
                            Su proyecto todavía no tiene docentes asignados.
                        </div>
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="d" items="${resDocentesProy.rows}">
                        <div class="col">
                            <div class="card h-100 shadow-sm border-0">
                                <div class="card-body small">
                                    <c:choose>
                                        <%-- El director siempre es visible --%>
                                        <c:when test="${d.subrol eq 'DIRECTOR'}">
                                            <span class="badge bg-success mb-1">Director</span>
                                            <div class="fw-semibold">
                                                <c:out value="${d.nombres}" /> <c:out value="${d.apellidos}" />
                                            </div>
                                            <c:if test="${not empty d.especialidad}">
                                                <span class="text-muted d-block"><c:out value="${d.especialidad}" /></span>
                                            </c:if>
                                        </c:when>

                                        <%-- RF-11 / RNF-02: el evaluador se revela en Fase 6 --%>
                                        <c:otherwise>
                                            <span class="badge bg-info text-dark mb-1">Evaluador</span>
                                            <c:choose>
                                                <c:when test="${proy.fase_actual ge 6}">
                                                    <div class="fw-semibold">
                                                        <c:out value="${d.nombres}" /> <c:out value="${d.apellidos}" />
                                                    </div>
                                                    <c:if test="${not empty d.especialidad}">
                                                        <span class="text-muted d-block"><c:out value="${d.especialidad}" /></span>
                                                    </c:if>
                                                </c:when>
                                                <c:otherwise>
                                                    <div class="text-muted">
                                                        <i class="bi bi-eye-slash me-1"></i>
                                                        Identidad reservada hasta la Fase 6 (RF-11 / RNF-02).
                                                    </div>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>

        <%-- -------- Sustentación programada (RF-16) -------- --%>
        <c:if test="${proy.fase_actual ge 6}">
            <c:catch var="errorSustentacion">
                <sql:query var="resSustentacion" dataSource="${db}">
                    SELECT t.*
                      FROM (
                          SELECT s.lugar_salon           AS lugar_salon,
                                 DATE_FORMAT(s.fecha_hora_programada, '%d/%m/%Y %H:%i') AS fecha_texto
                            FROM SUSTENTACIONES s
                           WHERE s.id_proyecto = ?
                           ORDER BY s.id_sustentacion DESC
                           LIMIT 1
                      ) t
                    <sql:param value="${proy.id_proyecto}" />
                </sql:query>
            </c:catch>

            <c:if test="${empty errorSustentacion and not empty resSustentacion and resSustentacion.rowCount gt 0}">
                <div class="alert alert-success d-flex flex-wrap align-items-center gap-3 small" role="alert">
                    <span><i class="bi bi-mic-fill me-1"></i><strong>Sustentación programada</strong></span>
                    <span>
                        <i class="bi bi-geo-alt-fill me-1"></i>
                        <c:out value="${resSustentacion.rows[0].lugar_salon}" />
                    </span>
                    <span>
                        <i class="bi bi-calendar-event me-1"></i>
                        <c:out value="${resSustentacion.rows[0].fecha_texto}" />
                    </span>
                </div>
            </c:if>
        </c:if>

        <%-- -------- RF-08: soporte de pago -------- --%>
        <h2 class="h5 mb-2">
            <i class="bi bi-receipt text-success me-2"></i>Soporte de pago
        </h2>

        <c:catch var="errorPago">
            <sql:query var="resPago" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT pa.id_pago,
                             pa.tipo_pago,
                             pa.ruta_comprobante_pdf,
                             pa.estado_pago,
                             pa.fecha_pago
                        FROM PAGOS_PROYECTO pa
                       WHERE pa.id_estudiante = ?
                         AND pa.tipo_pago = 'DERECHOS_GRADO'
                       ORDER BY pa.id_pago DESC
                       LIMIT 1
                  ) t
                <sql:param value="${u.id_usuario}" />
            </sql:query>
        </c:catch>

        <c:choose>
            <c:when test="${not empty errorPago or empty resPago or resPago.rowCount == 0}">
                <div class="alert alert-warning small" role="alert">
                    <i class="bi bi-exclamation-triangle me-1"></i>
                    No hay un pago de derechos de grado registrado para su usuario.
                </div>
            </c:when>
            <c:otherwise>
                <c:set var="pago" value="${resPago.rows[0]}" />
                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-body small">
                        <div class="row g-3">
                            <div class="col-12 col-md-4">
                                <span class="text-muted d-block">Estado del pago</span>
                                <c:choose>
                                    <c:when test="${pago.estado_pago eq 'APROBADO'}">
                                        <span class="badge bg-success">APROBADO</span>
                                    </c:when>
                                    <c:when test="${pago.estado_pago eq 'PENDIENTE'}">
                                        <span class="badge bg-warning text-dark">PENDIENTE</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-danger">
                                            <c:out value="${pago.estado_pago}" />
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                            <div class="col-12 col-md-4">
                                <span class="text-muted d-block">Tipo de pago</span>
                                <strong><c:out value="${pago.tipo_pago}" /></strong>
                            </div>
                            <div class="col-12 col-md-4">
                                <span class="text-muted d-block">Fecha de registro</span>
                                <strong>
                                    <fmt:formatDate value="${pago.fecha_pago}" pattern="dd/MM/yyyy" />
                                </strong>
                            </div>
                            <div class="col-12">
                                <span class="text-muted d-block">Comprobante (simulación de ruta PDF)</span>
                                <code><c:out value="${pago.ruta_comprobante_pdf}" /></code>
                            </div>
                        </div>
                    </div>
                </div>
            </c:otherwise>
        </c:choose>

        <div class="d-flex flex-wrap gap-2">
            <a href="dashboard.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-speedometer2 me-2"></i>Volver al panel
            </a>
            <a href="banco_ideas.jsp" class="btn btn-outline-success">
                <i class="bi bi-lightbulb me-2"></i>Ver banco de propuestas
            </a>
            <a href="solicitudes_estudiante.jsp" class="btn btn-outline-danger">
                <i class="bi bi-file-earmark-medical me-2"></i>Solicitudes especiales
            </a>
        </div>

    </c:otherwise>

</c:choose>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
