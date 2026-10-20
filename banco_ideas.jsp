<%--
    =====================================================================
    banco_ideas.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 4 (Módulo 2)
    ---------------------------------------------------------------------
    Banco de propuestas de proyecto de grado.

      RF-04: los docentes registran propuestas en crear_propuesta.jsp; desde
             aquí disponen del botón destacado "Nueva Propuesta".
      RF-05: el banco se filtra automáticamente por el nivel de formación
             del estudiante autenticado. DOCENTE, COMITE y ADMINISTRADOR
             ven todas las propuestas.
      RF-06: cada propuesta muestra su estado (DISPONIBLE / SELECCIONADA).
      RF-07: un estudiante puede seleccionar una propuesta DISPONIBLE de su
             nivel; el formulario envía id_propuesta por POST a
             seleccionar_propuesta.jsp.

    DOS NOTAS IMPORTANTES:

    1) CAMPO DE SESIÓN. El contrato de sesión del sistema (AGENTS.md §5.2 y
       validar_login.jsp) guarda el nivel de formación como
       "nivelFormacion" (camelCase). EL distingue mayúsculas, así que aquí
       se usa ${sessionScope.usuario.nivelFormacion} y NO
       ${sessionScope.usuario.nivel_formacion}.

    2) CLAVES DEL <sql:query>. Las claves del row son los NOMBRES FÍSICOS de
       las columnas, no los alias (trampa 5 del proyecto). Por eso cada
       consulta va envuelta en una tabla derivada: así los alias
       nombres_creador, rol_creador, etc. sí existen como claves del row.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) RNF-01: control de acceso (vista protegida)
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para consultar el banco de propuestas." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />
<c:set var="esEstudiante" value="${u.rol eq 'ESTUDIANTE'}" />
<c:set var="puedeCrear" value="${u.rol eq 'DOCENTE' or u.rol eq 'COMITE' or u.rol eq 'ADMINISTRADOR'}" />

<%-- =========================================================
     2) RF-07: ¿el estudiante ya tiene proyecto de grado?
        (INTEGRANTES_PROYECTO tiene UNIQUE(id_estudiante), así que un
         estudiante solo puede vincularse a un proyecto)
     ========================================================= --%>
<c:if test="${esEstudiante}">
    <c:catch var="errorMiProyecto">
        <sql:query var="resMiProyecto" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT g.id_proyecto, g.titulo, g.fase_actual, g.estado
                    FROM INTEGRANTES_PROYECTO i
                         INNER JOIN PROYECTOS_GRADO g ON g.id_proyecto = i.id_proyecto
                   WHERE i.id_estudiante = ?
                   LIMIT 1
              ) t
            <sql:param value="${u.id_usuario}" />
        </sql:query>
    </c:catch>
</c:if>

<%-- =========================================================
     3) RF-05 / RF-06: consulta del banco de propuestas
        Estudiante  -> solo su nivel de formación
        Otros roles -> todo el banco, de la más reciente a la más antigua
     ========================================================= --%>
<c:set var="errorBanco" value="" />
<c:catch var="errorBanco">
    <c:choose>

        <%-- ---------- 3.a) Estudiante: filtrado por nivel ---------- --%>
        <c:when test="${esEstudiante}">
            <sql:query var="resPropuestas" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT p.id_propuesta,
                             p.titulo,
                             p.descripcion,
                             p.nivel_destinatario,
                             p.estado,
                             p.fecha_creacion,
                             u.nombres      AS nombres_creador,
                             u.apellidos    AS apellidos_creador,
                             r.nombre       AS rol_creador,
                             dp.especialidad AS especialidad_creador
                        FROM PROPUESTAS_PROYECTO p
                             INNER JOIN USUARIOS         u  ON u.id_usuario  = p.id_creador
                             INNER JOIN ROLES            r  ON r.id_rol      = u.id_rol
                             LEFT  JOIN DOCENTES_PERFIL  dp ON dp.id_docente = u.id_usuario
                       WHERE p.nivel_destinatario = ?
                  ) t
                 ORDER BY t.fecha_creacion DESC, t.id_propuesta DESC
                <sql:param value="${u.nivelFormacion}" />
            </sql:query>
        </c:when>

        <%-- ---------- 3.b) Docente / Comité / Admin: banco completo ---------- --%>
        <c:otherwise>
            <sql:query var="resPropuestas" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT p.id_propuesta,
                             p.titulo,
                             p.descripcion,
                             p.nivel_destinatario,
                             p.estado,
                             p.fecha_creacion,
                             u.nombres      AS nombres_creador,
                             u.apellidos    AS apellidos_creador,
                             r.nombre       AS rol_creador,
                             dp.especialidad AS especialidad_creador
                        FROM PROPUESTAS_PROYECTO p
                             INNER JOIN USUARIOS         u  ON u.id_usuario  = p.id_creador
                             INNER JOIN ROLES            r  ON r.id_rol      = u.id_rol
                             LEFT  JOIN DOCENTES_PERFIL  dp ON dp.id_docente = u.id_usuario
                  ) t
                 ORDER BY t.fecha_creacion DESC, t.id_propuesta DESC
            </sql:query>
        </c:otherwise>

    </c:choose>
</c:catch>

<c:set var="pageTitle" value="Banco de propuestas - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<%-- =========================================================
     4) Mensajes devueltos por las páginas de proceso
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

<%-- =========================================================
     5) Encabezado del módulo
     ========================================================= --%>
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h1 class="h4 mb-1">
            <i class="bi bi-lightbulb-fill text-warning me-2"></i>Banco de Propuestas de Grado
        </h1>
        <p class="text-muted small mb-0">
            <c:choose>
                <c:when test="${esEstudiante}">
                    Propuestas habilitadas para su nivel de formación:
                    <c:choose>
                        <c:when test="${u.nivelFormacion eq 'INGENIERIA'}">
                            <span class="badge bg-primary">INGENIERÍA</span>
                        </c:when>
                        <c:when test="${u.nivelFormacion eq 'TECNOLOGIA'}">
                            <span class="badge bg-info text-dark">TECNOLOGÍA</span>
                        </c:when>
                        <c:otherwise>
                            <span class="badge bg-secondary">SIN NIVEL ASIGNADO</span>
                        </c:otherwise>
                    </c:choose>
                </c:when>
                <c:otherwise>
                    Vista completa del banco (rol <c:out value="${u.rol}" />): se listan
                    las propuestas de todos los niveles.
                </c:otherwise>
            </c:choose>
        </p>
    </div>

    <%-- RF-04: acceso destacado al registro de propuestas --%>
    <div>
        <c:if test="${puedeCrear}">
            <a href="crear_propuesta.jsp" class="btn btn-success">
                <i class="bi bi-plus-square-fill me-2"></i>Nueva Propuesta
            </a>
        </c:if>
        <a href="dashboard.jsp" class="btn btn-outline-secondary">
            <i class="bi bi-speedometer2 me-2"></i>Volver al panel
        </a>
    </div>
</div>

<%-- =========================================================
     6) RF-07: aviso si el estudiante ya inició su proceso
     ========================================================= --%>
<%-- OJO: <sql:query var> deja SIEMPRE un objeto Result no nulo (aunque no
     traiga filas), así que "not empty resMiProyecto" sería siempre verdadero.
     La comprobación correcta es rowCount gt 0. --%>
<c:if test="${esEstudiante and not empty resMiProyecto and resMiProyecto.rowCount gt 0}">
    <div class="alert alert-info d-flex align-items-start" role="alert">
        <i class="bi bi-info-circle-fill me-2 mt-1"></i>
        <div>
            <strong>Ya inició su trabajo de grado.</strong>

        </div>
    </div>
</c:if>

<%-- =========================================================
     7) Resultado de la consulta
     ========================================================= --%>
<c:choose>

    <%-- ---------- 7.a) La base de datos no respondió ---------- --%>
    <c:when test="${not empty errorBanco}">
        <div class="alert alert-warning d-flex align-items-start" role="alert">
            <i class="bi bi-plug-fill me-2 mt-1"></i>
            <div>
                <strong>No fue posible consultar el banco de propuestas.</strong><br />
                <span class="small">
                    Verifique que el servicio de base de datos esté en ejecución e
                    intente de nuevo.
                </span>
            </div>
        </div>
    </c:when>

    <%-- ---------- 7.b) No hay propuestas para mostrar ---------- --%>
    <c:when test="${empty resPropuestas or resPropuestas.rowCount == 0}">
        <div class="card shadow-sm border-0">
            <div class="card-body text-center py-5">
                <i class="bi bi-inboxes text-muted display-4"></i>
                <h2 class="h5 mt-3 mb-1">No hay propuestas disponibles</h2>
                <p class="text-muted small mb-0">
                    <c:choose>
                        <c:when test="${esEstudiante}">
                            Todavía no se han publicado propuestas para su nivel de
                            formación. Consulte de nuevo más adelante.
                        </c:when>
                        <c:otherwise>
                            El banco está vacío. Registre la primera propuesta con el
                            botón «Nueva Propuesta».
                        </c:otherwise>
                    </c:choose>
                </p>
            </div>
        </div>
    </c:when>

    <%-- ---------- 7.c) Listado de propuestas (RF-05 / RF-06) ---------- --%>
    <c:otherwise>

        <%-- Total de propuestas que el usuario puede seleccionar --%>
        <c:set var="totalDisponibles" value="${0}" />
        <c:forEach var="p" items="${resPropuestas.rows}">
            <c:if test="${p.estado eq 'DISPONIBLE'}">
                <c:set var="totalDisponibles" value="${totalDisponibles + 1}" />
            </c:if>
        </c:forEach>

        <p class="text-muted small">
            <i class="bi bi-list-check me-1"></i>
            Propuestas listadas: <strong><c:out value="${resPropuestas.rowCount}" /></strong>
            &nbsp;·&nbsp;
            Disponibles: <strong><c:out value="${totalDisponibles}" /></strong>
        </p>

        <div class="row row-cols-1 row-cols-lg-2 g-4">
            <c:forEach var="p" items="${resPropuestas.rows}">
                <div class="col">
                    <div class="card h-100 shadow-sm border-0">

                        <%-- Título + RF-06: indicador de estado --%>
                        <div class="card-header bg-white d-flex justify-content-between align-items-start gap-2">
                            <h2 class="h6 mb-0">
                                <i class="bi bi-lightbulb text-warning me-2"></i>
                                <c:out value="${p.titulo}" />
                            </h2>

                            <c:choose>
                                <c:when test="${p.estado eq 'DISPONIBLE'}">
                                    <span class="badge bg-success flex-shrink-0">
                                        <i class="bi bi-check-circle me-1"></i>DISPONIBLE
                                    </span>
                                </c:when>
                                <c:when test="${p.estado eq 'SELECCIONADA'}">
                                    <span class="badge bg-secondary flex-shrink-0">
                                        <i class="bi bi-lock-fill me-1"></i>SELECCIONADA
                                    </span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge bg-dark flex-shrink-0">
                                        <c:out value="${p.estado}" />
                                    </span>
                                </c:otherwise>
                            </c:choose>
                        </div>

                        <div class="card-body pb-2">
                            <%-- white-space pre-wrap: respeta los saltos de línea con que
                                 el docente escribió la descripción y los objetivos --%>
                            <div class="card-text small" style="white-space: pre-wrap;"><c:out value="${p.descripcion}" /></div>
                        </div>

                        <%-- Metadatos de la propuesta --%>
                        <ul class="list-group list-group-flush small">
                            <li class="list-group-item d-flex justify-content-between">
                                <span class="text-muted">
                                    <i class="bi bi-person-badge me-1"></i>Creador
                                </span>
                                <span class="text-end">
                                    <strong>
                                        <c:out value="${p.nombres_creador}" />
                                        <c:out value="${p.apellidos_creador}" />
                                    </strong>
                                    <c:if test="${not empty p.rol_creador}">
                                        <span class="text-muted">(<c:out value="${p.rol_creador}" />)</span>
                                    </c:if>
                                    <c:if test="${not empty p.especialidad_creador}">
                                        <br /><span class="text-muted">
                                            <c:out value="${p.especialidad_creador}" />
                                        </span>
                                    </c:if>
                                </span>
                            </li>

                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                <span class="text-muted">
                                    <i class="bi bi-mortarboard me-1"></i>Nivel destinatario
                                </span>
                                <span>
                                    <c:choose>
                                        <c:when test="${p.nivel_destinatario eq 'TECNOLOGIA'}">
                                            <span class="badge bg-info text-dark">TECNOLOGÍA</span>
                                        </c:when>
                                        <c:when test="${p.nivel_destinatario eq 'INGENIERIA'}">
                                            <span class="badge bg-primary">INGENIERÍA</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge bg-light text-dark">
                                                <c:out value="${p.nivel_destinatario}" />
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </span>
                            </li>

                            <li class="list-group-item d-flex justify-content-between">
                                <span class="text-muted">
                                    <i class="bi bi-calendar3 me-1"></i>Publicada
                                </span>
                                <span>
                                    <fmt:formatDate value="${p.fecha_creacion}" pattern="dd/MM/yyyy" />
                                </span>
                            </li>
                        </ul>

                        <%-- RF-07: selección de la idea por parte del estudiante --%>
                        <c:if test="${esEstudiante}">
                            <div class="card-footer bg-transparent border-0">
                                <c:choose>

                                    <c:when test="${p.estado ne 'DISPONIBLE'}">
                                        <button type="button" class="btn btn-outline-secondary btn-sm w-100" disabled>
                                            <i class="bi bi-lock me-1"></i>No disponible
                                        </button>
                                    </c:when>

                                    <c:when test="${not empty resMiProyecto and resMiProyecto.rowCount gt 0}">
                                        <button type="button" class="btn btn-outline-secondary btn-sm w-100" disabled>
                                            <i class="bi bi-check2-circle me-1"></i>Ya tiene proyecto en proceso
                                        </button>
                                    </c:when>

                                    <c:otherwise>
                                        <%--
                                            RF-07 -> Fase 1: la selección ya no crea el
                                            proyecto directamente. Lleva al formulario de
                                            Fase 1, donde además se registra el soporte de
                                            pago (RF-08) y la posible dupla.
                                        --%>
                                        <a href="fase1_registro.jsp?id_propuesta=${fn:escapeXml(p.id_propuesta)}"
                                           class="btn btn-success btn-sm w-100">
                                            <i class="bi bi-hand-index-thumb-fill me-1"></i>Seleccionar Idea
                                        </a>
                                    </c:otherwise>

                                </c:choose>
                            </div>
                        </c:if>

                    </div>
                </div>
            </c:forEach>
        </div>

    </c:otherwise>

</c:choose>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
