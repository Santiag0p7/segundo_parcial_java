<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- Con sesión activa no se vuelve a pedir credenciales --%>
<c:if test="${not empty sessionScope.usuario}">
    <c:redirect url="dashboard.jsp" />
</c:if>

<c:set var="pageTitle" value="Iniciar sesión - UTS" />
<c:set var="perfiles" value="${fn:split('ESTUDIANTE|Estudiante|bi-mortarboard-fill|Acceso para Estudiantes UTS;DOCENTE|Docente|bi-person-workspace|Acceso para Docentes UTS;COMITE|Comité / Admin|bi-shield-lock-fill|Acceso para Comité y Administración UTS', ';')}" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="row justify-content-center py-3 py-md-4">
    <div class="col-12 col-sm-10 col-md-8 col-lg-5 col-xl-4">

        <div class="text-center mb-4">
            <img src="assets/img/utslogo.png" alt="Unidades Tecnológicas de Santander"
                 class="mb-3" style="height: 88px; width: auto;" />
            <h1 class="h4 mb-1">Trabajos de Grado</h1>
            <p class="text-muted small mb-0">Unidades Tecnológicas de Santander</p>
        </div>

        <div class="card border-0 shadow p-3 p-md-4">
            <div class="card-body">

                <c:if test="${not empty param.error}">
                    <div class="alert alert-danger d-flex align-items-start small" role="alert">
                        <i class="bi bi-exclamation-triangle-fill me-2 mt-1"></i>
                        <div><c:out value="${param.error}" /></div>
                    </div>
                </c:if>

                <c:if test="${not empty param.msg}">
                    <div class="alert alert-success d-flex align-items-start small" role="alert">
                        <i class="bi bi-check-circle-fill me-2 mt-1"></i>
                        <div><c:out value="${param.msg}" /></div>
                    </div>
                </c:if>

                <ul class="nav nav-tabs nav-fill mb-4" role="tablist">
                    <c:forEach var="p" items="${perfiles}" varStatus="st">
                        <c:set var="c" value="${fn:split(p, '|')}" />
                        <li class="nav-item" role="presentation">
                            <button class="nav-link fw-semibold ${st.first ? 'active' : ''}"
                                    id="tab-${c[0]}" data-bs-toggle="tab" data-bs-target="#pane-${c[0]}"
                                    type="button" role="tab" aria-controls="pane-${c[0]}"
                                    aria-selected="${st.first ? 'true' : 'false'}">
                                <i class="bi ${c[2]} me-1"></i><c:out value="${c[1]}" />
                            </button>
                        </li>
                    </c:forEach>
                </ul>

                <div class="tab-content">
                    <c:forEach var="p" items="${perfiles}" varStatus="st">
                        <c:set var="c" value="${fn:split(p, '|')}" />
                        <div class="tab-pane fade ${st.first ? 'show active' : ''}"
                             id="pane-${c[0]}" role="tabpanel" aria-labelledby="tab-${c[0]}" tabindex="0">

                            <h2 class="h6 mb-3"><c:out value="${c[3]}" /></h2>

                            <form action="validar_login.jsp" method="post" accept-charset="UTF-8">
                                <input type="hidden" name="perfil" value="${c[0]}" />

                                <div class="mb-3">
                                    <label for="correo-${c[0]}" class="form-label small fw-semibold">Correo institucional</label>
                                    <input type="email" class="form-control form-control-lg rounded-3"
                                           id="correo-${c[0]}" name="correo"
                                           value="${fn:escapeXml(param.correo)}"
                                           placeholder="usuario@correo.uts.edu.co"
                                           autocomplete="username" required />
                                </div>

                                <div class="mb-4">
                                    <label for="contrasena-${c[0]}" class="form-label small fw-semibold">Contraseña</label>
                                    <input type="password" class="form-control form-control-lg rounded-3"
                                           id="contrasena-${c[0]}" name="contrasena"
                                           autocomplete="current-password" required />
                                </div>

                                <button type="submit" class="btn btn-success btn-lg w-100 rounded-3">
                                    Ingresar
                                </button>
                            </form>
                        </div>
                    </c:forEach>
                </div>

            </div>
        </div>

    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
