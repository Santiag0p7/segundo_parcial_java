<%--
    =====================================================================
    fase1_registro.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 5 (Módulo 3, Fase 1)
    ---------------------------------------------------------------------
    Formulario único para iniciar la Fase 1 del trabajo de grado. Sirve en
    los dos casos:

      * Llega desde el banco con ${param.id_propuesta}  -> RF-07
        (se precarga el título y la descripción de la propuesta).
      * Llega sin id_propuesta                          -> RF-09
        (el estudiante escribe su idea propia).

    Campos: titulo, descripcion (obligatoria solo para idea propia),
    codigo_companero (opcional, dupla), soporte_pago (RF-08) e id_propuesta
    oculto cuando viene del banco.

    El envío va por POST a fase1_procesar.jsp.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) Control de acceso
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para registrar su proyecto de grado." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />

<c:if test="${u.rol ne 'ESTUDIANTE'}">
    <c:redirect url="banco_ideas.jsp">
        <c:param name="error" value="Solo los estudiantes pueden iniciar la Fase 1 de un proyecto de grado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     2) Si ya tiene proyecto, no se repite la Fase 1
     ========================================================= --%>
<c:catch var="errorProyecto">
    <sql:query var="resProyectoPrevio" dataSource="${db}">
        SELECT t.*
          FROM (
              SELECT i.id_proyecto
                FROM INTEGRANTES_PROYECTO i
               WHERE i.id_estudiante = ?
               LIMIT 1
          ) t
        <sql:param value="${u.id_usuario}" />
    </sql:query>
</c:catch>

<c:if test="${empty errorProyecto and not empty resProyectoPrevio and resProyectoPrevio.rowCount gt 0}">
    <c:redirect url="mi_proyecto.jsp">
        <c:param name="error" value="Usted ya tiene un proyecto de grado registrado." />
    </c:redirect>
</c:if>

<%-- =========================================================
     3) ¿Viene de una propuesta del banco? Se valida que siga
        DISPONIBLE y que sea de su nivel (RF-05 + RF-07)
     ========================================================= --%>
<c:set var="origenBanco" value="${false}" />

<c:if test="${not empty param.id_propuesta}">
    <c:catch var="errorPropuesta">
        <sql:query var="resPropuestaSel" dataSource="${db}">
            SELECT t.*
              FROM (
                  SELECT p.id_propuesta,
                         p.titulo,
                         p.descripcion,
                         p.nivel_destinatario,
                         p.estado
                    FROM PROPUESTAS_PROYECTO p
                   WHERE p.id_propuesta = ?
                     AND p.estado = 'DISPONIBLE'
                     AND p.nivel_destinatario = ?
              ) t
            <sql:param value="${param.id_propuesta}" />
            <sql:param value="${u.nivelFormacion}" />
        </sql:query>
    </c:catch>

    <c:if test="${empty errorPropuesta and not empty resPropuestaSel and resPropuestaSel.rowCount gt 0}">
        <c:set var="propuestaSel" value="${resPropuestaSel.rows[0]}" />
        <c:set var="origenBanco" value="${true}" />
    </c:if>
</c:if>

<c:if test="${not empty param.id_propuesta and not origenBanco}">
    <c:redirect url="banco_ideas.jsp">
        <c:param name="error" value="La propuesta seleccionada no está disponible o no corresponde a su nivel de formación." />
    </c:redirect>
</c:if>

<%-- =========================================================
     4) Valores iniciales del formulario
        (param.* primero, para no perder lo escrito si hubo error)
     ========================================================= --%>
<c:set var="valorTitulo" value="${empty param.titulo ? (origenBanco ? propuestaSel.titulo : '') : param.titulo}" />
<c:set var="valorDescripcion" value="${param.descripcion}" />
<c:set var="valorCompanero" value="${param.codigo_companero}" />
<c:set var="valorSoporte" value="${param.soporte_pago}" />

<c:set var="pageTitle" value="Iniciar Fase 1 - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb small">
        <li class="breadcrumb-item"><a href="dashboard.jsp">Panel</a></li>
        <li class="breadcrumb-item"><a href="mi_proyecto.jsp">Mi proyecto</a></li>
        <li class="breadcrumb-item active" aria-current="page">Iniciar Fase 1</li>
    </ol>
</nav>

<c:if test="${not empty param.error}">
    <div class="alert alert-danger d-flex align-items-start" role="alert">
        <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
        <div><c:out value="${param.error}" /></div>
    </div>
</c:if>

<div class="row justify-content-center">
    <div class="col-12 col-lg-9">

        <div class="mb-3">
            <h1 class="h4 mb-1">
                <i class="bi bi-clipboard2-plus-fill text-success me-2"></i>
                Iniciar Fase 1 del trabajo de grado
            </h1>
        </div>

        <div class="card shadow border-0">
            <div class="card-header bg-success text-white">
                <i class="bi bi-pencil-square me-2"></i>
                <c:out value="${origenBanco ? 'Confirmar propuesta del banco e inscribir el proyecto' : 'Registrar idea propia e inscribir el proyecto'}" />
            </div>

            <div class="card-body p-4">

                <%-- -------- Origen de la idea -------- --%>
                <c:choose>

                    <%-- Viene del banco de propuestas --%>
                    <c:when test="${origenBanco}">
                        <div class="card bg-light border-0 mb-4">
                            <div class="card-body">
                                <h2 class="h6 mb-2">
                                    <i class="bi bi-lightbulb text-warning me-1"></i>
                                    <c:out value="${propuestaSel.titulo}" />
                                </h2>
                                <div class="small" style="white-space: pre-wrap;"><c:out value="${propuestaSel.descripcion}" /></div>
                            </div>
                        </div>
                    </c:when>

                    <%-- Idea propia (RF-09) --%>
                    <c:otherwise>
                    </c:otherwise>

                </c:choose>

                <form action="fase1_procesar.jsp" method="post" accept-charset="UTF-8">

                    <%-- id_propuesta: solo si viene del banco --%>
                    <c:if test="${origenBanco}">
                        <input
                            type="hidden"
                            name="id_propuesta"
                            value="${fn:escapeXml(propuestaSel.id_propuesta)}" />
                    </c:if>

                    <%-- Título del proyecto --%>
                    <div class="mb-3">
                        <label for="titulo" class="form-label fw-semibold">
                            Título del proyecto <span class="text-danger">*</span>
                        </label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-type-h1"></i></span>
                            <input
                                type="text"
                                class="form-control"
                                id="titulo"
                                name="titulo"
                                maxlength="255"
                                value="${fn:escapeXml(valorTitulo)}"
                                placeholder="Título con el que se registrará su trabajo de grado"
                                required
                                autofocus />
                        </div>
                        <div class="form-text">
                            <c:choose>
                                <c:when test="${origenBanco}">
                                    Viene precargado del banco de ideas; puede ajustarlo.
                                </c:when>
                                <c:otherwise>
                                    Máximo 255 caracteres. El título se guarda en el proyecto de grado.
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <%-- Descripción: obligatoria solo para idea propia --%>
                    <c:if test="${not origenBanco}">
                        <div class="mb-3">
                            <label for="descripcion" class="form-label fw-semibold">
                                Descripción / Idea <span class="text-danger">*</span>
                            </label>
                            <textarea
                                class="form-control"
                                id="descripcion"
                                name="descripcion"
                                rows="6"
                                placeholder="Describa el problema a resolver, el alcance y los objetivos de su idea."
                                required><c:out value="${valorDescripcion}" /></textarea>
                        </div>
                    </c:if>

                    <%-- Dupla opcional --%>
                    <div class="mb-3">
                        <label for="codigo_companero" class="form-label fw-semibold">
                            Código del Integrante 2 <span class="text-muted fw-normal">(opcional)</span>
                        </label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-people-fill"></i></span>
                            <input
                                type="text"
                                class="form-control"
                                id="codigo_companero"
                                name="codigo_companero"
                                maxlength="20"
                                value="${fn:escapeXml(valorCompanero)}"
                                placeholder="Ej.: ST-1001" />
                        </div>
                    </div>

                    <%-- RF-08: soporte de pago (ruta PDF simulada) --%>
                    <div class="mb-4">
                        <label for="soporte_pago" class="form-label fw-semibold">
                            Archivo PDF Soporte de Pago <span class="text-danger">*</span>
                        </label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-file-earmark-pdf-fill text-danger"></i></span>
                            <input
                                type="text"
                                class="form-control"
                                id="soporte_pago"
                                name="soporte_pago"
                                maxlength="255"
                                value="${fn:escapeXml(valorSoporte)}"
                                placeholder="comprobantes/pago-derechos-grado-2026-001.pdf"
                                required />
                        </div>
                    </div>

                    <div class="d-flex flex-column flex-sm-row gap-2">
                        <button type="submit" class="btn btn-success btn-lg flex-grow-1">
                            <i class="bi bi-check2-circle me-2"></i>Registrar proyecto e iniciar Fase 1
                        </button>
                        <a href="mi_proyecto.jsp" class="btn btn-outline-secondary btn-lg">
                            <i class="bi bi-x-circle me-1"></i>Cancelar
                        </a>
                    </div>

                </form>

            </div>
        </div>

    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
