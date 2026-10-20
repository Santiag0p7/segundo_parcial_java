<%--
    =====================================================================
    crear_propuesta.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado  -  Paso 4 (Módulo 2)
    ---------------------------------------------------------------------
    RF-04: formulario con el que DOCENTE y COMITE registran una propuesta
           de proyecto de grado en el banco de ideas.

    Vista protegida: exige sesión y uno de los roles autorizados
    (DOCENTE, COMITE o ADMINISTRADOR). Un estudiante no puede publicar
    propuestas, así que se le devuelve al banco con un mensaje.

    El formulario envía titulo, descripcion y nivel_destinatario por POST
    a guardar_propuesta.jsp, que es quien escribe en la base de datos.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- =========================================================
     1) RNF-01: control de acceso + RBAC del módulo
     ========================================================= --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="login.jsp">
        <c:param name="error" value="Debe iniciar sesión para registrar propuestas." />
    </c:redirect>
</c:if>

<c:set var="u" value="${sessionScope.usuario}" />
<c:set var="puedeCrear" value="${u.rol eq 'DOCENTE' or u.rol eq 'COMITE' or u.rol eq 'ADMINISTRADOR'}" />

<c:if test="${not puedeCrear}">
    <c:redirect url="banco_ideas.jsp">
        <c:param name="error" value="Solo los docentes y el comité pueden registrar propuestas de proyecto." />
    </c:redirect>
</c:if>

<c:set var="pageTitle" value="Registrar propuesta - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="row justify-content-center">
    <div class="col-12 col-lg-8">

        <%-- =========================================================
             2) Migas de pan
             ========================================================= --%>
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item"><a href="dashboard.jsp">Panel</a></li>
                <li class="breadcrumb-item"><a href="banco_ideas.jsp">Banco de propuestas</a></li>
                <li class="breadcrumb-item active" aria-current="page">Nueva propuesta</li>
            </ol>
        </nav>

        <%-- =========================================================
             3) Mensajes devueltos por guardar_propuesta.jsp
             ========================================================= --%>
        <c:if test="${not empty param.error}">
            <div class="alert alert-danger d-flex align-items-start" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
                <div><c:out value="${param.error}" /></div>
            </div>
        </c:if>

        <div class="card shadow border-0">
            <div class="card-header bg-success text-white">
                <i class="bi bi-plus-square-fill me-2"></i>Registrar propuesta de proyecto de grado
            </div>

            <div class="card-body p-4">

                <div class="alert alert-success d-flex align-items-start small" role="alert">
                    <i class="bi bi-info-circle-fill me-2 mt-1"></i>
                    <div>
                        <strong>RF-04.</strong> La propuesta quedará publicada en el banco de
                        ideas con estado <span class="badge bg-success">DISPONIBLE</span>,
                        visible únicamente para los estudiantes del nivel destinatario que
                        usted seleccione.
                    </div>
                </div>

                <form action="guardar_propuesta.jsp" method="post" accept-charset="UTF-8">

                    <%-- Autor de la propuesta (sale de la sesión, no del formulario) --%>
                    <div class="mb-4">
                        <label class="form-label fw-semibold">Autor de la propuesta</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-person-badge-fill"></i></span>
                            <input
                                type="text"
                                class="form-control"
                                value="${fn:escapeXml(u.nombres)} ${fn:escapeXml(u.apellidos)} - ${fn:escapeXml(u.rol)}"
                                disabled />
                        </div>
                    </div>

                    <%-- Título --%>
                    <div class="mb-3">
                        <label for="titulo" class="form-label fw-semibold">
                            Título de la propuesta <span class="text-danger">*</span>
                        </label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-type-h1"></i></span>
                            <input
                                type="text"
                                class="form-control"
                                id="titulo"
                                name="titulo"
                                maxlength="255"
                                value="${fn:escapeXml(param.titulo)}"
                                placeholder="Ej.: Sistema de gestión documental para el área de posgrados"
                                required
                                autofocus />
                        </div>
                    </div>

                    <%-- Descripción y objetivos --%>
                    <div class="mb-3">
                        <label for="descripcion" class="form-label fw-semibold">
                            Descripción y objetivos <span class="text-danger">*</span>
                        </label>
                        <textarea
                            class="form-control"
                            id="descripcion"
                            name="descripcion"
                            rows="7"
                            placeholder="Describa el problema a resolver, el alcance y los objetivos del proyecto."
                            required><c:out value="${param.descripcion}" /></textarea>
                    </div>

                    <%-- Nivel destinatario --%>
                    <div class="mb-4">
                        <label for="nivel_destinatario" class="form-label fw-semibold">
                            Nivel destinatario <span class="text-danger">*</span>
                        </label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-mortarboard-fill"></i></span>
                            <select class="form-select" id="nivel_destinatario" name="nivel_destinatario" required>
                                <option value="">-- Seleccione el nivel --</option>
                                <option value="TECNOLOGIA" ${param.nivel_destinatario eq 'TECNOLOGIA' ? 'selected' : ''}>
                                    TECNOLOGÍA - ciclo tecnológico
                                </option>
                                <option value="INGENIERIA" ${param.nivel_destinatario eq 'INGENIERIA' ? 'selected' : ''}>
                                    INGENIERÍA - ciclo profesional
                                </option>
                            </select>
                        </div>
                    </div>

                    <div class="d-flex flex-column flex-sm-row gap-2">
                        <button type="submit" class="btn btn-success btn-lg flex-grow-1">
                            <i class="bi bi-save-fill me-2"></i>Publicar propuesta
                        </button>
                        <a href="banco_ideas.jsp" class="btn btn-outline-secondary btn-lg">
                            <i class="bi bi-x-circle me-1"></i>Cancelar
                        </a>
                    </div>

                </form>

            </div>
        </div>

    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
