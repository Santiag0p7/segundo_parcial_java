<%--
    =====================================================================
    comite_informes.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 8 (RF-32 a RF-35)
    ---------------------------------------------------------------------
    Módulo exclusivo del COMITE.

      RF-32  Filtro de búsqueda avanzada: código del estudiante, nivel de
             formación y estado del proyecto.
      RF-33  Informe 1: estado de avance de los proyectos por estudiante.
      RF-34  Informe 2: carga de proyectos por DIRECTOR (GROUP BY).
      RF-35  Informe 3: carga de proyectos por EVALUADOR (GROUP BY).

    FILTROS OPCIONALES SIN SQL DINÁMICO: `<sql:query>` no admite etiquetas
    JSTL dentro de su cuerpo, así que no se puede "armar" el WHERE con
    <c:if>. Se usa el patrón de parámetro repetido:

        AND (? = '' OR ep.codigo_estudiantil LIKE CONCAT('%', ?, '%'))
        AND (? = '' OR pa.nivel_formacion = ?)
        AND (? = '' OR g.estado = ?)

    Con el filtro vacío la condición es verdadera y no filtra nada; con
    valor, compara. Son seis <sql:param> (cada valor va dos veces), en el
    mismo orden en que aparecen los "?".

    La búsqueda es por GET porque es una consulta de solo lectura: así el
    comité puede guardar o compartir la URL con los filtros aplicados.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para consultar los informes." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'COMITE' and u.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="Los informes de gestión son exclusivos del comité de trabajos de grado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Filtros (lista blanca para nivel y estado)
     ========================================================= --%>
<c:set var="fCodigo" value="${fn:trim(param.codigo)}" />

<c:set var="fNivel" value="${param.nivel}" />
<c:if test="${fNivel ne 'TECNOLOGIA' and fNivel ne 'INGENIERIA'}">
    <c:set var="fNivel" value="" />
</c:if>

<c:set var="fEstado" value="${param.estado}" />
<c:if test="${fEstado ne 'EN_PROCESO' and fEstado ne 'APROBADO'
              and fEstado ne 'EXONERADO' and fEstado ne 'CANCELADO'}">
    <c:set var="fEstado" value="" />
</c:if>

<c:set var="hayFiltros" value="${not empty fCodigo or not empty fNivel or not empty fEstado}" />

<%-- =========================================================
     3) Informe 1 (RF-33): avance de los proyectos por estudiante
     ========================================================= --%>
<c:catch var="errorAvance">
    <sql:query var="resAvance" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT g.id_proyecto,
                     g.titulo,
                     g.fase_actual,
                     g.estado,
                     g.fecha_registro,
                     f.nombre_fase        AS nombre_fase,
                     COALESCE(CONCAT(est.nombres, ' ', est.apellidos), 'Sin líder') AS estudiante,
                     ep.codigo_estudiantil AS codigo_estudiantil,
                     pa.nivel_formacion    AS nivel_formacion,
                     (SELECT COUNT(*)
                        FROM INTEGRANTES_PROYECTO i2
                       WHERE i2.id_proyecto = g.id_proyecto) AS integrantes,
                     (SELECT COUNT(*)
                        FROM ENTREGABLES en
                       WHERE en.id_proyecto = g.id_proyecto) AS entregables,
                     (SELECT CONCAT(ud.nombres, ' ', ud.apellidos)
                        FROM ASIGNACIONES_DOCENTES a2
                             INNER JOIN USUARIOS ud ON ud.id_usuario = a2.id_docente
                       WHERE a2.id_proyecto = g.id_proyecto
                         AND a2.subrol = 'DIRECTOR'
                       LIMIT 1) AS director,
                     (SELECT CONCAT(ue.nombres, ' ', ue.apellidos)
                        FROM ASIGNACIONES_DOCENTES a3
                             INNER JOIN USUARIOS ue ON ue.id_usuario = a3.id_docente
                       WHERE a3.id_proyecto = g.id_proyecto
                         AND a3.subrol = 'EVALUADOR'
                       LIMIT 1) AS evaluador,
                     (SELECT DATE_FORMAT(s.fecha_hora_programada, '%d/%m/%Y %H:%i')
                        FROM SUSTENTACIONES s
                       WHERE s.id_proyecto = g.id_proyecto
                       ORDER BY s.id_sustentacion DESC
                       LIMIT 1) AS fecha_sustentacion
                FROM PROYECTOS_GRADO g
                     LEFT JOIN INTEGRANTES_PROYECTO il
                            ON il.id_proyecto = g.id_proyecto AND il.es_lider = 1
                     LEFT JOIN USUARIOS est ON est.id_usuario = il.id_estudiante
                     LEFT JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = est.id_usuario
                     LEFT JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
                     LEFT JOIN FASES_CICLO f ON f.numero_fase = g.fase_actual
               WHERE (? = '' OR ep.codigo_estudiantil LIKE CONCAT('%', ?, '%'))
                 AND (? = '' OR pa.nivel_formacion = ?)
                 AND (? = '' OR g.estado = ?)
          ) t
         ORDER BY t.fecha_registro DESC
        <sql:param value="${fCodigo}" />
        <sql:param value="${fCodigo}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fEstado}" />
        <sql:param value="${fEstado}" />
    </sql:query>
</c:catch>

<%-- =========================================================
     4) Informe 2 (RF-34): carga por DIRECTOR
     ========================================================= --%>
<c:catch var="errorDirector">
    <sql:query var="resDirector" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT CONCAT(ud.nombres, ' ', ud.apellidos) AS docente,
                     COALESCE(d.especialidad, '—')          AS especialidad,
                     COUNT(DISTINCT g.id_proyecto)          AS total,
                     SUM(CASE WHEN g.estado = 'EN_PROCESO' THEN 1 ELSE 0 END) AS en_proceso,
                     SUM(CASE WHEN g.estado = 'APROBADO'   THEN 1 ELSE 0 END) AS aprobados,
                     SUM(CASE WHEN g.estado = 'EXONERADO'  THEN 1 ELSE 0 END) AS exonerados,
                     SUM(CASE WHEN g.estado = 'CANCELADO'  THEN 1 ELSE 0 END) AS cancelados
                FROM ASIGNACIONES_DOCENTES a
                     INNER JOIN USUARIOS ud ON ud.id_usuario = a.id_docente
                     LEFT  JOIN DOCENTES_PERFIL d ON d.id_docente = a.id_docente
                     INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = a.id_proyecto
                     LEFT  JOIN INTEGRANTES_PROYECTO il
                            ON il.id_proyecto = g.id_proyecto AND il.es_lider = 1
                     LEFT  JOIN USUARIOS est ON est.id_usuario = il.id_estudiante
                     LEFT  JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = est.id_usuario
                     LEFT  JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
               WHERE a.subrol = 'DIRECTOR'
                 AND (? = '' OR ep.codigo_estudiantil LIKE CONCAT('%', ?, '%'))
                 AND (? = '' OR pa.nivel_formacion = ?)
                 AND (? = '' OR g.estado = ?)
               GROUP BY ud.id_usuario, ud.nombres, ud.apellidos, d.especialidad
          ) t
         ORDER BY t.total DESC, t.docente
        <sql:param value="${fCodigo}" />
        <sql:param value="${fCodigo}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fEstado}" />
        <sql:param value="${fEstado}" />
    </sql:query>
</c:catch>

<%-- =========================================================
     5) Informe 3 (RF-35): carga por EVALUADOR
     ========================================================= --%>
<c:catch var="errorEvaluador">
    <sql:query var="resEvaluador" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT CONCAT(ud.nombres, ' ', ud.apellidos) AS docente,
                     COALESCE(d.especialidad, '—')          AS especialidad,
                     COUNT(DISTINCT g.id_proyecto)          AS total,
                     SUM(CASE WHEN g.estado = 'EN_PROCESO' THEN 1 ELSE 0 END) AS en_proceso,
                     SUM(CASE WHEN g.estado = 'APROBADO'   THEN 1 ELSE 0 END) AS aprobados,
                     SUM(CASE WHEN g.estado = 'EXONERADO'  THEN 1 ELSE 0 END) AS exonerados,
                     SUM(CASE WHEN g.estado = 'CANCELADO'  THEN 1 ELSE 0 END) AS cancelados
                FROM ASIGNACIONES_DOCENTES a
                     INNER JOIN USUARIOS ud ON ud.id_usuario = a.id_docente
                     LEFT  JOIN DOCENTES_PERFIL d ON d.id_docente = a.id_docente
                     INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = a.id_proyecto
                     LEFT  JOIN INTEGRANTES_PROYECTO il
                            ON il.id_proyecto = g.id_proyecto AND il.es_lider = 1
                     LEFT  JOIN USUARIOS est ON est.id_usuario = il.id_estudiante
                     LEFT  JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = est.id_usuario
                     LEFT  JOIN PROGRAMAS_ACADEMICOS pa ON pa.id_programa = ep.id_programa
               WHERE a.subrol = 'EVALUADOR'
                 AND (? = '' OR ep.codigo_estudiantil LIKE CONCAT('%', ?, '%'))
                 AND (? = '' OR pa.nivel_formacion = ?)
                 AND (? = '' OR g.estado = ?)
               GROUP BY ud.id_usuario, ud.nombres, ud.apellidos, d.especialidad
          ) t
         ORDER BY t.total DESC, t.docente
        <sql:param value="${fCodigo}" />
        <sql:param value="${fCodigo}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fNivel}" />
        <sql:param value="${fEstado}" />
        <sql:param value="${fEstado}" />
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Informes y búsquedas - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-graph-up-arrow text-success me-2"></i>
            Informes y búsquedas
        </h1>
    </div>
    <a href="dashboard.jsp" class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-speedometer2 me-1"></i>Volver al panel
    </a>
</div>

<c:if test="${not empty errorAvance or not empty errorDirector or not empty errorEvaluador}">
    <div class="alert alert-warning d-flex align-items-start" role="alert">
        <i class="bi bi-plug-fill me-2 mt-1"></i>
        <div>
            <strong>Alguno de los informes no se pudo generar.</strong><br />
            <span class="small">Verifique el servicio de base de datos e intente de nuevo.</span>
        </div>
    </div>
</c:if>

<%-- =========================================================
     6) RF-32: filtro de búsqueda
     ========================================================= --%>
<div class="card shadow-sm border-0 mb-4">
    <div class="card-header bg-white">
        <h2 class="h6 mb-0">
            <i class="bi bi-funnel text-success me-2"></i>
            Filtro de búsqueda <span class="badge bg-light text-dark">RF-32</span>
        </h2>
    </div>
    <div class="card-body">
        <form action="comite_informes.jsp" method="get" accept-charset="UTF-8">
            <div class="row g-2 align-items-end">

                <div class="col-12 col-md-4">
                    <label for="codigo" class="form-label small fw-semibold">Código del estudiante</label>
                    <div class="input-group input-group-sm">
                        <span class="input-group-text"><i class="bi bi-person-vcard"></i></span>
                        <input type="text" class="form-control" id="codigo" name="codigo"
                               maxlength="20" value="${fn:escapeXml(fCodigo)}"
                               placeholder="Ej.: ST-1002" />
                    </div>
                </div>

                <div class="col-6 col-md-3">
                    <label for="nivel" class="form-label small fw-semibold">Nivel de formación</label>
                    <select class="form-select form-select-sm" id="nivel" name="nivel">
                        <option value="">— Todos —</option>
                        <option value="TECNOLOGIA" <c:if test="${fNivel eq 'TECNOLOGIA'}">selected</c:if>>
                            Tecnología
                        </option>
                        <option value="INGENIERIA" <c:if test="${fNivel eq 'INGENIERIA'}">selected</c:if>>
                            Ingeniería
                        </option>
                    </select>
                </div>

                <div class="col-6 col-md-3">
                    <label for="estado" class="form-label small fw-semibold">Estado del proyecto</label>
                    <select class="form-select form-select-sm" id="estado" name="estado">
                        <option value="">— Todos —</option>
                        <option value="EN_PROCESO" <c:if test="${fEstado eq 'EN_PROCESO'}">selected</c:if>>
                            En proceso
                        </option>
                        <option value="APROBADO" <c:if test="${fEstado eq 'APROBADO'}">selected</c:if>>
                            Aprobado
                        </option>
                        <option value="EXONERADO" <c:if test="${fEstado eq 'EXONERADO'}">selected</c:if>>
                            Exonerado
                        </option>
                        <option value="CANCELADO" <c:if test="${fEstado eq 'CANCELADO'}">selected</c:if>>
                            Cancelado
                        </option>
                    </select>
                </div>

                <div class="col-12 col-md-2 d-flex gap-2">
                    <button type="submit" class="btn btn-success btn-sm flex-grow-1">
                        <i class="bi bi-search me-1"></i>Buscar
                    </button>
                    <a href="comite_informes.jsp" class="btn btn-outline-secondary btn-sm"
                       title="Limpiar filtros">
                        <i class="bi bi-x-circle"></i>
                    </a>
                </div>

            </div>
        </form>

        <c:if test="${hayFiltros}">
            <div class="mt-3 d-flex flex-wrap align-items-center gap-2 small">
                <span class="text-muted">Filtros aplicados:</span>
                <c:if test="${not empty fCodigo}">
                    <span class="badge bg-primary">Código: <c:out value="${fCodigo}" /></span>
                </c:if>
                <c:if test="${not empty fNivel}">
                    <span class="badge bg-primary">Nivel: <c:out value="${fNivel}" /></span>
                </c:if>
                <c:if test="${not empty fEstado}">
                    <span class="badge bg-primary">Estado: <c:out value="${fEstado}" /></span>
                </c:if>
            </div>
        </c:if>
    </div>
</div>

<%-- =========================================================
     7) Informe 1 (RF-33)
     ========================================================= --%>
<div class="card shadow-sm border-0 mb-4">
    <div class="card-header bg-white d-flex flex-wrap justify-content-between align-items-center gap-2">
        <h2 class="h6 mb-0">
            <i class="bi bi-list-check text-success me-2"></i>
            Informe 1: avance de los proyectos por estudiante
            <span class="badge bg-light text-dark">RF-33</span>
        </h2>
        <span class="badge bg-success">
            <c:out value="${empty resAvance ? 0 : resAvance.rowCount}" /> proyecto(s)
        </span>
    </div>
    <div class="card-body p-0">
        <c:choose>
            <c:when test="${not empty errorAvance}">
                <p class="text-muted small p-3 mb-0">No fue posible generar este informe.</p>
            </c:when>
            <c:when test="${empty resAvance or resAvance.rowCount == 0}">
                <p class="text-muted small p-3 mb-0">
                    <i class="bi bi-inbox me-1"></i>
                    No hay proyectos que coincidan con los filtros.
                </p>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-success">
                            <tr>
                                <th scope="col">Estudiante líder</th>
                                <th scope="col">Código</th>
                                <th scope="col">Nivel</th>
                                <th scope="col">Proyecto</th>
                                <th scope="col">Fase</th>
                                <th scope="col">Estado</th>
                                <th scope="col">Integr.</th>
                                <th scope="col">Entreg.</th>
                                <th scope="col">Director</th>
                                <th scope="col">Evaluador</th>
                                <th scope="col">Sustentación</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="p" items="${resAvance.rows}">
                                <tr>
                                    <td class="small"><c:out value="${p.estudiante}" /></td>
                                    <td class="small">
                                        <c:out value="${empty p.codigo_estudiantil ? '—' : p.codigo_estudiantil}" />
                                    </td>
                                    <td class="small">
                                        <c:choose>
                                            <c:when test="${p.nivel_formacion eq 'INGENIERIA'}">
                                                <span class="badge bg-primary">INGENIERÍA</span>
                                            </c:when>
                                            <c:when test="${p.nivel_formacion eq 'TECNOLOGIA'}">
                                                <span class="badge bg-info text-dark">TECNOLOGÍA</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">—</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="small"><c:out value="${p.titulo}" /></td>
                                    <td class="small text-center">
                                        <span class="badge bg-secondary"><c:out value="${p.fase_actual}" /></span>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${p.estado eq 'EN_PROCESO'}">
                                                <span class="badge bg-primary">EN PROCESO</span>
                                            </c:when>
                                            <c:when test="${p.estado eq 'APROBADO'}">
                                                <span class="badge bg-success">APROBADO</span>
                                            </c:when>
                                            <c:when test="${p.estado eq 'EXONERADO'}">
                                                <span class="badge bg-info text-dark">EXONERADO</span>
                                            </c:when>
                                            <c:when test="${p.estado eq 'CANCELADO'}">
                                                <span class="badge bg-danger">CANCELADO</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">
                                                    <c:out value="${p.estado}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="small text-center"><c:out value="${p.integrantes}" /></td>
                                    <td class="small text-center"><c:out value="${p.entregables}" /></td>
                                    <td class="small"><c:out value="${empty p.director ? '—' : p.director}" /></td>
                                    <td class="small"><c:out value="${empty p.evaluador ? '—' : p.evaluador}" /></td>
                                    <td class="small text-nowrap">
                                        <c:choose>
                                            <c:when test="${not empty p.fecha_sustentacion}">
                                                <c:out value="${p.fecha_sustentacion}" />
                                            </c:when>
                                            <c:otherwise>—</c:otherwise>
                                        </c:choose>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </div>
</div>

<%-- =========================================================
     8) Informe 2 (RF-34) e Informe 3 (RF-35)
     ========================================================= --%>
<div class="row g-4">

    <%-- -------- Carga por director -------- --%>
    <div class="col-12 col-xl-6">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-header bg-white d-flex flex-wrap justify-content-between align-items-center gap-2">
                <h2 class="h6 mb-0">
                    <i class="bi bi-person-badge text-success me-2"></i>
                    Informe 2: carga por director
                    <span class="badge bg-light text-dark">RF-34</span>
                </h2>
                <span class="badge bg-success">
                    <c:out value="${empty resDirector ? 0 : resDirector.rowCount}" /> docente(s)
                </span>
            </div>
            <div class="card-body p-0">
                <c:choose>
                    <c:when test="${not empty errorDirector}">
                        <p class="text-muted small p-3 mb-0">No fue posible generar este informe.</p>
                    </c:when>
                    <c:when test="${empty resDirector or resDirector.rowCount == 0}">
                        <p class="text-muted small p-3 mb-0">
                            <i class="bi bi-inbox me-1"></i>Sin directores con proyectos para los filtros.
                        </p>
                    </c:when>
                    <c:otherwise>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-success">
                                    <tr>
                                        <th scope="col">Director</th>
                                        <th scope="col">Especialidad</th>
                                        <th scope="col" class="text-center">Total</th>
                                        <th scope="col" class="text-center">En proceso</th>
                                        <th scope="col" class="text-center">Aprobados</th>
                                        <th scope="col" class="text-center">Exonerados</th>
                                        <th scope="col" class="text-center">Cancelados</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="c" items="${resDirector.rows}">
                                        <tr>
                                            <td class="small fw-semibold"><c:out value="${c.docente}" /></td>
                                            <td class="small text-muted"><c:out value="${c.especialidad}" /></td>
                                            <td class="text-center">
                                                <span class="badge bg-success"><c:out value="${c.total}" /></span>
                                            </td>
                                            <td class="small text-center"><c:out value="${c.en_proceso}" /></td>
                                            <td class="small text-center"><c:out value="${c.aprobados}" /></td>
                                            <td class="small text-center"><c:out value="${c.exonerados}" /></td>
                                            <td class="small text-center"><c:out value="${c.cancelados}" /></td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>

    <%-- -------- Carga por evaluador -------- --%>
    <div class="col-12 col-xl-6">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-header bg-white d-flex flex-wrap justify-content-between align-items-center gap-2">
                <h2 class="h6 mb-0">
                    <i class="bi bi-person-check text-success me-2"></i>
                    Informe 3: carga por evaluador
                    <span class="badge bg-light text-dark">RF-35</span>
                </h2>
                <span class="badge bg-success">
                    <c:out value="${empty resEvaluador ? 0 : resEvaluador.rowCount}" /> docente(s)
                </span>
            </div>
            <div class="card-body p-0">
                <c:choose>
                    <c:when test="${not empty errorEvaluador}">
                        <p class="text-muted small p-3 mb-0">No fue posible generar este informe.</p>
                    </c:when>
                    <c:when test="${empty resEvaluador or resEvaluador.rowCount == 0}">
                        <p class="text-muted small p-3 mb-0">
                            <i class="bi bi-inbox me-1"></i>Sin evaluadores con proyectos para los filtros.
                        </p>
                    </c:when>
                    <c:otherwise>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-success">
                                    <tr>
                                        <th scope="col">Evaluador</th>
                                        <th scope="col">Especialidad</th>
                                        <th scope="col" class="text-center">Total</th>
                                        <th scope="col" class="text-center">En proceso</th>
                                        <th scope="col" class="text-center">Aprobados</th>
                                        <th scope="col" class="text-center">Exonerados</th>
                                        <th scope="col" class="text-center">Cancelados</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="c" items="${resEvaluador.rows}">
                                        <tr>
                                            <td class="small fw-semibold"><c:out value="${c.docente}" /></td>
                                            <td class="small text-muted"><c:out value="${c.especialidad}" /></td>
                                            <td class="text-center">
                                                <span class="badge bg-success"><c:out value="${c.total}" /></span>
                                            </td>
                                            <td class="small text-center"><c:out value="${c.en_proceso}" /></td>
                                            <td class="small text-center"><c:out value="${c.aprobados}" /></td>
                                            <td class="small text-center"><c:out value="${c.exonerados}" /></td>
                                            <td class="small text-center"><c:out value="${c.cancelados}" /></td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>

</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
