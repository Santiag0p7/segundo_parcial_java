<%--
    =====================================================================
    programar_sustentacion.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 8 (RF-16)
    ---------------------------------------------------------------------
    Vista del COMITE para programar la sustentación oral de los proyectos
    que están en la Fase 6.

      * Lista los proyectos con fase_actual = 6.
      * Formulario por proyecto: lugar_salon + fecha_hora_programada
        (input datetime-local).
      * Al guardar:
          INSERT / UPDATE en SUSTENTACIONES
          UPDATE PROYECTOS_GRADO SET estado = 'APROBADO'
        El UPDATE se hace en una etiqueta aparte por la limitación de JSTL
        (no hay transacciones).

    También muestra el DIRECTOR y el EVALUADOR asignados: en Fase 6 la
    identidad del evaluador ya es pública (RF-11 / RNF-02).

    PATRÓN: procesa el POST antes de cualquier salida y deja todo el render
    dentro de <c:if test="${empty param.accion}">, para no escribir HTML
    después de <c:redirect> (riesgo de IllegalStateException).

    NOTA SOBRE LA FECHA: el input datetime-local envía "AAAA-MM-DDTHH:MM".
    Se reemplaza la "T" por un espacio con fn:replace y MySQL interpreta el
    literal como DATETIME.
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
        <c:param name="error" value="Debe iniciar sesión para programar sustentaciones." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'COMITE' and u.rol ne 'ADMINISTRADOR'}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La programación de sustentaciones corresponde al comité de trabajos de grado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Procesamiento (solo cuando llega el POST)
     ========================================================= --%>
<c:if test="${not empty param.accion}">

    <c:set var="errorAccion" value="" />
    <c:set var="okAccion" value="${false}" />

    <c:choose>

        <c:when test="${param.accion eq 'programar'}">

            <c:set var="lugar" value="${fn:trim(param.lugar_salon)}" />
            <%-- datetime-local -> "AAAA-MM-DD HH:MM" --%>
            <c:set var="fechaHora" value="${fn:replace(fn:trim(param.fecha_hora), 'T', ' ')}" />

            <c:if test="${empty param.id_proyecto}">
                <c:set var="errorAccion" value="No se recibió el proyecto a programar." />
            </c:if>

            <c:if test="${empty errorAccion and empty lugar}">
                <c:set var="errorAccion" value="Debe indicar el salón o auditorio de la sustentación." />
            </c:if>

            <c:if test="${empty errorAccion and fn:length(lugar) gt 100}">
                <c:set var="errorAccion" value="El salón no puede superar los 100 caracteres." />
            </c:if>

            <c:if test="${empty errorAccion and empty fechaHora}">
                <c:set var="errorAccion" value="Debe indicar la fecha y la hora de la sustentación." />
            </c:if>

            <%-- El proyecto debe existir y estar en Fase 6 --%>
            <c:if test="${empty errorAccion}">
                <c:catch var="errorProyecto">
                    <sql:query var="resProyecto" dataSource="${db}">
                        SELECT t.*
                          FROM (
                              SELECT g.id_proyecto, g.titulo, g.fase_actual
                                FROM PROYECTOS_GRADO g
                               WHERE g.id_proyecto = ?
                                 AND g.fase_actual = 6
                          ) t
                        <sql:param value="${param.id_proyecto}" />
                    </sql:query>
                </c:catch>

                <c:choose>
                    <c:when test="${not empty errorProyecto}">
                        <c:set var="errorAccion" value="No fue posible validar el proyecto. Verifique la conexión a la base de datos." />
                    </c:when>
                    <c:when test="${empty resProyecto or resProyecto.rowCount == 0}">
                        <c:set var="errorAccion" value="Solo se puede programar la sustentación de proyectos que estén en la Fase 6." />
                    </c:when>
                </c:choose>
            </c:if>

            <%-- ---------- Guardar ---------- --%>
            <c:if test="${empty errorAccion}">
                <c:catch var="errorGuardado">

                    <%-- ¿El proyecto ya tenía sustentación? Se reprograma. --%>
                    <sql:query var="resExiste" dataSource="${db}">
                        SELECT t.*
                          FROM (
                              SELECT COUNT(*) AS programadas
                                FROM SUSTENTACIONES s
                               WHERE s.id_proyecto = ?
                          ) t
                        <sql:param value="${param.id_proyecto}" />
                    </sql:query>

                    <c:choose>
                        <c:when test="${resExiste.rows[0].programadas gt 0}">
                            <sql:update var="resSustentacion" dataSource="${db}">
                                UPDATE SUSTENTACIONES
                                   SET lugar_salon = ?,
                                       fecha_hora_programada = ?
                                 WHERE id_proyecto = ?
                                <sql:param value="${lugar}" />
                                <sql:param value="${fechaHora}" />
                                <sql:param value="${param.id_proyecto}" />
                            </sql:update>
                        </c:when>
                        <c:otherwise>
                            <sql:update var="resSustentacion" dataSource="${db}">
                                INSERT INTO SUSTENTACIONES
                                       (id_proyecto, lugar_salon, fecha_hora_programada)
                                VALUES (?, ?, ?)
                                <sql:param value="${param.id_proyecto}" />
                                <sql:param value="${lugar}" />
                                <sql:param value="${fechaHora}" />
                            </sql:update>
                        </c:otherwise>
                    </c:choose>

                    <%-- El proyecto queda APROBADO al programarse la sustentación --%>
                    <sql:update var="resProyectoAprobado" dataSource="${db}">
                        UPDATE PROYECTOS_GRADO
                           SET estado = 'APROBADO'
                         WHERE id_proyecto = ?
                        <sql:param value="${param.id_proyecto}" />
                    </sql:update>

                </c:catch>

                <c:choose>
                    <c:when test="${empty errorGuardado}">
                        <c:set var="okAccion" value="${true}" />
                    </c:when>
                    <%-- El error más probable aquí es una fecha mal formada --%>
                    <c:otherwise>
                        <c:set var="errorAccion" value="No fue posible guardar la sustentación. Revise la fecha y la hora indicadas." />
                    </c:otherwise>
                </c:choose>
            </c:if>

        </c:when>

        <c:otherwise>
            <c:set var="errorAccion" value="Acción no reconocida." />
        </c:otherwise>

    </c:choose>

    <c:choose>
        <c:when test="${okAccion}">
            <c:redirect url="programar_sustentacion.jsp">
                <c:param name="msg" value="Sustentación programada. El proyecto quedó en estado APROBADO." />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:redirect url="programar_sustentacion.jsp">
                <c:param name="error" value="${errorAccion}" />
            </c:redirect>
        </c:otherwise>
    </c:choose>

</c:if>

<c:if test="${empty param.accion}">

    <%-- =========================================================
         3) Proyectos en Fase 6
         ========================================================= --%>
    <c:catch var="errorListado">
        <sql:query var="resFase6" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT g.id_proyecto,
                         g.titulo,
                         g.fase_actual,
                         g.estado,
                         f.nombre_fase AS nombre_fase,
                         (SELECT CONCAT(est.nombres, ' ', est.apellidos)
                            FROM INTEGRANTES_PROYECTO i
                                 INNER JOIN USUARIOS est ON est.id_usuario = i.id_estudiante
                           WHERE i.id_proyecto = g.id_proyecto
                             AND i.es_lider = 1
                           LIMIT 1) AS estudiante,
                         (SELECT ep.codigo_estudiantil
                            FROM INTEGRANTES_PROYECTO i
                                 INNER JOIN ESTUDIANTES_PERFIL ep ON ep.id_estudiante = i.id_estudiante
                           WHERE i.id_proyecto = g.id_proyecto
                             AND i.es_lider = 1
                           LIMIT 1) AS codigo_estudiante,
                         (SELECT CONCAT(ud.nombres, ' ', ud.apellidos)
                            FROM ASIGNACIONES_DOCENTES a
                                 INNER JOIN USUARIOS ud ON ud.id_usuario = a.id_docente
                           WHERE a.id_proyecto = g.id_proyecto
                             AND a.subrol = 'DIRECTOR'
                           LIMIT 1) AS director,
                         (SELECT CONCAT(ue.nombres, ' ', ue.apellidos)
                            FROM ASIGNACIONES_DOCENTES a
                                 INNER JOIN USUARIOS ue ON ue.id_usuario = a.id_docente
                           WHERE a.id_proyecto = g.id_proyecto
                             AND a.subrol = 'EVALUADOR'
                           LIMIT 1) AS evaluador,
                         s.id_sustentacion       AS id_sustentacion,
                         s.lugar_salon           AS lugar_salon,
                         DATE_FORMAT(s.fecha_hora_programada, '%d/%m/%Y %H:%i') AS fecha_texto,
                         DATE_FORMAT(s.fecha_hora_programada, '%Y-%m-%dT%H:%i') AS fecha_input
                    FROM PROYECTOS_GRADO g
                         LEFT JOIN FASES_CICLO f ON f.numero_fase = g.fase_actual
                         LEFT JOIN SUSTENTACIONES s
                                ON s.id_sustentacion = (SELECT MAX(s2.id_sustentacion)
                                                          FROM SUSTENTACIONES s2
                                                         WHERE s2.id_proyecto = g.id_proyecto)
                   WHERE g.fase_actual = 6
              ) t
             ORDER BY t.fecha_input IS NULL, t.titulo
        </sql:query>
    </c:catch>

    <c:set var="pageTitle" value="Programar sustentación - UTS" />
    <%@ include file="/WEB-INF/jspf/header.jspf" %>

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

    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
        <div>
            <h1 class="h4 mb-1">
                <i class="bi bi-mic-fill text-success me-2"></i>
                Programación de sustentaciones
            </h1>
        </div>
        <a href="dashboard.jsp" class="btn btn-outline-secondary btn-sm">
            <i class="bi bi-speedometer2 me-1"></i>Volver al panel
        </a>
    </div>

    <c:choose>

        <c:when test="${not empty errorListado}">
            <div class="alert alert-warning d-flex align-items-start" role="alert">
                <i class="bi bi-plug-fill me-2 mt-1"></i>
                <div>
                    <strong>No fue posible consultar los proyectos de la Fase 6.</strong><br />
                    <span class="small">Verifique el servicio de base de datos e intente de nuevo.</span>
                </div>
            </div>
        </c:when>

        <c:when test="${empty resFase6 or resFase6.rowCount == 0}">
            <div class="card shadow-sm border-0">
                <div class="card-body text-center py-5">
                    <i class="bi bi-mic-mute text-warning display-4"></i>
                    <h2 class="h5 mt-3 mb-1">No hay proyectos en la Fase 6</h2>
                </div>
            </div>
        </c:when>

        <c:otherwise>

            <p class="text-muted small">
                <i class="bi bi-list-check me-1"></i>
                Proyectos en Fase 6: <strong><c:out value="${resFase6.rowCount}" /></strong>
            </p>

            <div class="row row-cols-1 g-4">
                <c:forEach var="p" items="${resFase6.rows}">
                    <div class="col">
                        <div class="card shadow-sm border-0">

                            <div class="card-header bg-white d-flex flex-wrap justify-content-between align-items-start gap-2">
                                <h2 class="h6 mb-0">
                                    <i class="bi bi-journal-check text-success me-2"></i>
                                    <c:out value="${p.titulo}" />
                                </h2>
                                <div class="d-flex gap-1 flex-wrap">
                                    <span class="badge bg-secondary">FASE 6</span>
                                    <c:choose>
                                        <c:when test="${p.estado eq 'APROBADO'}">
                                            <span class="badge bg-success">APROBADO</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-primary">
                                                <c:out value="${p.estado}" />
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                    <c:if test="${not empty p.id_sustentacion}">
                                        <span class="badge bg-info text-dark">
                                            <i class="bi bi-calendar-check me-1"></i>Programada
                                        </span>
                                    </c:if>
                                </div>
                            </div>

                            <div class="card-body">

                                <div class="row g-3 small mb-3">
                                    <div class="col-12 col-md-4">
                                        <span class="text-muted d-block">Estudiante líder</span>
                                        <strong><c:out value="${empty p.estudiante ? 'Sin líder registrado' : p.estudiante}" /></strong>
                                        <c:if test="${not empty p.codigo_estudiante}">
                                            <span class="text-muted d-block">
                                                Código: <c:out value="${p.codigo_estudiante}" />
                                            </span>
                                        </c:if>
                                    </div>
                                    <div class="col-12 col-md-4">
                                        <span class="text-muted d-block">Director</span>
                                        <strong><c:out value="${empty p.director ? 'Sin asignar' : p.director}" /></strong>
                                    </div>
                                    <div class="col-12 col-md-4">
                                        <span class="text-muted d-block">
                                            Evaluador
                                            <span class="badge bg-light text-dark">RF-11</span>
                                        </span>
                                        <strong><c:out value="${empty p.evaluador ? 'Sin asignar' : p.evaluador}" /></strong>
                                        <span class="text-muted d-block">Visible en Fase 6</span>
                                    </div>
                                </div>

                                <%-- -------- Sustentación ya programada -------- --%>
                                <c:if test="${not empty p.id_sustentacion}">
                                    <div class="alert alert-success small d-flex flex-wrap gap-3 mb-3" role="alert">
                                        <span>
                                            <i class="bi bi-geo-alt-fill me-1"></i>
                                            <strong><c:out value="${p.lugar_salon}" /></strong>
                                        </span>
                                        <span>
                                            <i class="bi bi-calendar-event me-1"></i>
                                            <c:out value="${p.fecha_texto}" />
                                        </span>
                                    </div>
                                </c:if>

                                <%-- -------- Formulario de programación -------- --%>
                                <form action="programar_sustentacion.jsp" method="post" accept-charset="UTF-8">
                                    <input type="hidden" name="accion" value="programar" />
                                    <input type="hidden" name="id_proyecto" value="${p.id_proyecto}" />

                                    <div class="row g-2 align-items-end">
                                        <div class="col-12 col-lg-5">
                                            <label class="form-label small fw-semibold"
                                                   for="lugar_${p.id_proyecto}">
                                                Salón / auditorio <span class="text-danger">*</span>
                                            </label>
                                            <input type="text" class="form-control form-control-sm"
                                                   id="lugar_${p.id_proyecto}" name="lugar_salon"
                                                   maxlength="100" required
                                                   value="${fn:escapeXml(empty p.lugar_salon ? '' : p.lugar_salon)}"
                                                   placeholder="Auditorio A - Edificio B UTS" />
                                        </div>
                                        <div class="col-12 col-lg-4">
                                            <label class="form-label small fw-semibold"
                                                   for="fecha_${p.id_proyecto}">
                                                Fecha y hora <span class="text-danger">*</span>
                                            </label>
                                            <input type="datetime-local" class="form-control form-control-sm"
                                                   id="fecha_${p.id_proyecto}" name="fecha_hora" required
                                                   value="${p.fecha_input}" />
                                        </div>
                                        <div class="col-12 col-lg-3">
                                            <button type="submit" class="btn btn-success btn-sm w-100">
                                                <c:choose>
                                                    <c:when test="${not empty p.id_sustentacion}">
                                                        <i class="bi bi-arrow-repeat me-1"></i>Reprogramar
                                                    </c:when>
                                                    <c:otherwise>
                                                        <i class="bi bi-calendar-plus me-1"></i>Programar
                                                    </c:otherwise>
                                                </c:choose>
                                            </button>
                                        </div>
                                    </div>
                                </form>

                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>

        </c:otherwise>

    </c:choose>

    <%@ include file="/WEB-INF/jspf/footer.jspf" %>

</c:if>
