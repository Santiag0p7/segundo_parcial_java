<%--
    =====================================================================
    index.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Proyectos de Grado
    ---------------------------------------------------------------------
    Página de aterrizaje pública.

    Contenido deliberadamente mínimo:
      * Título central del sistema.
      * Botón "Iniciar sesión" en la esquina superior derecha.
      * Sin navbar, sin secciones informativas y sin footer.

    Si el visitante ya tiene sesión activa, se redirige al panel que
    corresponde a su rol. Esta vista es la única que no usa header.jspf /
    footer.jspf porque el requerimiento es una portada limpia.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- Con sesión activa no se muestra la portada: se va al panel. --%>
<c:if test="${not empty sessionScope.usuario}">
    <c:choose>
        <c:when test="${sessionScope.usuario.rol eq 'ADMINISTRADOR'}">
            <c:redirect url="dashboard_admin.jsp" />
        </c:when>
        <c:otherwise>
            <c:redirect url="dashboard.jsp" />
        </c:otherwise>
    </c:choose>
</c:if>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="author" content="Unidades Tecnológicas de Santander - UTS" />
    <meta name="description" content="Sistema de Gestión de Proyectos de Grado - UTS" />
    <title>Sistema de Gestión de Proyectos de Grado - UTS</title>

    <link rel="icon" type="image/png" href="${ctx}/assets/img/utslogo.png" />
    <link rel="apple-touch-icon" href="${ctx}/assets/img/utslogo.png" />

    <link
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        rel="stylesheet"
        integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH"
        crossorigin="anonymous" />
    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
        href="https://fonts.googleapis.com/css2?family=Archivo+Black&family=Inconsolata:wght@400;600;700&display=swap"
        rel="stylesheet" />

    <style>
        :root {
            --uts-blue: #00A3E0;
            --uts-deep-blue: #005A8C;
            --uts-green: #A4D233;
            --uts-dark: #2D2D2D;
        }

        html,
        body {
            min-height: 100%;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow-x: hidden;
            color: #fff;
            font-family: 'Inconsolata', monospace;
            background:
                radial-gradient(circle at 18% 18%, rgba(255, 255, 255, .18), transparent 34%),
                radial-gradient(circle at 84% 82%, rgba(164, 210, 51, .30), transparent 38%),
                linear-gradient(135deg, var(--uts-deep-blue) 0%, #008CC4 48%, #6F9E1E 100%);
        }

        /* Trama sutil, tomada del hero de la página institucional. */
        body::before {
            content: "";
            position: fixed;
            inset: 0;
            pointer-events: none;
            background-image:
                linear-gradient(rgba(255, 255, 255, .07) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255, 255, 255, .07) 1px, transparent 1px);
            background-size: 64px 64px;
            -webkit-mask-image: radial-gradient(circle at center, #000 0%, transparent 72%);
            mask-image: radial-gradient(circle at center, #000 0%, transparent 72%);
        }

        .landing-login {
            position: fixed;
            top: 1.5rem;
            right: 1.5rem;
            z-index: 10;
            display: inline-flex;
            align-items: center;
            gap: .6rem;
            padding: .75rem 1.35rem;
            border-radius: 999px;
            background: rgba(255, 255, 255, .96);
            color: var(--uts-dark);
            font-family: 'Inconsolata', 'Courier New', monospace;
            font-weight: 700;
            text-decoration: none;
            box-shadow: 0 10px 30px rgba(0, 0, 0, .18);
            transition: transform .2s ease, background-color .2s ease, color .2s ease;
        }

        .landing-login:hover,
        .landing-login:focus {
            background: #fff;
            color: var(--uts-deep-blue);
            transform: translateY(-2px);
        }

        .landing-login i {
            font-size: 1.1rem;
        }

        .landing-main {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 1100px;
            padding: 5rem 2rem;
            text-align: center;
        }

        .landing-title {
            margin: 0 auto;
            width: 100%;
            max-width: 1000px;
            font-family: 'Archivo Black', 'Arial Black', 'Helvetica Neue', Arial, sans-serif;
            font-weight: 900;
            font-size: clamp(2rem, 5.4vw, 4.8rem);
            line-height: 1.06;
            letter-spacing: -.02em;
            text-wrap: balance;
            overflow-wrap: break-word;
            text-shadow: 0 12px 40px rgba(0, 0, 0, .25);
        }

        @media (max-width: 576px) {
            .landing-login {
                top: 1rem;
                right: 1rem;
                max-width: calc(100vw - 2rem);
                padding: .6rem 1rem;
                font-size: .85rem;
                white-space: nowrap;
            }

            .landing-main {
                padding: 6.5rem 1rem 3rem;
            }

            .landing-title {
                font-size: clamp(1.5rem, 7.2vw, 2.4rem);
                line-height: 1.12;
            }
        }
    </style>
</head>

<body>

    <a class="landing-login" href="${ctx}/login.jsp" aria-label="Iniciar sesión">
        <i class="bi bi-box-arrow-in-right" aria-hidden="true"></i>
        <span>Iniciar sesión</span>
    </a>

    <main class="landing-main">
        <h1 class="landing-title">Sistema de Gestión de Proyectos de Grado</h1>
    </main>

</body>
</html>
