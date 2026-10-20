<%--
    =====================================================================
    comite_fase1.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 5 (Módulo 3, Fase 1)
    ---------------------------------------------------------------------
    Vista del COMITE: proyectos que están en la Fase 1 a la espera de que se
    verifique el soporte de pago de derechos de grado.

    Lista, por proyecto: título, integrantes (individual o dupla), ruta del
    PDF simulado y estado del pago. El botón «Aprobar Pago y Fase 1» hace
    dos cosas en un <sql:update> cada una:
        * PAGOS_PROYECTO.estado_pago  -> 'APROBADO'
        * PROYECTOS_GRADO.fase_actual -> 2

    PATRÓN PRG (Post/Redirect/Get) DENTRO DE LA MISMA PÁGINA:
    el enunciado pide el botón en esta vista, así que la aprobación se
    procesa arriba de todo, ANTES de incluir el header y de emitir
    cualquier HTML, y termina en un <c:redirect> a esta misma página. Si se
    escribiera HTML antes del redirect, Tomcat lanzaría
    IllegalStateException ("respuesta ya confirmada").

    RELACIÓN PAGO <-> PROYECTO: PAGOS_PROYECTO no tiene id_proyecto; se une
    por el estudiante LÍDER (es_lider = 1), que por el UNIQUE
    (id_estudiante) identifica al proyecto sin ambigüedad. Se toma el último
    pago de derechos de grado con MAX(id_pago) para no duplicar filas.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<fmt:requestEncoding value="UTF-8" />

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para revisar los pagos de la Fase 1." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'COMITE' and u.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La revisión de la Fase 1 corresponde al comité de trabajos de grado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) PRG: aprobar pago y avanzar a la Fase 2
     ========================================================= --%>
<c:if test="${not empty param.accion and param.accion eq 'aprobar'}">

    <c:catch var="errorAprobar">
        <sql:query var="resValidacion" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT pa.id_pago, g.id_proyecto, g.fase_actual, pa.estado_pago
                    FROM PAGOS_PROYECTO pa
                         INNER JOIN INTEGRANTES_PROYECTO i ON i.id_estudiante = pa.id_estudiante
                                                          AND i.es_lider = 1
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
                   WHERE pa.id_pago = ?
                     AND g.id_proyecto = ?
                     AND pa.tipo_pago = 'DERECHOS_GRADO'
                     AND pa.estado_pago = 'PENDIENTE'
                     AND g.fase_actual = 1
              ) t
            <sql:param value="${param.id_pago}" />
            <sql:param value="${param.id_proyecto}" />
        </sql:query>
    </c:catch>

    <c:choose>

        <%-- ---------- 2.a) La base de datos falló ---------- --%>
        <c:when test="${not empty errorAprobar}">
            <c:redirect url="comite_fase1.jsp">
                <c:param name="error" value="No fue posible aprobar el pago. Verifique la conexión a la base de datos." />
            </c:redirect>
        </c:when>

        <%-- ---------- 2.b) Pago/proyecto válidos: se aprueba ---------- --%>
        <c:when test="${not empty resValidacion and resValidacion.rowCount gt 0}">

            <c:catch var="errorUpdates">
                <sql:update var="resPagoAprobado" dataSource="${db}">
                    UPDATE PAGOS_PROYECTO
                       SET estado_pago = 'APROBADO'
                     WHERE id_pago = ?
                       AND estado_pago = 'PENDIENTE'
                    <sql:param value="${param.id_pago}" />
                </sql:update>

                <sql:update var="resFaseAvanzada" dataSource="${db}">
                    UPDATE PROYECTOS_GRADO
                       SET fase_actual = 2
                     WHERE id_proyecto = ?
                       AND fase_actual = 1
                    <sql:param value="${param.id_proyecto}" />
                </sql:update>
            </c:catch>

            <c:choose>
                <c:when test="${empty errorUpdates}">
                    <c:redirect url="comite_fase1.jsp">
                        <c:param name="msg" value="Pago aprobado: el proyecto avanzó a la Fase 2." />
                    </c:redirect>
                </c:when>
                <c:otherwise>
                    <c:redirect url="comite_fase1.jsp">
                        <c:param name="error" value="No fue posible actualizar el pago y la fase del proyecto." />
                    </c:redirect>
                </c:otherwise>
            </c:choose>

        </c:when>

        <%-- ---------- 2.c) No cumple las condiciones ---------- --%>
        <c:otherwise>
            <c:redirect url="comite_fase1.jsp">
                <c:param name="error" value="No se pudo aprobar: el pago debe estar PENDIENTE y el proyecto en Fase 1." />
            </c:redirect>
        </c:otherwise>

    </c:choose>

</c:if>

<%-- =========================================================
     3) Proyectos en Fase 1 con su líder y su último pago
     ========================================================= --%>
<c:catch var="errorListado">
    <sql:query var="resFase1" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT g.id_proyecto,
                     g.titulo,
                     g.fase_actual,
                     g.estado,
                     g.fecha_registro,
                     f.nombre_fase            AS nombre_fase,
                     p.descripcion            AS descripcion_idea,
                     c.id_usuario             AS id_lider,
                     c.nombres                AS nombres_lider,
                     c.apellidos              AS apellidos_lider,
                     cl.codigo_estudiantil    AS codigo_lider,
                     pa.id_pago               AS id_pago,
                     pa.ruta_comprobante_pdf  AS ruta_comprobante_pdf,
                     pa.estado_pago           AS estado_pago,
                     pa.fecha_pago            AS fecha_pago
                FROM PROYECTOS_GRADO g
                     LEFT JOIN FASES_CICLO f ON f.numero_fase = g.fase_actual
                     LEFT JOIN PROPUESTAS_PROYECTO p ON p.id_propuesta = g.id_propuesta
                     INNER JOIN INTEGRANTES_PROYECTO il ON il.id_proyecto = g.id_proyecto
                                                       AND il.es_lider = 1
                     INNER JOIN USUARIOS c ON c.id_usuario = il.id_estudiante
                     LEFT JOIN ESTUDIANTES_PERFIL cl ON cl.id_estudiante = c.id_usuario
                     LEFT JOIN PAGOS_PROYECTO pa
                            ON pa.id_pago = (SELECT MAX(p2.id_pago)
                                               FROM PAGOS_PROYECTO p2
                                              WHERE p2.id_estudiante = c.id_usuario
                                                AND p2.tipo_pago = 'DERECHOS_GRADO')
               WHERE g.fase_actual = 1
                 AND g.estado = 'EN_PROCESO'
          ) t
         ORDER BY t.fecha_registro DESC, t.id_proyecto DESC
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Fase 1: pagos por aprobar - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- =========================================================
     4) Mensajes del PRG
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

<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-cash-coin text-success me-2"></i>
            Fase 1: verificación de pagos y registro de idea
        </h1>
    </div>
    <div>
        <a href="dashboard.jsp" class="btn btn-outline-secondary">
            <i class="bi bi-speedometer2 me-2"></i>Volver al panel
        </a>
    </div>
</div>

<c:choose>

    <%-- ---------- 4.a) Error de consulta ---------- --%>
    <c:when test="${not empty errorListado}">
        <div class="alert alert-warning d-flex align-items-start" role="alert">
            <i class="bi bi-plug-fill me-2 mt-1"></i>
            <div>
                <strong>No fue posible consultar los proyectos de la Fase 1.</strong><br />
                <span class="small">Verifique el servicio de base de datos e intente de nuevo.</span>
            </div>
        </div>
    </c:when>

    <%-- ---------- 4.b) No hay proyectos en Fase 1 ---------- --%>
    <c:when test="${empty resFase1 or resFase1.rowCount == 0}">
        <div class="card shadow-sm border-0">
            <div class="card-body text-center py-5">
                <i class="bi bi-check2-all text-success display-4"></i>
                <h2 class="h5 mt-3 mb-1">No hay proyectos pendientes en la Fase 1</h2>
                <p class="text-muted small mb-0">
                    Todos los proyectos registrados ya superaron la verificación de pago.
                </p>
            </div>
        </div>
    </c:when>

    <%-- ---------- 4.c) Listado ---------- --%>
    <c:otherwise>

        <p class="text-muted small">
            <i class="bi bi-list-check me-1"></i>
            Proyectos en Fase 1: <strong><c:out value="${resFase1.rowCount}" /></strong>
        </p>

        <div class="row row-cols-1 g-4">
            <c:forEach var="pr" items="${resFase1.rows}">
                <div class="col">

                    <div class="card shadow-sm border-0">
                        <div class="card-header bg-white d-flex justify-content-between align-items-start gap-2">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-journal-text text-success me-2"></i>
                                <c:out value="${pr.titulo}" />
                            </h2>
                            <span class="badge bg-warning text-dark flex-shrink-0">
                                <i class="bi bi-hourglass-split me-1"></i>FASE 1
                            </span>
                        </div>

                        <div class="card-body">

                            <div class="row g-3 small">

                                <%-- -------- Integrantes: individual o dupla -------- --%>
                                <div class="col-12 col-lg-6">
                                    <span class="text-muted d-block mb-1">
                                        <i class="bi bi-people-fill me-1"></i>Integrantes
                                    </span>

                                    <c:catch var="errorMiembros">
                                        <sql:query var="resMiembros" dataSource="${db}">
                                            SELECT t.*
                                              FROM (
                                                  SELECT m.nombres,
                                                         m.apellidos,
                                                         m.correo_institucional,
                                                         em.codigo_estudiantil AS codigo_estudiantil,
                                                         i.es_lider            AS es_lider
                                                    FROM INTEGRANTES_PROYECTO i
                                                         INNER JOIN USUARIOS m ON m.id_usuario = i.id_estudiante
                                                         LEFT  JOIN ESTUDIANTES_PERFIL em ON em.id_estudiante = m.id_usuario
                                                   WHERE i.id_proyecto = ?
                                                   ORDER BY i.es_lider DESC
                                              ) t
                                            <sql:param value="${pr.id_proyecto}" />
                                        </sql:query>
                                    </c:catch>

                                    <c:choose>
                                        <c:when test="${not empty errorMiembros or empty resMiembros or resMiembros.rowCount == 0}">
                                            <span class="text-muted">Sin integrantes registrados.</span>
                                        </c:when>
                                        <c:otherwise>
                                            <ul class="list-unstyled mb-0">
                                                <c:forEach var="m" items="${resMiembros.rows}">
                                                    <li>
                                                        <c:choose>
                                                            <%-- es_lider es BOOLEAN (java.lang.Boolean) --%>
                                                            <c:when test="${m.es_lider}">
                                                                <span class="badge bg-success me-1">Líder</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge bg-secondary me-1">Compañero</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                        <c:out value="${m.nombres}" /> <c:out value="${m.apellidos}" />
                                                        <span class="text-muted">
                                                            (<c:out value="${empty m.codigo_estudiantil ? 'sin código' : m.codigo_estudiantil}" />)
                                                        </span>
                                                    </li>
                                                </c:forEach>
                                            </ul>
                                            <c:if test="${resMiembros.rowCount gt 1}">
                                                <span class="badge bg-info text-dark mt-2">Dupla</span>
                                            </c:if>
                                            <c:if test="${resMiembros.rowCount eq 1}">
                                                <span class="badge bg-light text-dark mt-2">Individual</span>
                                            </c:if>
                                        </c:otherwise>
                                    </c:choose>
                                </div>

                                <%-- -------- RF-08: soporte de pago -------- --%>
                                <div class="col-12 col-lg-6">
                                    <span class="text-muted d-block mb-1">
                                        <i class="bi bi-receipt me-1"></i>Soporte de pago
                                    </span>

                                    <c:choose>
                                        <c:when test="${empty pr.id_pago}">
                                            <span class="badge bg-danger">Sin pago registrado</span>
                                            <div class="text-muted mt-1">
                                                El líder no tiene un pago de derechos de grado.
                                            </div>
                                        </c:when>
                                        <c:otherwise>
                                            <div class="mb-1">
                                                <c:choose>
                                                    <c:when test="${pr.estado_pago eq 'PENDIENTE'}">
                                                        <span class="badge bg-warning text-dark">PENDIENTE</span>
                                                    </c:when>
                                                    <c:when test="${pr.estado_pago eq 'APROBADO'}">
                                                        <span class="badge bg-success">APROBADO</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge bg-danger">
                                                            <c:out value="${pr.estado_pago}" />
                                                        </span>
                                                    </c:otherwise>
                                                </c:choose>
                                                <span class="text-muted">
                                                    · <fmt:formatDate value="${pr.fecha_pago}" pattern="dd/MM/yyyy" />
                                                </span>
                                            </div>
                                            <div>
                                                <i class="bi bi-file-earmark-pdf-fill text-danger me-1"></i>
                                                <a href="${fn:escapeXml(fn:startsWith(pr.ruta_comprobante_pdf, 'http') ? pr.ruta_comprobante_pdf : pdfDemo)}" target="_blank"
                                                   title="Comprobante de pago">
                                                    <c:out value="${pr.ruta_comprobante_pdf}" />
                                                </a>
                                            </div>
                                        </c:otherwise>
                                    </c:choose>
                                </div>

                                <%-- -------- Idea / descripción -------- --%>
                                <c:if test="${not empty pr.descripcion_idea}">
                                    <div class="col-12">
                                        <span class="text-muted d-block mb-1">Idea del proyecto</span>
                                        <div style="white-space: pre-wrap;"><c:out value="${pr.descripcion_idea}" /></div>
                                    </div>
                                </c:if>

                            </div>
                        </div>

                        <%-- -------- Acción del comité -------- --%>
                        <div class="card-footer bg-transparent border-0 d-flex flex-wrap justify-content-between align-items-center gap-2">
                            <span class="small text-muted">
                                Registrado el
                                <fmt:formatDate value="${pr.fecha_registro}" pattern="dd/MM/yyyy" />
                            </span>

                            <c:choose>
                                <c:when test="${empty pr.id_pago}">
                                    <button type="button" class="btn btn-secondary btn-sm" disabled>
                                        <i class="bi bi-slash-circle me-1"></i>Sin soporte de pago
                                    </button>
                                </c:when>
                                <c:when test="${pr.estado_pago ne 'PENDIENTE'}">
                                    <button type="button" class="btn btn-secondary btn-sm" disabled>
                                        <i class="bi bi-check2-circle me-1"></i>Pago ya gestionado
                                    </button>
                                </c:when>
                                <c:otherwise>
                                    <form action="comite_fase1.jsp" method="post"
                                          onsubmit="return confirm('¿Confirma la aprobación del pago y el avance del proyecto a la Fase 2?');">
                                        <input type="hidden" name="accion" value="aprobar" />
                                        <input type="hidden" name="id_pago" value="${fn:escapeXml(pr.id_pago)}" />
                                        <input type="hidden" name="id_proyecto" value="${fn:escapeXml(pr.id_proyecto)}" />
                                        <button type="submit" class="btn btn-success btn-sm">
                                            <i class="bi bi-shield-check me-1"></i>Aprobar Pago y Fase 1
                                        </button>
                                    </form>
                                </c:otherwise>
                            </c:choose>
                        </div>

                    </div>
                </div>
            </c:forEach>
        </div>

    </c:otherwise>

</c:choose>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
