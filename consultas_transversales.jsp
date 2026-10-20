<%--
    =====================================================================
    consultas_transversales.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  RF-30
    ---------------------------------------------------------------------
    Vista TRANSVERSAL: la puede consultar cualquier usuario autenticado
    (estudiante, docente, comité o administrador).

    Muestra el CALENDARIO ACADÉMICO INSTITUCIONAL (hitos y fechas de
    entrega del semestre) y, al costado, las fases del ciclo leídas de
    FASES_CICLO.

    ¿POR QUÉ EL CALENDARIO NO SALE DE LA BASE DE DATOS? El esquema no tiene
    tabla de calendario institucional: ENTREGABLES guarda las entregas de
    cada proyecto, no las fechas del semestre. Por eso los hitos se declaran
    aquí como datos institucionales (una cadena separada por ";" y "|" que
    se recorre con fn:split), sin scriptlets ni Java embebido. Las fases,
    que sí están normalizadas, se consultan de FASES_CICLO.

    Formato de cada registro:  hito | fase | fecha | descripción
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso: cualquier rol autenticado
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para consultar el calendario académico." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<%-- =========================================================
     2) Calendario institucional 2026-2
        Fuente: Acuerdo 03-024 del 07/04/2026 (Consejo Académico)
                y modificación 03-075 del 22/09/2026 (graduaciones).
        Formato: hito | fase | fecha | descripción
     ========================================================= --%>
<c:set var="hitosTexto"
       value="Pago de matrícula|0|06/07/2026 al 23/07/2026|Estudiantes nuevos y antiguos, modalidad presencial y virtual.;Matrícula y registro de cursos|0|Hasta 25/07/2026|Cierre del registro de cursos del semestre en el sistema académico.;Publicación de la lista de matriculados|0|05/08/2026|Estudiantes nuevos, niveles tecnológico y universitario.;Inducción a estudiantes nuevos - modalidad virtual|0|06/08/2026|Jornada de inducción institucional.;Inicio de clases|0|10/08/2026|Todas las modalidades y jornadas.;Inducción a estudiantes nuevos - modalidad presencial|0|18/08/2026 al 21/08/2026|Jornada de inducción institucional.;Inducción y reinducción docente|0|24/08/2026 al 28/08/2026|Actividad académica general.;Revisión de matrícula académica|0|Hasta 31/08/2026|A cargo de la coordinación académica.;Inscripción de la modalidad de trabajo de grado|1|Hasta 05/09/2026|Registro en la coordinación del programa académico.;Solicitud de devolución del derecho pecuniario de matrícula|0|Hasta 07/09/2026|Según el Artículo 18 del Reglamento Estudiantil.;Primer parcial|0|14/09/2026 al 19/09/2026|Evaluación del primer corte.;Registro de notas del primer corte|0|14/09/2026 al 30/09/2026|Registro en el sistema académico.;Supletorio del primer parcial|0|21/09/2026 al 26/09/2026|Evaluación supletoria.;Cancelación del derecho pecuniario de trabajo de grado|1|Hasta 02/10/2026|Excepto la modalidad de seminario.;Evaluación docente|0|05/10/2026 al 04/11/2026|Actividad académica general.;Segundo parcial|0|19/10/2026 al 24/10/2026|Evaluación del segundo corte.;Registro de notas del segundo corte|0|19/10/2026 al 07/11/2026|Registro en el sistema académico.;Supletorio del segundo parcial|0|26/10/2026 al 31/10/2026|Evaluación supletoria.;Aprobación de la propuesta de trabajo de grado|2|Hasta 30/10/2026|Aval de la propuesta ante la coordinación del programa.;Graduación única - sede Vélez|0|19/11/2026|Ceremonia de graduación.;Cancelación de semestre|0|Hasta 20/11/2026|Trámite ante la coordinación académica.;Cancelación de cursos|0|Hasta 21/11/2026|Trámite ante la coordinación académica.;Finalización de clases|0|28/11/2026|Cierre del período académico.;Registro de notas del tercer corte|0|30/11/2026 al 11/12/2026|Registro en el sistema académico.;Graduación - sede Barrancabermeja|0|03/12/2026|Segunda ceremonia del período.;Graduación - modalidad virtual|0|09/12/2026|Segunda ceremonia del período.;Graduación - Bucaramanga y Piedecuesta|0|10/12/2026 y 11/12/2026|Segunda ceremonia del período.;Entrega de actas de notas|0|Hasta 14/12/2026|Actas de todos los cortes a la coordinación académica.;Habilitaciones|0|14/12/2026 al 16/12/2026|Evaluaciones de habilitación.;Registro de notas de habilitaciones|0|14/12/2026 al 17/12/2026|Registro en el sistema académico." />

<c:set var="hitos" value="${fn:split(hitosTexto, ';')}" />

<%-- Fases del ciclo (esto sí viene de la base de datos) --%>
<c:catch var="errorFases">
    <sql:query var="resFases" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT f.numero_fase, f.nombre_fase
                FROM FASES_CICLO f
          ) t
         ORDER BY t.numero_fase
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Calendario académico - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-calendar3 text-success me-2"></i>
            Calendario académico
        </h1>
    </div>
    <a href="dashboard.jsp" class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-speedometer2 me-1"></i>Volver al panel
    </a>
</div>

<%-- =========================================================
     3) Calendario (hitos) y fases del ciclo
     ========================================================= --%>
<div class="row g-4">

    <div class="col-12 col-lg-8">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-header bg-white">
                <h2 class="h6 mb-0">
                    <i class="bi bi-calendar-event text-success me-2"></i>
                    Calendario académico 2026-2
                </h2>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm table-hover align-middle mb-0">
                        <thead class="table-success">
                            <tr>
                                <th scope="col">Hito / entrega</th>
                                <th scope="col">Fase</th>
                                <th scope="col">Fecha</th>
                                <th scope="col">Descripción</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="h" items="${hitos}">
                                <c:set var="campos" value="${fn:split(h, '|')}" />
                                <tr>
                                    <td class="fw-semibold small">
                                        <c:out value="${campos[0]}" />
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${campos[1] eq '0'}">
                                                <span class="badge bg-secondary">Institucional</span>
                                            </c:when>
                                            <c:when test="${campos[1] eq '6'}">
                                                <span class="badge bg-success">Fase 6</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-primary">
                                                    Fase <c:out value="${campos[1]}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="small text-nowrap">
                                        <i class="bi bi-clock text-muted me-1"></i>
                                        <c:out value="${campos[2]}" />
                                    </td>
                                    <td class="small text-muted">
                                        <c:out value="${campos[3]}" />
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="card-footer bg-white small text-muted">
                <i class="bi bi-file-earmark-text me-1"></i>
                Fuente: Acuerdo 03-024 del 07/04/2026 y modificación 03-075 del 22/09/2026,
                Consejo Académico UTS.
            </div>
        </div>
    </div>

    <div class="col-12 col-lg-4">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-header bg-white">
                <h2 class="h6 mb-0">
                    <i class="bi bi-diagram-3 text-success me-2"></i>
                    Fases del ciclo
                </h2>
            </div>
            <div class="card-body">
                <c:choose>
                    <c:when test="${not empty errorFases}">
                        <p class="text-muted small mb-0">
                            No fue posible consultar las fases del ciclo.
                        </p>
                    </c:when>
                    <c:when test="${empty resFases or resFases.rowCount == 0}">
                        <p class="text-muted small mb-0">No hay fases registradas.</p>
                    </c:when>
                    <c:otherwise>
                        <ol class="list-group list-group-numbered list-group-flush small">
                            <c:forEach var="f" items="${resFases.rows}">
                                <li class="list-group-item px-0">
                                    <c:out value="${f.nombre_fase}" />
                                </li>
                            </c:forEach>
                        </ol>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>

</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
