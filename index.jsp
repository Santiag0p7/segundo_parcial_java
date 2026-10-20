<%--
    =====================================================================
    index.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Proyectos de Grado
    ---------------------------------------------------------------------
    Página de aterrizaje pública.

    Contenido:
      * Encabezado con logo UTS y botón "Iniciar sesión" arriba a la derecha.
      * Hero con el título del sistema.
      * Sección informativa sobre los proyectos de grado.
      * Sección informativa sobre la UTS.
      * Pie institucional.

    Si el visitante ya tiene sesión activa, se redirige al panel que
    corresponde a su rol. Esta vista no usa header.jspf / footer.jspf
    porque tiene un diseño de portada propio.
    =====================================================================
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

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

<fmt:setLocale value="es_CO" />
<jsp:useBean id="fechaActual" class="java.util.Date" scope="page" />

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="author" content="Unidades Tecnológicas de Santander - UTS" />
    <meta name="description" content="Sistema de Gestión de Proyectos de Grado - UTS" />
    <meta name="theme-color" content="#005A8C" />
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
            --uts-dark-green: #7FA827;
            --uts-dark: #2D2D2D;
            --uts-gray: #6C757D;
            --uts-light: #F8F9FA;
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            color: var(--uts-dark);
            background: #fff;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.65;
        }

        a {
            text-decoration: none;
        }

        /* =============================================================
           Encabezado
           ============================================================= */
        .landing-header {
            position: sticky;
            top: 0;
            z-index: 50;
            background: rgba(255, 255, 255, .96);
            border-bottom: 1px solid rgba(45, 45, 45, .08);
            box-shadow: 0 4px 24px rgba(0, 0, 0, .06);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }

        .landing-header .container {
            min-height: 76px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
        }

        .landing-brand {
            display: inline-flex;
            align-items: center;
            gap: .75rem;
            color: var(--uts-deep-blue);
            min-width: 0;
        }

        .landing-brand img {
            width: 44px;
            height: 44px;
            object-fit: contain;
            flex-shrink: 0;
        }

        .landing-brand-text {
            display: flex;
            flex-direction: column;
            line-height: 1.1;
            min-width: 0;
        }

        .landing-brand-title {
            font-family: 'Archivo Black', 'Arial Black', sans-serif;
            font-size: 1rem;
            color: var(--uts-deep-blue);
            white-space: nowrap;
        }

        .landing-brand-sub {
            font-size: .68rem;
            letter-spacing: .08em;
            text-transform: uppercase;
            color: var(--uts-gray);
            white-space: nowrap;
        }

        .landing-login {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: .5rem;
            flex-shrink: 0;
            padding: .7rem 1.25rem;
            border-radius: 999px;
            background: var(--uts-green);
            color: var(--uts-dark);
            font-weight: 700;
            font-size: .92rem;
            box-shadow: 0 4px 14px rgba(164, 210, 51, .35);
            transition: transform .2s ease, background-color .2s ease, box-shadow .2s ease;
        }

        .landing-login:hover,
        .landing-login:focus {
            background: var(--uts-dark-green);
            color: #fff;
            transform: translateY(-2px);
            box-shadow: 0 8px 22px rgba(127, 168, 39, .35);
        }

        /* =============================================================
           Hero
           ============================================================= */
        .hero {
            position: relative;
            overflow: hidden;
            min-height: 68vh;
            display: flex;
            align-items: center;
            padding: 5rem 0 6rem;
            color: #fff;
            background:
                radial-gradient(circle at 18% 18%, rgba(255, 255, 255, .18), transparent 34%),
                radial-gradient(circle at 84% 82%, rgba(164, 210, 51, .30), transparent 38%),
                linear-gradient(135deg, var(--uts-deep-blue) 0%, #008CC4 48%, #6F9E1E 100%);
        }

        .hero::before {
            content: "";
            position: absolute;
            inset: 0;
            pointer-events: none;
            background-image:
                linear-gradient(rgba(255, 255, 255, .07) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255, 255, 255, .07) 1px, transparent 1px);
            background-size: 64px 64px;
            -webkit-mask-image: radial-gradient(circle at center, #000 0%, transparent 72%);
            mask-image: radial-gradient(circle at center, #000 0%, transparent 72%);
        }

        .hero .container {
            position: relative;
            z-index: 1;
        }

        .hero-eyebrow {
            display: inline-flex;
            align-items: center;
            gap: .45rem;
            padding: .4rem .9rem;
            margin-bottom: 1.25rem;
            border: 1px solid rgba(255, 255, 255, .32);
            border-radius: 999px;
            background: rgba(255, 255, 255, .13);
            color: rgba(255, 255, 255, .95);
            font-size: .78rem;
            font-weight: 600;
            letter-spacing: .06em;
            text-transform: uppercase;
        }

        .hero-title {
            max-width: 980px;
            margin: 0 auto;
            font-family: 'Archivo Black', 'Arial Black', 'Helvetica Neue', Arial, sans-serif;
            font-weight: 900;
            font-size: clamp(2.2rem, 5vw, 4.6rem);
            line-height: 1.06;
            letter-spacing: -.02em;
            text-wrap: balance;
            overflow-wrap: break-word;
            text-shadow: 0 12px 40px rgba(0, 0, 0, .25);
        }

        .hero-subtitle {
            max-width: 760px;
            margin: 1.35rem auto 0;
            color: rgba(255, 255, 255, .92);
            font-size: clamp(1rem, 1.4vw, 1.18rem);
        }

        /* =============================================================
           Secciones informativas
           ============================================================= */
        .section {
            padding: 5rem 0;
        }

        .section-projects {
            background: #fff;
        }

        .section-uts {
            background: var(--uts-light);
        }

        .section-kicker {
            display: inline-block;
            color: var(--uts-dark-green);
            font-size: .78rem;
            font-weight: 800;
            letter-spacing: .12em;
            text-transform: uppercase;
        }

        .section-title {
            margin: .45rem 0 1rem;
            color: var(--uts-dark);
            font-family: 'Archivo Black', 'Arial Black', 'Helvetica Neue', Arial, sans-serif;
            font-weight: 900;
            font-size: clamp(1.8rem, 3vw, 2.6rem);
            line-height: 1.15;
            letter-spacing: -.02em;
            overflow-wrap: break-word;
        }

        .section-lead {
            color: var(--uts-gray);
            font-size: 1.04rem;
            margin: 0;
        }

        .section-head {
            max-width: 820px;
            margin: 0 auto 2.5rem;
            text-align: center;
        }

        .project-card {
            height: 100%;
            padding: 1.75rem;
            border: 1px solid rgba(164, 210, 51, .28);
            border-radius: 18px;
            background: #fff;
            box-shadow: 0 8px 30px rgba(45, 45, 45, .055);
            transition: transform .2s ease, border-color .2s ease, box-shadow .2s ease;
        }

        .project-card:hover {
            transform: translateY(-6px);
            border-color: var(--uts-green);
            box-shadow: 0 18px 42px rgba(45, 45, 45, .11);
        }

        .project-icon {
            width: 56px;
            height: 56px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1.15rem;
            border-radius: 14px;
            background: linear-gradient(135deg, var(--uts-blue) 0%, var(--uts-green) 100%);
            color: #fff;
            font-size: 1.45rem;
        }

        .project-card h3 {
            margin: 0 0 .55rem;
            color: var(--uts-dark);
            font-family: 'Archivo Black', 'Arial Black', sans-serif;
            font-size: 1.12rem;
        }

        .project-card p {
            margin: 0;
            color: var(--uts-gray);
            font-size: .95rem;
        }

        .section-note {
            margin: 2rem auto 0;
            max-width: 780px;
            color: var(--uts-gray);
            font-size: .9rem;
            text-align: center;
        }

        /* =============================================================
           Sobre la UTS
           ============================================================= */
        .uts-facts {
            display: flex;
            flex-wrap: wrap;
            gap: .6rem;
            margin-top: 1.5rem;
        }

        .uts-facts span {
            display: inline-flex;
            align-items: center;
            gap: .45rem;
            padding: .45rem .85rem;
            border: 1px solid #e1e7ec;
            border-radius: 999px;
            background: #fff;
            color: var(--uts-dark);
            font-size: .83rem;
            font-weight: 600;
        }

        .uts-facts i {
            color: var(--uts-dark-green);
        }

        .uts-card {
            padding: 2rem;
            border: 1px solid rgba(0, 163, 224, .18);
            border-radius: 22px;
            background: #fff;
            text-align: center;
            box-shadow: 0 15px 40px rgba(0, 90, 140, .08);
        }

        .uts-card img {
            width: 86px;
            height: 86px;
            object-fit: contain;
            margin-bottom: .9rem;
        }

        .uts-card h3 {
            margin: 0 0 .75rem;
            color: var(--uts-deep-blue);
            font-family: 'Archivo Black', 'Arial Black', sans-serif;
            font-size: 1.05rem;
            line-height: 1.3;
        }

        .uts-card p {
            margin: .45rem 0;
            color: var(--uts-gray);
            font-size: .9rem;
        }

        .uts-card i {
            color: var(--uts-dark-green);
            margin-right: .3rem;
        }

        .uts-card a {
            color: var(--uts-deep-blue);
            font-weight: 700;
        }

        .uts-card a:hover {
            color: var(--uts-dark-green);
        }

        /* =============================================================
           Pie
           ============================================================= */
        .landing-footer {
            padding: 2.5rem 0;
            color: #fff;
            text-align: center;
            background: linear-gradient(135deg, var(--uts-deep-blue) 0%, var(--uts-dark) 100%);
        }

        .landing-footer p {
            margin: .25rem 0;
            color: rgba(255, 255, 255, .78);
            font-size: .88rem;
        }

        .landing-footer .footer-title {
            margin-bottom: .4rem;
            color: #fff;
            font-family: 'Archivo Black', 'Arial Black', sans-serif;
            font-size: 1rem;
        }

        /* =============================================================
           Responsive
           ============================================================= */
        @media (max-width: 767px) {
            .landing-header .container {
                min-height: 66px;
            }

            .landing-brand img {
                width: 38px;
                height: 38px;
            }

            .landing-brand-sub {
                display: none;
            }

            .landing-brand-title {
                font-size: .92rem;
            }

            .landing-login {
                padding: .55rem .9rem;
                font-size: .84rem;
            }

            .hero {
                min-height: auto;
                padding: 4rem 0 5rem;
            }

            .hero-eyebrow {
                max-width: 100%;
                font-size: .68rem;
                line-height: 1.35;
            }

            .hero-title {
                font-size: clamp(1.8rem, 8vw, 2.8rem);
            }

            .hero-subtitle {
                font-size: .96rem;
            }

            .section {
                padding: 3.5rem 0;
            }

            .uts-card {
                margin-top: .5rem;
            }
        }

        @media (max-width: 400px) {
            .landing-brand-text {
                display: none;
            }
        }
    </style>
</head>

<body>

    <%-- =============================================================
         Encabezado institucional
         ============================================================= --%>
    <header class="landing-header">
        <div class="container">
            <a class="landing-brand" href="${ctx}/index.jsp" aria-label="Inicio">
                <img src="${ctx}/assets/img/utslogo.png" alt="Logo UTS" />
                <span class="landing-brand-text">
                    <span class="landing-brand-title">Proyectos de Grado</span>
                    <span class="landing-brand-sub">Sistema de Gestión</span>
                </span>
            </a>

            <a class="landing-login" href="${ctx}/login.jsp">
                <i class="bi bi-box-arrow-in-right" aria-hidden="true"></i>
                <span>Iniciar sesión</span>
            </a>
        </div>
    </header>

    <main>

        <%-- =========================================================
             Hero
             ========================================================= --%>
        <section class="hero">
            <div class="container text-center">
                <span class="hero-eyebrow">
                    <i class="bi bi-buildings" aria-hidden="true"></i>
                    Institución Universitaria Tecnológica de Santander
                </span>

                <h1 class="hero-title">Sistema de Gestión de Proyectos de Grado</h1>

                <p class="hero-subtitle">
                    Un espacio para gestionar la propuesta, el desarrollo, las revisiones y la
                    sustentación de los proyectos de grado de la UTS.
                </p>
            </div>
        </section>

        <%-- =========================================================
             Proyectos de grado
             ========================================================= --%>
        <section class="section section-projects" id="proyectos">
            <div class="container">
                <div class="section-head">
                    <span class="section-kicker">Proyectos de Grado</span>
                    <h2 class="section-title">¿Qué es un proyecto de grado?</h2>
                    <p class="section-lead">
                        Es el trabajo académico en el que el estudiante integra los conocimientos de su
                        programa para plantear una solución a una necesidad o problema del entorno. En la
                        UTS se desarrolla por fases y culmina con la sustentación final.
                    </p>
                </div>

                <div class="row g-4">
                    <div class="col-12 col-md-6 col-lg-4">
                        <article class="project-card">
                            <span class="project-icon">
                                <i class="bi bi-lightbulb-fill" aria-hidden="true"></i>
                            </span>
                            <h3>Propuesta</h3>
                            <p>
                                Formulación y registro de la idea, selección de la propuesta y soporte
                                de pago para iniciar la Fase 1.
                            </p>
                        </article>
                    </div>

                    <div class="col-12 col-md-6 col-lg-4">
                        <article class="project-card">
                            <span class="project-icon">
                                <i class="bi bi-diagram-3-fill" aria-hidden="true"></i>
                            </span>
                            <h3>Desarrollo</h3>
                            <p>
                                Seguimiento de fases, entregables y revisiones del director y del
                                evaluador hasta completar el ciclo.
                            </p>
                        </article>
                    </div>

                    <div class="col-12 col-md-6 col-lg-4">
                        <article class="project-card">
                            <span class="project-icon">
                                <i class="bi bi-mic-fill" aria-hidden="true"></i>
                            </span>
                            <h3>Sustentación</h3>
                            <p>
                                Programación de la sustentación final y cierre del proceso de grado
                                ante el comité.
                            </p>
                        </article>
                    </div>
                </div>

                <p class="section-note">
                    El sistema también apoya la gestión de pagos, solicitudes extraordinarias,
                    informes y consultas del calendario académico.
                </p>
            </div>
        </section>

        <%-- =========================================================
             Sobre la UTS
             ========================================================= --%>
        <section class="section section-uts" id="uts">
            <div class="container">
                <div class="row align-items-center g-5">
                    <div class="col-12 col-lg-7">
                        <span class="section-kicker">Sobre la UTS</span>
                        <h2 class="section-title">Institución Universitaria Tecnológica de Santander</h2>
                        <p class="section-lead">
                            La UTS es una institución de educación superior pública de Santander,
                            acreditada en Alta Calidad, con más de 62 años de trayectoria y presencia
                            en Bucaramanga, Barrancabermeja, Vélez, Piedecuesta y modalidad virtual.
                        </p>
                        <p class="section-lead mt-3">
                            Este sistema centraliza la gestión de los proyectos de grado de sus
                            programas y conecta el trabajo de estudiantes, docentes y comité.
                        </p>

                        <div class="uts-facts">
                            <span><i class="bi bi-patch-check-fill" aria-hidden="true"></i>Acreditada en Alta Calidad</span>
                            <span><i class="bi bi-geo-alt-fill" aria-hidden="true"></i>Bucaramanga, Santander</span>
                            <span><i class="bi bi-buildings" aria-hidden="true"></i>Presencia regional y virtual</span>
                            <span><i class="bi bi-clock-history" aria-hidden="true"></i>Más de 62 años</span>
                        </div>
                    </div>

                    <div class="col-12 col-lg-5">
                        <div class="uts-card">
                            <img src="${ctx}/assets/img/utslogo.png" alt="Logo UTS" />
                            <h3>Institución Universitaria Tecnológica de Santander</h3>
                            <p>
                                <i class="bi bi-geo-alt-fill" aria-hidden="true"></i>
                                Calle de los Estudiantes #9-82<br />
                                Ciudadela Real de Minas<br />
                                Bucaramanga, Santander
                            </p>
                            <p>
                                <i class="bi bi-envelope-fill" aria-hidden="true"></i>
                                <a href="mailto:peticiones@correo.uts.edu.co">peticiones@correo.uts.edu.co</a>
                            </p>
                            <p>
                                <a href="https://www.uts.edu.co" target="_blank" rel="noopener">
                                    www.uts.edu.co
                                    <i class="bi bi-box-arrow-up-right" aria-hidden="true"></i>
                                </a>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

    </main>

    <%-- =============================================================
         Pie institucional
         ============================================================= --%>
    <footer class="landing-footer">
        <div class="container">
            <p class="footer-title">Sistema de Gestión de Proyectos de Grado</p>
            <p>Institución Universitaria Tecnológica de Santander · UTS</p>
            <p>
                Bucaramanga, Santander · © <fmt:formatDate value="${fechaActual}" pattern="yyyy" />
                UTS. Todos los derechos reservados.
            </p>
        </div>
    </footer>

</body>
</html>
