# AGENTS.md — Sistema de Trabajos de Grado UTS

Contexto persistente del proyecto para OpenCode. Leer antes de crear o modificar archivos.

## 1. Qué es este proyecto

Aplicación web académica para la gestión de trabajos de grado de las **Unidades
Tecnológicas de Santander (UTS)**: propuestas, proyectos, fases del ciclo,
entregables, revisiones, pagos, asignación de docentes (director/evaluador),
exoneración por Saber y sustentación final.

Es un proyecto de **segundo parcial** de la asignatura de desarrollo web.
Se despliega como *webapp* directamente en el Tomcat de XAMPP.

## 2. Restricciones técnicas obligatorias (NO negociables)

1. **NO se permiten** Servlets, Controllers en Java, ni clases POJO (`.java`).
2. **Todo** el manejo de vistas, conexión a base de datos y lógica de negocio
   debe ser **100% JSP + JSTL** (`<c:>`, `<sql:>`, `<fmt:>`, `<fn:>`).
   - No se permiten scriptlets `<% ... %>` con lógica Java (solo directivas
     `<%@ ... %>` y comentarios `<%-- --%>`). *Única excepción autorizada por el
     usuario:* `<% session.invalidate(); %>` en `logout.jsp`.
   - Para variables nuevas usar `<c:set>`; para mapas/objetos simples usar
     `<jsp:useBean ... class="java.util.HashMap">` + `<c:set target=...>`.
3. **Bootstrap 5 por CDN** para todo el diseño visual (nunca CSS propio extenso,
   solo ajustes puntuales justificados).
4. Conexión a MySQL exclusivamente vía `<sql:setDataSource var="db" ...>` y
   consultas vía `<sql:query dataSource="${db}">` / `<sql:update dataSource="${db}">`.
5. Toda salida de datos desde la BD o desde la sesión debe ir con `<c:out>`
   (evita XSS) o con `${fn:escapeXml(...)}`.

## 3. Entorno

| Elemento      | Valor |
| ------------- | ----- |
| Servidor      | Apache Tomcat **8.5.96** en `C:\xampp\tomcat` |
| Java          | JDK **17** en `C:\Program Files\Java\jdk-17` |
| `JAVA_HOME`   | **Sin definir** (ni usuario ni equipo). Sin él, `startup.bat` aborta con *"Neither the JAVA_HOME nor the JRE_HOME environment variable is defined"* |
| Contexto web  | `http://localhost:8080/segundo_parcial_java/` |
| BD            | **MariaDB 10.4.32** (el "MySQL" de XAMPP) en `localhost:3306`, base `uts_trabajos_grado` |
| Usuario/clave | `root` / *(vacío)* |

JSTL es **1.2**, por eso las URIs de taglib son las clásicas
(`http://java.sun.com/jsp/jstl/...`). **No** usar las URIs de Jakarta
(`jakarta.tags.*`); el proyecto no usa JSTL 3.

### 3.1 Servicios: los levanta el usuario, no el agente

Acuerdo explícito con el usuario: **el agente no arranca Tomcat ni MySQL**. Las
sesiones anteriores demostraron que:

- Un proceso lanzado con `Start-Process` o `catalina.bat run` desde el shell del
  agente queda dentro del *job object* de la herramienta y **muere** al cerrarse
  la ejecución (pasó con MySQL en mitad de una verificación: el 500 resultante
  parecía un bug del JSP y era la BD caída).
- Levantar el servidor por el agente deja el panel de XAMPP en un estado que no
  coincide con la realidad (MySQL corriendo pero el panel "no lo ve"), lo que
  confunde al usuario.

Flujo acordado: **el usuario arranca Tomcat** (y MySQL si hace falta) y el agente
verifica **solo por HTTP** con `curl.exe`. Para arrancarlo a mano hace falta
exportar las variables en la misma consola:

```powershell
$env:JAVA_HOME    = "C:\Program Files\Java\jdk-17"
$env:CATALINA_HOME = "C:\xampp\tomcat"
cmd /c "C:\xampp\tomcat\bin\startup.bat"     # arrancar
cmd /c "C:\xampp\tomcat\bin\shutdown.bat"    # detener
```

Definir `JAVA_HOME` de forma permanente (variable de usuario) es lo que hace
funcionar el botón **Tomcat** del panel de XAMPP, que ya está habilitado
(`TomcatVisible=1` en `C:\xampp\xampp-control.ini`). Sin `JAVA_HOME`, el botón
falla igual que el `.bat`.

## 4. Estructura del proyecto

```text
segundo_parcial_java/
├── db/script1.sql            # Esquema completo (los INSERT semilla están comentados)
├── assets/img/utslogo.png    # Logo institucional (favicon, header, footer y login)
├── login.jsp                 # RF-01: acceso con pestañas por rol (vista pública)
├── validar_login.jsp         # Proceso: valida en BD y abre la sesión
├── logout.jsp                # Proceso: <c:remove> + session.invalidate() + redirect
├── dashboard.jsp             # Panel dinámico por rol con sidebar (vista protegida)
├── dashboard_admin.jsp       # Panel propio del ADMINISTRADOR (gestión global)
├── admin_usuarios.jsp        # Listado/búsqueda de usuarios (solo ADMIN)
├── admin_usuario_form.jsp    # Crear/editar usuario y perfil (solo ADMIN)
├── admin_usuario_procesar.jsp # Proceso: crear/editar/activar/clave (sin HTML)
├── admin_suplantar.jsp       # Selector para entrar como estudiante/docente
├── admin_impersonar.jsp      # Proceso: cambia la sesión al usuario elegido
├── admin_volver.jsp          # Proceso: restaura la sesión del administrador
├── index.jsp                 # Portada pública: título + inicio de sesión
├── banco_ideas.jsp           # RF-04..RF-07: banco de propuestas (protegida)
├── crear_propuesta.jsp       # RF-04: formulario de propuesta (DOCENTE/COMITE)
├── guardar_propuesta.jsp     # Proceso RF-04: INSERT en PROPUESTAS_PROYECTO
├── seleccionar_propuesta.jsp # Compatibilidad: redirige a fase1_registro.jsp
├── mi_proyecto.jsp           # Paso 5: seguimiento del proyecto del estudiante
├── fase1_registro.jsp        # Paso 5: alta en Fase 1 (idea propia o del banco)
├── fase1_procesar.jsp        # Paso 5: pago + proyecto + integrantes (proceso)
├── comite_fase1.jsp          # Paso 5: comité aprueba el pago y avanza a Fase 2
├── solicitudes_estudiante.jsp # Paso 7: solicitudes extraordinarias (RF-23..RF-29)
├── procesar_solicitud.jsp    # Paso 7: proceso de las 4 solicitudes (sin HTML)
├── comite_solicitudes.jsp    # Paso 7: dictamen del comité sobre las solicitudes
├── programar_sustentacion.jsp # Paso 8: comité programa la sustentación (RF-16)
├── consultas_transversales.jsp # Paso 8: calendario académico (RF-30)
├── comite_informes.jsp        # Paso 8: búsqueda e informes (RF-32 a RF-35)
├── comite_asignaciones.jsp    # Paso 9: comité asigna director y evaluador (RF-10)
├── entregables_estudiante.jsp # Paso 9: estudiante sube entregables (RF-13)
├── evaluacion_docente.jsp     # Paso 9: docentes revisan entregables (RF-14, RF-15)
├── comite_fases.jsp           # Paso 9: comité da visto bueno y avanza fase (RF-16)
└── WEB-INF/
    ├── web.xml               # jsp-property-group: fuerza UTF-8 en *.jsp y *.jspf
    ├── lib/                  # jstl-1.2.jar, mysql-connector-j-8.4.0.jar
    └── jspf/
        ├── conexion.jspf     # Taglibs JSTL + <sql:setDataSource var="db">
        ├── header.jspf       # HTML5 + Bootstrap 5 + topbar + navbar + <main>
        └── footer.jspf       # </main> + footer institucional + JS de Bootstrap
```

Estado actual: **Pasos 2 (infraestructura base), 3 (autenticación, RBAC y
dashboard dinámico), 4 (Módulo 2: banco de propuestas), 5 (Módulo 3, Fase 1:
idea, dupla y soporte de pago), 7 (Módulo 5: solicitudes extraordinarias),
8 (Módulos 3 y 6: sustentación, consultas transversales e informes) y
9 (flujo jerárquico de revisión) terminados y verificados**. Suites: Paso 3 =
64 comprobaciones, Paso 4 = 81, Paso 5 = 92, Paso 7 = 91, Paso 8 = 82 y
Paso 9 = 58; todas en verde (RF-04 a RF-16, RF-23 a RF-30 y RF-32 a RF-35,
RBAC, validaciones, tildes y regresión de los pasos anteriores).

Además se agregó el **panel propio del ADMINISTRADOR** con gestión de usuarios
y suplantación controlada de estudiantes/docentes (ver 5.9). Los 34 JSP
compilan con `JspC` sin errores y el flujo del panel admin se verificó por HTTP
(login, panel, usuarios, suplantación y regreso).

## 5. Plantilla obligatoria para una vista nueva

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="pageTitle" value="Nombre de la vista - UTS" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>

  <!-- contenido; apertura y cierre de columnas Bootstrap -->

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
```

Reglas para las vistas:

- El `contentType` con `charset=UTF-8` va **solo** en la página, no en los `.jspf`.
- Nunca escribir `<html>`, `<head>`, `<body>`, `<main>` ni el navbar: ya están en
  `header.jspf` / `footer.jspf`.
- El enlace del navbar se prefija con `${ctx}` (definido en `header.jspf`).
- `pageTitle` es opcional; se imprime con `<c:out>`.
- Una **página de proceso** (la que no devuelve HTML, como `validar_login.jsp` o
  `logout.jsp`) no incluye header/footer y no escribe nada antes de su
  `<c:redirect>` (si la respuesta se confirma, `c:redirect` lanza
  `IllegalStateException`).

### 5.1 Flujo de autenticación y RBAC (Paso 3)

```text
login.jsp ──POST correo/contrasena──> validar_login.jsp
                                        ├─ OK ADMINISTRADOR ─> dashboard_admin.jsp
                                        ├─ OK otros roles   ─> dashboard.jsp
                                        └─ mal ─> login.jsp?error=... (mensaje)
logout.jsp ─> <c:remove var="usuario"> + session.invalidate() ─> login.jsp?msg=...
Toda vista protegida ─> <c:if test="${empty sessionScope.usuario}"> ─> login.jsp?error=...
```

Detalles deliberados:

- `validar_login.jsp` usa `<fmt:requestEncoding value="UTF-8" />` **antes** de leer
  cualquier `${param...}`: Tomcat 8.5 decodifica el cuerpo POST como ISO-8859-1 si
  nadie fija la codificación y se corrompen claves o correos con tilde.
- La consulta usa `<sql:param>` (parametrizada), nunca `${param...}` concatenado.
- El JOIN a `ESTUDIANTES_PERFIL` y `PROGRAMAS_ACADEMICOS` es **LEFT**, no INNER:
  docentes, comité y administrador no tienen fila en `ESTUDIANTES_PERFIL` y con
  INNER no podrían iniciar sesión nunca.
- `login.jsp` redirige a `dashboard_admin.jsp` si la sesión activa es
  `ADMINISTRADOR` y a `dashboard.jsp` para los demás roles.

### 5.2 Contrato de la sesión

`header.jspf` y `dashboard.jsp` leen exactamente estas claves, que produce
`validar_login.jsp`:

```text
sessionScope.usuario.id_usuario           -> PK de USUARIOS
sessionScope.usuario.documento_identidad  -> documento
sessionScope.usuario.nombres              -> nombres
sessionScope.usuario.apellidos            -> apellidos
sessionScope.usuario.correo_institucional -> correo
sessionScope.usuario.rol                  -> ESTUDIANTE | DOCENTE | COMITE | ADMINISTRADOR
sessionScope.usuario.nivelFormacion       -> TECNOLOGIA | INGENIERIA (vacío si no es estudiante)
sessionScope.usuario.codigoEstudiantil    -> código (solo estudiantes)
sessionScope.usuario.especialidad         -> especialidad (solo docentes)
```

`nivelFormacion` solo aplica a estudiantes (viene de `PROGRAMAS_ACADEMICOS`);
para docente/comité queda vacío y el header muestra `SIN NIVEL`.

> ⚠ **El enunciado de los RF escribe este campo como `nivel_formacion`. La clave
> real es `nivelFormacion` (camelCase).** Como EL distingue mayúsculas, el filtro
> de RF-05 debe escribirse `${sessionScope.usuario.nivelFormacion}`; con
> `nivel_formacion` el `<sql:param>` recibe vacío y el estudiante no ve **ninguna**
> propuesta (falla silenciosa, sin error de JSP).

Si alguna vez se renombra una clave, hay que actualizar `header.jspf`,
`dashboard.jsp` y la tabla de `validar_login.jsp` **a la vez** (trampa 5).

### 5.3 Flujo del Paso 5 (Módulo 3, Fase 1)

```text
mi_proyecto.jsp ──┬─ sin proyecto ─┬─> banco_ideas.jsp ──«Seleccionar Idea»──┐
                  │                └─> fase1_registro.jsp                  │
                  │                          ^                             │
                  │                          └── id_propuesta=N ────────────┘
                  │                          |
                  │                          v  POST (titulo, descripcion,
                  │                    fase1_procesar.jsp   codigo_companero, soporte_pago)
                  │                          |
                  │                          v
                  └─ con proyecto ─────> mi_proyecto.jsp?msg=...   (seguimiento)
comite_fase1.jsp ──«Aprobar Pago y Fase 1»──> UPDATE pago + fase_actual = 2 ──> comite_fase1.jsp?msg=...
```

Reglas del flujo:

- Un estudiante solo puede estar en **un** proyecto (`UNIQUE(id_estudiante)` en
  `INTEGRANTES_PROYECTO`); `fase1_registro.jsp` y `fase1_procesar.jsp` lo
  comprueban **antes** de insertar y redirigen a `mi_proyecto.jsp`.
- El compañero de la dupla es opcional y debe existir en
  `ESTUDIANTES_PERFIL`, estar activo, ser del **mismo** nivel de formación y no
  tener ya proyecto. Se busca por `codigo_estudiantil` y entra con
  `es_lider = FALSE`; quien registra queda `es_lider = TRUE`.
- `comite_fase1.jsp` usa el patrón **PRG dentro de la misma página**: el bloque
  de aprobación se ejecuta arriba de todo, antes del `header`, y termina en
  `<c:redirect>` a sí misma (si se escribiera HTML antes, `c:redirect` lanzaría
  `IllegalStateException`). El `POST` revalida en BD que el pago sea del líder,
  esté `PENDIENTE` y el proyecto en Fase 1; no se fía de los ids del formulario.
- La acción de aprobar **no** vive en un `*_procesar.jsp` porque el enunciado la
  pide en la vista del comité; aun así no hay lógica en un scriptlet.

### 5.4 Flujo del Paso 7 (Módulo 5, solicitudes extraordinarias)

```text
solicitudes_estudiante.jsp ──POST tipo_solicitud──> procesar_solicitud.jsp
        ^                                                   |
        |                                                   v
        └──────────────── msg / error ──────────────  INSERT / UPDATE

comite_solicitudes.jsp ──POST accion──> misma vista (PRG) ──UPDATE──> ?msg / ?error
```

Reglas del flujo:

- El proyecto **nunca** se recibe por parámetro: se deduce de la sesión
  (`INTEGRANTES_PROYECTO`). Así no se puede radicar sobre el proyecto de otro.
- `CAMBIO_DOCENTE` envía `id_asignacion` (no `id_docente`): el servidor relee
  la asignación para obtener `id_docente_actual` + `subrol_afectado` y
  comprueba que pertenezca al proyecto del estudiante.
- `PRORROGA` crea primero `PAGOS_PROYECTO` (tipo `PRORROGA`, estado
  `PENDIENTE`) y luego la solicitud con ese `id_pago`, porque la FK es NOT NULL.
- `EXONERACION_SABER` exige `fase_actual >= 4` y un puntaje entre 1 y 500.
  El puntaje se valida con un `<c:if>` dentro de `<c:catch>`: si no es
  numérico, EL lanza `ELException` y el `catch` lo convierte en error de
  validación (no en un 500).
- `CANCELACION` es inmediata (no existe tabla de solicitudes de cancelación):
  `UPDATE PROYECTOS_GRADO SET estado = 'CANCELADO'`.
- Se bloquea una segunda solicitud `PENDIENTE` del mismo tipo (y del mismo
  subrol, en el cambio de docente).
- Un proyecto `CANCELADO`, `EXONERADO` o `RECHAZADO` no admite solicitudes
  nuevas: la vista solo muestra el historial.
- Aprobar una prórroga también marca su pago como `APROBADO` (y rechazarla
  como `RECHAZADO`): si no, el pago quedaría `PENDIENTE` para siempre.

#### PRG sin salida en JSP

`comite_solicitudes.jsp` procesa el POST **antes** de cualquier salida y deja
todo el render —incluidos `header.jspf` y `footer.jspf`— dentro de
`<c:if test="${empty param.accion}">`. Como el `<%@ include %>` es estático,
su HTML se expande dentro del `c:if`: cuando se atiende un POST la página no
emite ni un byte y solo queda el `302`. Es la forma segura de hacer PRG en una
sola vista (escribir HTML después de `<c:redirect>` arriesga
`IllegalStateException`).

### 5.5 Paso 8: sustentación, consultas transversales e informes

```text
programar_sustentacion.jsp   (COMITE / ADMIN)
    POST accion=programar
      -> INSERT o UPDATE SUSTENTACIONES   (reprogramar = UPDATE)
      -> UPDATE PROYECTOS_GRADO estado = 'APROBADO'   (solo proyectos en Fase 6)

comite_informes.jsp          (COMITE / ADMIN)  GET con filtros
    1) avance por estudiante   2) carga por DIRECTOR   3) carga por EVALUADOR

consultas_transversales.jsp  (cualquier rol autenticado)
    calendario institucional (hitos) + fases del ciclo desde FASES_CICLO
```

- **RF-11**: el evaluador se revela en `mi_proyecto.jsp` cuando
  `fase_actual >= 6`; antes se muestra "Identidad reservada hasta la Fase 6"
  (el director siempre es visible). La misma identidad aparece en
  `programar_sustentacion.jsp`, porque allí el proyecto ya está en Fase 6.
- Un proyecto **`APROBADO`** (sustentación programada) cuenta como cerrado en
  `solicitudes_estudiante.jsp` y en `procesar_solicitud.jsp`: no admite
  solicitudes nuevas.
- Los filtros de los informes son **opcionales sin SQL dinámico**: no se puede
  meter `<c:if>` dentro de `<sql:query>`, así que se usa
  `AND (? = '' OR columna = ?)` — seis `<sql:param>`, dos por filtro, en el
  mismo orden en que aparecen los `?`. Nivel y estado pasan por lista blanca.
- El **calendario** es dato institucional (el esquema no tiene tabla de
  calendario): se declara como cadena `hito|fase|fecha|descripción` y se
  recorre con `fn:split`, sin scriptlets ni Java embebido. Las fases, que sí
  están normalizadas, se leen de `FASES_CICLO`.
  **Datos oficiales 2026-2 (30 hitos):** Acuerdo 03-024 del 07/04/2026 y
  modificación 03-075 del 22/09/2026 (esta última solo cambia las ceremonias
  de graduación). Se extrajeron de los PDF de
  `https://www.uts.edu.co/calendario-academico/` con `pypdf`
  (`extract_text(extraction_mode="layout")`): el PDF viene con OCR y tablas en
  columnas, y sin `layout` el texto sale desalineado. Para cambiar de período:
  descargar el Acuerdo nuevo, extraerlo igual y reemplazar `hitosTexto`.
  La columna **Fase** solo se marca (1 o 2) en las actividades de trabajo de
  grado —inscripción de la modalidad, cancelación del derecho pecuniario y
  aprobación de la propuesta—; el resto va como «Institucional» (fase 0).
- El menú de `header.jspf` suma «Calendario Académico» para todos los roles y
  «Sustentaciones» / «Informes y Búsquedas» solo para COMITE y ADMINISTRADOR.

### 5.6 Paso 9: flujo jerárquico de revisión (Bloque 3)

```text
comite_asignaciones.jsp    (COMITE / ADMIN)
    POST accion=asignar
      -> INSERT ASIGNACIONES_DOCENTES (DIRECTOR)
      -> INSERT ASIGNACIONES_DOCENTES (EVALUADOR)
      -> El proyecto sigue en Fase 2 hasta que suba entregable

entregables_estudiante.jsp (ESTUDIANTE)
    POST accion=subir
      -> INSERT ENTREGABLES (solo si no existe para la fase actual)
      -> El entregable queda pendiente de revisión del director

evaluacion_docente.jsp     (DOCENTE)
    POST accion=revisar
      -> INSERT REVISIONES_ENTREGABLE (DIRECTOR o EVALUADOR)
      -> Director: solo ve entregables sin revisión de director
      -> Evaluador: solo ve entregables donde director = APROBADO

comite_fases.jsp           (COMITE / ADMIN)
    POST accion=aprobar
      -> INSERT REVISIONES_ENTREGABLE (COMITE, APROBADO)
      -> UPDATE fase_actual = fase_actual + 1
      -> Si fase >= 6: estado = 'APROBADO' (listo para sustentación)
    POST accion=rechazar
      -> INSERT REVISIONES_ENTREGABLE (COMITE, RECHAZADO)
      -> No avanza la fase (estudiante debe corregir)
```

- **Flujo jerárquico estricto**: Director → Evaluador → Comité. Cada rol solo
  ve los entregables que le corresponde revisar según el estado de las
  revisiones previas.
- **RF-11 (anonimato del evaluador)**: en `evaluacion_docente.jsp`, el director
  no ve quién es el evaluador (solo el comité). En `mi_proyecto.jsp`, el
  estudiante no ve al evaluador hasta Fase 6.
- **RF-15 (flujo jerárquico)**: el evaluador solo puede revisar si el director
  ya aprobó. El comité solo puede dar visto bueno si ambos (director y
  evaluador) aprobaron.
- **RF-16 (avance de fase)**: cuando el comité aprueba, la fase avanza
  automáticamente (+1). Si alcanza Fase 6, el proyecto queda en estado
  `APROBADO` y puede programarse la sustentación.
- **No hay transacciones**: JSTL no las ofrece. Si falla el segundo INSERT en
  `comite_asignaciones.jsp` (evaluador), el primero (director) ya se ejecutó.
  Se valida antes para minimizar el riesgo, pero no es atómico.
- **Revisión de entregables**: se usa `REVISIONES_ENTREGABLE` con
  `string_revisor` ENUM ('DIRECTOR', 'EVALUADOR', 'COMITE') y `estado_evaluacion`
  ENUM ('APROBADO', 'RECHAZADO', 'AJUSTAR'). Cada revisor solo puede dejar
  **una** revisión por entregable (se valida con `NOT EXISTS`).
  **La UI y el servidor solo aceptan dos decisiones: `APROBADO` y `RECHAZADO`.**
  El valor `AJUSTAR` sigue existiendo en el ENUM (no se puede quitar desde JSP
  sin un `ALTER`), pero `evaluacion_docente.jsp` no lo ofrece y lo rechaza si
  llega por POST manipulado.
- **Estados visibles del entregable (tres)**: `En espera` (subido, sin dictamen
  final), `Rechazado` (algún revisor lo rechazó) y `Validado` (el comité dio el
  visto bueno). El historial de `entregables_estudiante.jsp` muestra además el
  motivo del rechazo.
- **Re-subida tras rechazo**: se puede subir otro archivo para la misma fase
  **solo si el último entregable de esa fase quedó `RECHAZADO`**. Si está
  `En espera` o `Validado`, el formulario no se muestra y el POST se rechaza en
  el servidor con el mismo criterio. Cada re-subida inserta un `ENTREGABLES`
  nuevo (con `numero_entregable` siguiente); el anterior queda como historial y
  ya no vuelve a la cola de revisión porque conserva su revisión `RECHAZADO`.
  Un entregable de la fase puede repetirse: la tabla no tiene
  `UNIQUE (id_proyecto, fase_asociada)`.

### 5.7 Layout del panel: barra lateral (sidebar)

`dashboard.jsp` es la **única** vista con sidebar. Dentro del
`<main class="container">` que abre `header.jspf` monta un `row g-4`:

```text
aside   col-12 col-md-3 col-lg-2   > div.uts-sidebar (bg-white, sticky, shadow-sm)
section col-12 col-md-9 col-lg-10    bienvenida + KPIs + tarjetas de módulos
```

- El menú se declara como una cadena `href|icono|texto` separada por `;` y se
  recorre con `fn:split`: evita duplicar un `<ul>` por rol y no usa scriptlets.
- El ítem activo se marca con `campos[0] eq 'dashboard.jsp'`, porque esta es la
  única vista que pinta el sidebar. **Si el sidebar se extrae a un `.jspf`
  compartido**, esa comparación debe hacerse contra
  `${pageContext.request.servletPath}`.
- Los estilos propios son **5 reglas** acotadas a `.uts-sidebar` /
  `.uts-nav-link` (Bootstrap 5 no trae componente de sidebar) y viven en un
  `<style>` dentro del body para no tocar `header.jspf`.
- **`header.jspf` y `footer.jspf` no se modificaron**: el navbar superior sigue
  siendo la barra institucional global; el sidebar es la navegación del panel.
- Los KPIs usan subconsultas escalares dentro de una tabla derivada (trampa 5) y
  no comparan columnas `BOOLEAN` con 1/0 (trampa 12). Un estudiante sin
  proyecto ve una llamada a la acción (banco / idea propia) en lugar de KPIs.

### 5.8 Acceso, tipografía y política de textos

- **Punto de entrada**: `index.jsp` es la portada pública minimalista: fondo
  institucional azul-verde, título central "Sistema de Gestión de Proyectos de
  Grado" y botón "Iniciar sesión" arriba a la derecha. No incluye
  `header.jspf`/`footer.jspf` para no agregar navbar, secciones ni pie. Si hay
  sesión activa, redirige al panel del rol (`dashboard_admin.jsp` para
  administrador y `dashboard.jsp` para los demás).
- **Login**: `login.jsp` es la pantalla de acceso con tres pestañas por rol
  (`ESTUDIANTE`, `DOCENTE`, `COMITE`) generadas con `fn:split`. La tercera se
  rotula **"Comité / Administrador"** y su valor oculto sigue siendo `COMITE`.
  Cada pestaña tiene su propio formulario que envía a `validar_login.jsp` con un
  campo oculto `perfil`. **`validar_login.jsp` compara `perfil` con el rol real**:
  si el usuario intenta entrar por una pestaña que no corresponde a su cuenta, el
  sistema lo rechaza con el mensaje "El perfil seleccionado no coincide con esta
  cuenta. Seleccione la pestaña correcta para su rol." Excepción: la pestaña
  `COMITE` admite también el rol `ADMINISTRADOR` (el usuario administrador entra
  por esa pestaña).
- **Usuario administrador**: `admin@correo.uts.edu.co` / `uts2026`, rol
  `ADMINISTRADOR`, sin fila en `ESTUDIANTES_PERFIL` ni `DOCENTES_PERFIL`. Lo crea
  `db/seed_minimo_clevercloud.sql` (y su versión sin comentarios de línea
  `db/seed_minimo_clevercloud_paste.sql`). No existe una cuarta pestaña en
  `login.jsp`: el administrador usa la de "Comité / Administrador".
- **Tipografía**: los enlaces de Google Fonts están en `header.jspf`.
  `Archivo Black` para encabezados (`h1`–`h6`, `.h1`–`.h6`) e `Inconsolata` para
  el resto (cuerpo, botones, formularios, tablas, badges).
- **Escala tipográfica**: base **17px** (`body { font-size: 1.0625rem }`,
  `line-height: 1.6`) y encabezados con `clamp()` —crecen con el ancho de la
  ventana hasta un máximo— para que el aumento no rompa el responsive:
  `h1` 1.75–2.15rem, `h2` 1.5–1.8rem, `h3` 1.3–1.55rem, `h4` 1.2–1.38rem,
  `h5` 1.15rem, `h6` 1.08rem. Los `.small`/`small` van a `.9em` para no quedar
  diminutos frente al texto base.
- **Sidebar**: `col-12 col-md-3 col-lg-3 col-xl-2` (más ancho en `lg` para que
  los textos largos no se apilen) y `.uts-nav-link` a `.95rem`.
- **Paleta**: fondo `#F8F9FA`, verde UTS `#198754`. La barra superior
  institucional es **blanca con texto verde** (`bg-white text-success`) y borde
  inferior `#dee2e6`; el navbar principal sigue en verde. Las tarjetas usan
  `var(--bs-border-radius-xl)` (equivale a `rounded-4`) con sombra suave.
- **Logo institucional**: `assets/img/utslogo.png` (512×512, PNG, ~5 KB). Se usa
  como **favicon** (`<link rel="icon">` y `apple-touch-icon` en `header.jspf`),
  en la barra superior (26 px), en el navbar (30 px sobre un círculo blanco de
  40 px para garantizar contraste sobre el verde), en el pie (20 px sobre
  círculo blanco) y en `login.jsp` (88 px). En los `.jspf` se referencia con
  `${ctx}`; en `login.jsp`, con ruta relativa.
- **PDF de demostración**: `conexion.jspf` define `${pdfDemo}` con un PDF
  público. Los enlaces a comprobantes/certificados del comité usan
  `fn:startsWith(ruta, 'http') ? ruta : pdfDemo`, así la demo descarga un PDF
  real aunque la ruta guardada sea simulada (`comprobantes/x.pdf`).
- **RF-31 (formatos de grado) queda FUERA de alcance** por decisión del
  usuario: la sección se eliminó de `consultas_transversales.jsp` porque no se
  pueden descargar PDFs institucionales. La vista quedó solo con el calendario
  académico y las fases del ciclo.
- **Política de textos visibles**: no se muestran notas explicativas, guías de
  uso ni avisos de simulación. Se conservan los mensajes de estado
  («No fue posible consultar…», «No hay … pendientes») y las etiquetas de
  datos. Los comentarios `<%-- --%>` del código no se ven en pantalla y se
  mantienen.

### 5.9 Panel de administración y suplantación

```text
login.jsp -> validar_login.jsp
  ├─ ADMINISTRADOR -> dashboard_admin.jsp
  └─ otros roles   -> dashboard.jsp

dashboard_admin.jsp
  ├─ admin_usuarios.jsp -> admin_usuario_form.jsp -> admin_usuario_procesar.jsp
  ├─ admin_suplantar.jsp -> admin_impersonar.jsp -> dashboard.jsp (rol suplantado)
  └─ módulos del comité, banco_ideas.jsp y consultas_transversales.jsp

header.jspf (con adminOriginal en sesión)
  -> aviso "Volver al panel admin" -> admin_volver.jsp -> dashboard_admin.jsp
```

- `dashboard.jsp` redirige a `dashboard_admin.jsp` cuando el rol es
  `ADMINISTRADOR` y no hay una suplantación activa. `validar_login.jsp` también
  envía al panel propio.
- `dashboard_admin.jsp` es exclusivo del administrador real. Si se entra
  mientras hay una suplantación, redirige a `admin_volver.jsp`, que restaura la
  sesión del administrador.
- **Suplantación**: `admin_impersonar.jsp` guarda el mapa del administrador en
  `sessionScope.adminOriginal` y reemplaza `sessionScope.usuario` por el usuario
  elegido. Solo permite cuentas activas con rol `ESTUDIANTE`, `DOCENTE` o
  `COMITE`; nunca otro `ADMINISTRADOR`.
- Las vistas de estudiante y docente **no se modificaron**: siguen usando
  `sessionScope.usuario.id_usuario`, por eso la suplantación permite operarlas
  sin duplicar lógica ni agregar selectores en cada página.
- `header.jspf` calcula `panelUrl`: `dashboard_admin.jsp` para el administrador
  real y `dashboard.jsp` para el resto. El aviso de suplantación aparece dentro
  de `<main>` y se ve en todas las vistas que incluyen el header.
- **Gestión de usuarios**: `admin_usuarios.jsp` lista y filtra; el formulario
  crea o edita; el proceso inserta/actualiza y maneja el perfil
  (`ESTUDIANTES_PERFIL` / `DOCENTES_PERFIL`). Acciones: activar/desactivar,
  restablecer clave a `uts2026` y cambiar rol. No hay borrado físico.
- El cambio de rol se bloquea si el usuario tiene proyectos o asignaciones. El
  administrador no puede desactivar ni cambiar el rol de su propia cuenta.
- No se agregaron tablas ni clases Java: todo es JSP/JSTL. Los formularios usan
  `<sql:param>` y las salidas `<c:out>` / `fn:escapeXml`.
- El seed de Clever Cloud crea `admin@correo.uts.edu.co` / `uts2026`.

## 6. Trampas ya detectadas (no reintroducirlas)

1. **`&amp;` en atributos de tag JSP.** En sintaxis JSP clásica las entidades XML
   **no** se expanden dentro de un atributo, así que
   `url="...?useSSL=false&amp;serverTimezone=UTC"` rompe la conexión. Usar `&`
   literal (ya está aplicado en `conexion.jspf`).
2. **`<fmt:formatDate>` sin locale.** Si el request no trae `Accept-Language`
   (curl, PowerShell, algunos clientes), JSTL no resuelve locale y en vez de
   aplicar el `pattern` imprime `Date.toString()` → `Sun Oct 18 ... 2026`.
   Por eso `header.jspf` fija `<fmt:setLocale value="es_CO" />`. Toda página que
   use `<fmt:formatDate>` / `<fmt:formatNumber>` debe haber incluido el header
   antes.
3. **Scriptlets con `new java.util.Date()`**: usar
   `<jsp:useBean id="x" class="java.util.Date" />` para inyectar la fecha actual.
4. **No borrar `WEB-INF/lib/*.jar`**: son necesarios para JSTL y el driver MySQL.
   Existen copias también en `C:\xampp\tomcat\lib`.
5. **`<sql:query>` ignora los alias `AS`.** Las claves del `row` de JSTL 1.2 son
   los **nombres físicos** de las columnas (`ResultSetMetaData.getColumnName`),
   **no** las etiquetas del `SELECT`. Comprobado:
   `SELECT r.nombre AS rol` produce la clave `nombre`, y
   `SELECT pa.nivel_formacion AS nivelFormacion` produce `nivel_formacion`.
   Por eso `${usuario.rol}` llegaba **vacío** y el dashboard caía siempre en
   `<c:otherwise>` ("Rol sin panel configurado").

   **Solución aplicada** en `validar_login.jsp`: envolver la consulta en una
   tabla derivada, cuyas columnas sí se llaman como el alias, para poder seguir
   usando `<c:set var="usuario" value="${resUsuario.rows[0]}" scope="session" />`:

   ```sql
   SELECT t.* FROM (
       SELECT r.nombre AS rol, pa.nivel_formacion AS nivelFormacion, ...
       FROM USUARIOS u INNER JOIN ROLES r ON ... WHERE ...
   ) t
   ```

   Ojo: las claves salen **sensibles a mayúsculas**; `nivelFormacion` y
   `nivel_formacion` son claves distintas.
6. **Los `.jspf` necesitan `web.xml` para leerse en UTF-8.** Un `.jspf` sin BOM y
   sin directiva propia se lee como ISO-8859-1: el `pageEncoding="UTF-8"` del JSP
   que lo incluye **no se hereda**. El síntoma es texto doble codificado
   (`Cerrar sesiÃ³n`, bytes `C3 83 C2 B3`) **solo** en lo que viene de los `.jspf`,
   mientras las cadenas del propio JSP se ven bien. Arreglado de forma
   declarativa en `WEB-INF/web.xml`:

   ```xml
   <jsp-config>
       <jsp-property-group>
           <url-pattern>*.jsp</url-pattern>
           <url-pattern>*.jspf</url-pattern>
           <page-encoding>UTF-8</page-encoding>
       </jsp-property-group>
   </jsp-config>
   ```

   Un BOM (`EF BB BF`) al inicio del `.jspf` también lo arregla, pero se pierde
   al editar el archivo: preferir `web.xml`.
7. **Nunca escribir dos guiones seguidos dentro de un comentario XML.** `--` está
   prohibido por la especificación en un comentario XML. Si se cuela (por ejemplo
   en un separador decorativo o al citar `"--"`), Tomcat marca el contexto como
   *no disponible* y **todo el sitio responde 404** (`The string "--" is not
   permitted within comments`). Vale para `web.xml`; los `.jspf` usan comentarios
   JSP, que no tienen esa restricción.
8. **`sessions`/work dir**: si se borra
   `C:\xampp\tomcat\work\Catalina\localhost\segundo_parcial_java` con Tomcat
   corriendo, se ve un `SEVERE FileNotFoundException SESSIONS.ser` al parar. Es
   inofensivo: borrar solo con Tomcat detenido.
9. **Avisos normales de JDBC al parar** (`registered the JDBC driver but failed to
   deregister`, hilo `mysql-cj-abandoned-connection-cleanup`): los emite Tomcat
   porque la webapp usa JDBC sin `ServletContextListener`, figura que este
   proyecto no puede usar (prohibido el Java). Tomcat los neutraliza solo; no son
   un fallo.
10. **`<sql:query var>` deja SIEMPRE un `Result` no nulo**, aunque la consulta no
    traiga filas. Por eso `not empty resX` es **siempre verdadero** y no sirve para
    saber si hay resultados: hay que preguntar `${resX.rowCount gt 0}`.
    Síntoma real del Paso 4: `banco_ideas.jsp` mostraba "Ya inició su trabajo de
    grado" a estudiantes que no tenían ningún proyecto, porque la consulta de
    `INTEGRANTES_PROYECTO` devolvía 0 filas pero el objeto seguía sin ser *empty*.
    Regla: **`empty` sobre un `var` de `<sql:query>` nunca es `true`**.
11. **`<sql:param>` es posicional respecto de cada `?`.** En
    `INSERT INTO PROYECTOS_GRADO (id_propuesta, fase_actual, titulo, estado)
     VALUES (?, 1, ?, 'EN_PROCESO')` hay **dos** `?`, así que van exactamente dos
    `<sql:param>` (los literales `1` y `'EN_PROCESO'` no consumen parámetros). Un
    `<sql:param>` de más desplaza todo y se insertan valores cruzados sin error
    visible.
12. **Las columnas `BOOLEAN` llegan como `java.lang.Boolean`, no como 0/1.** En EL
    no se pueden comparar con números: `${m.es_lider eq 1}` lanza
    `javax.el.ELException: No puedo convertir [true] desde tipo
    [class java.lang.Boolean] a [class java.lang.Long]` y la página responde
    **500**. Afecta a `INTEGRANTES_PROYECTO.es_lider` y
    `USUARIOS.estado_activo`. Regla: usarlos como valor lógico
    (`${m.es_lider}` / `${not u.estado_activo}`). En **SQL** sí se escribe
    `es_lider = 1` sin problema: la restricción es solo de EL.
13. **Una etiqueta JSTL no puede ir dentro del atributo de otra etiqueta JSP.**
    `<c:out value="<c:if test='...'>x</c:if>" />` **no compila**: los atributos
    de una etiqueta JSP los analiza el motor JSP, no la plantilla.
    En cambio, dentro de un **atributo HTML** sí funciona, porque JSP no
    analiza HTML: se comprobó que
    `<span class="badge <c:choose>...</c:choose>">` y
    `<option value="X" <c:if test="...">selected</c:if>>` generan
    `<span class="badge bg-primary">` y `<option value="X" selected>`
    (HTTP 200). Aun así **se prefiere** calcular el valor con `<c:set>` +
    `<c:choose>` e interpolarlo (`class="badge ${clase}"`): se lee mejor, el
    editor no se confunde y no depende de cómo se trocee el texto.
14. **Las columnas `DATETIME` llegan como `java.time.LocalDateTime`, no como
    `java.util.Date`.** `<fmt:formatDate>` sobre
    `SUSTENTACIONES.fecha_hora_programada` (que es `DATETIME`) lanza
    `ELException: No puedo convertir [2026-12-10T09:00] desde tipo
    [class java.time.LocalDateTime] a [class java.util.Date]` y la página
    responde **500**. Las columnas `TIMESTAMP` sí funcionan (llegan como
    `java.sql.Timestamp`, que hereda de `java.util.Date`), por eso el problema
    no apareció hasta el Paso 8. Solución: formatear en SQL con
    `DATE_FORMAT(columna, '%d/%m/%Y %H:%i') AS fecha_texto` y pintar con
    `<c:out>`; para un `input type="datetime-local"` use
    `DATE_FORMAT(columna, '%Y-%m-%dT%H:%i')`.
15. **En EL el signo `+` es SUMA, no concatenación de texto.**
    `'<c:param value="fase ${x}">'` con algo como
    `${cond ? '(avanzó a ' + nuevaFase + ')' : '...'}` lanza
    `java.lang.NumberFormatException: For input string: "(fase avanzó a"`
    y la página responde **500**. Para armar un mensaje con una variable:
    `<c:set var="msg" value="La fase avanzó a la ${nuevaFase}." />` y luego
    `<c:param name="msg" value="${msg}" />`. Regla general: en EL solo se
    interpola con `${...}`; la concatenación se hace poniendo las
    expresiones dentro de un mismo literal de texto.
16. **`<c:redirect url="pagina.jsp?msg=texto con tildes">`**: mejor
    `<c:redirect url="pagina.jsp"><c:param name="msg" value="${...}" /></c:redirect>`.
    El `c:param` codifica el valor (tildes, `%`, `&`) y evita URLs rotas;
    además el `<c:redirect>` con `url` + `c:param` no obliga a escapar la
    query a mano.

## 7. Base de datos

`db/script1.sql` crea la base `uts_trabajos_grado` y 17 tablas
(`ROLES`, `USUARIOS`, `PROGRAMAS_ACADEMICOS`, `ESTUDIANTES_PERFIL`,
`DOCENTES_PERFIL`, `PROPUESTAS_PROYECTO`, `FASES_CICLO`, `PROYECTOS_GRADO`,
`INTEGRANTES_PROYECTO`, `PAGOS_PROYECTO`, `ASIGNACIONES_DOCENTES`,
`ENTREGABLES`, `REVISIONES_ENTREGABLE`, `SOLICITUDES_CAMBIO_DOCENTE`,
`SOLICITUDES_EXONERACION_SABER`, `SOLICITUDES_PRORROGA`, `SUSTENTACIONES`) e
inserta las 6 fases del ciclo. Los `INSERT` de usuarios/programas están
**comentados** al final del script (el archivo no se ha modificado).

**Estado de la BD (ya cargada en el MariaDB local):** esquema creado + datos
semilla insertados a mano, con clave `uts2026` para todos:

| id | correo | rol | nivel / especialidad |
| -- | ------ | --- | -------------------- |
| 1 | `jsantiago@correo.uts.edu.co` | ESTUDIANTE | INGENIERIA (`ST-1001`) |
| 2 | `cperez@correo.uts.edu.co` | ESTUDIANTE | INGENIERIA (`ST-1002`) |
| 3 | `director@correo.uts.edu.co` | DOCENTE | Desarrollo Web & Software |
| 4 | `evaluador@correo.uts.edu.co` | DOCENTE | Bases de Datos & Redes |
| 5 | `comite@correo.uts.edu.co` | COMITE | — |
| 6 | `atecnologa@correo.uts.edu.co` | ESTUDIANTE | TECNOLOGIA (`ST-1003`) |
| 7 | `sramirez@correo.uts.edu.co` | ESTUDIANTE | TECNOLOGIA (`ST-1004`) |
| 8 | `admin@correo.uts.edu.co` | ADMINISTRADOR | — |

El usuario 8 se agregó para el panel de administración y también lo crea
`db/seed_minimo_clevercloud.sql` con la clave `uts2026`. No necesita perfil de
estudiante ni de docente.

El usuario 6 **no venía** en `script1.sql`: se añadió para poder demostrar RF-02
en los dos niveles (`TECNOLOGIA` e `INGENIERIA`), porque los dos estudiantes
originales son de ingeniería. Está avisado en el resumen de la sesión.

El usuario 7 **tampoco** venía: se añadió en el Paso 7 para tener un estudiante
**sin proyecto** (los tres anteriores ya están en uno, y `UNIQUE(id_estudiante)`
impide vincularlos a otro), necesario para demostrar el estado vacío de
`solicitudes_estudiante.jsp`. Lo siembra la sección `0` de `test_paso7.ps1`.

**Propuestas semilla del Paso 4** (cargadas desde
`%TEMP%\opencode\seed_paso4.sql`; el banco estaba vacío, 0 filas):

| id | nivel | estado | creador | título (resumen) |
| -- | ----- | ------ | ------- | ---------------- |
| 1 | INGENIERIA | DISPONIBLE | 3 (director) | Gestión de consultorios jurídicos |
| 2 | INGENIERIA | SELECCIONADA | 4 (evaluador) | Analítica de datos de egresados |
| 3 | TECNOLOGIA | DISPONIBLE | 3 (director) | Inventario del laboratorio de electrónica |
| 4 | TECNOLOGIA | DISPONIBLE | 4 (evaluador) | Asistencia por código QR |

**Estado tras el Paso 5** (la suite `test_paso5.ps1` hace su propio reset y deja
este escenario, útil para demostrar):

| proyecto | fase | integrantes | pago | propuesta |
| -------- | ---- | ----------- | ---- | --------- |
| `cperez` | **2** | `cperez` (líder) + `jsantiago` (dupla) | APROBADO | 2 → SELECCIONADA |
| `atecnologa` | **1** | `atecnologa` (individual) | PENDIENTE | idea propia (RF-09) → SELECCIONADA |

> Los `id_proyecto` **no** son fijos: cada corrida de la suite borra y vuelve a
> insertar, así que el `AUTO_INCREMENT` avanza. Las aserciones no deben
> referenciar ids concretos, sino el correo del estudiante o el título.

Así `comite_fase1.jsp` tiene un proyecto pendiente de aprobar y otro ya
en Fase 2. Las propuestas 1, 3 y 4 siguen `DISPONIBLE` para una demostración
nueva de RF-05/RF-07. Ojo: `cperez`, `jsantiago` y `atecnologa` ya están en un
proyecto y `INTEGRANTES_PROYECTO` tiene `UNIQUE (id_estudiante)`, así que no
pueden iniciar otro; para reiniciar la demostración hay que borrar todas las
tablas dependientes en orden: `REVISIONES_ENTREGABLE`, `ENTREGABLES`,
`SUSTENTACIONES`, `SOLICITUDES_CAMBIO_DOCENTE`, `SOLICITUDES_PRORROGA`,
`SOLICITUDES_EXONERACION_SABER`, `ASIGNACIONES_DOCENTES`, `INTEGRANTES_PROYECTO`,
`PROYECTOS_GRADO`, `PAGOS_PROYECTO` y las propuestas creadas por estudiantes
(esto último lo hace la sección `0` de la suite).

**Cadena de escenarios de las suites** (cada suite deja el estado del paso que
prueba, y al ejecutar la siguiente se pisa el anterior):

| suite | deja |
| ----- | ---- |
| `test_paso5.ps1` | `cperez` + `jsantiago` en Fase 2 (pago APROBADO); `atecnologa` en Fase 1 (pago PENDIENTE) |
| `test_paso7.ps1` | `cperez` en Fase 4 `EXONERADO` (con las tres solicitudes dictaminadas); `atecnologa` en Fase 1 `EN_PROCESO` |
| `test_paso8.ps1` | `atecnologa` en Fase 6 `APROBADO` con sustentación programada (10/12/2026 09:00, «Sala de Juntas»); `cperez` en Fase 4 `EXONERADO` |
| `test_paso9.ps1` | `jsantiago` en Fase 3 (después del flujo jerárquico completo); evaluador revelado en Fase 6 |

Así, `test_paso7` exige el escenario del Paso 5 y `test_paso8` el del Paso 7
(cada uno fija fases y asignaciones en su sección `0`, pero necesita que los
proyectos y sus integrantes existan). `test_paso9` requiere el escenario del
Paso 5 y demuestra el flujo jerárquico completo de revisión.

**`seleccionar_propuesta.jsp` es solo un redirect de compatibilidad** (Paso 5).
El botón «Seleccionar Idea» de `banco_ideas.jsp` enlaza directo a
`fase1_registro.jsp?id_propuesta=N`, porque la selección debe pasar por el
registro del soporte de pago (RF-08). El archivo se conservó para que los
enlaces o marcadores antiguos sigan funcionando, pero ya **no escribe en la
base de datos**: `id_propuesta` presente → `fase1_registro.jsp`, ausente →
`banco_ideas.jsp?error=...`. Antes del Paso 5 creaba un proyecto en Fase 1 sin
comprobante (saltándose la verificación del comité), y ese era el agujero que
este redirect cierra.

Notas de esquema a respetar:

- Contraseñas: columna `contrasena_hash VARCHAR(255)` (los datos semilla usan
  texto plano `uts2026`; no hay hashing real ni POJOs para comparar hashes).
  Comparación directa `u.contrasena_hash = ?` — es una limitación aceptada del
  parcial, no un olvido.
- `REVISIONES_ENTREGABLE.string_revisor` es un `ENUM` con un nombre engañoso
  (`DIRECTOR | EVALUADOR | COMITE`), no un texto libre.
- Estados y niveles son `ENUM` en mayúsculas: usar exactamente
  `'TECNOLOGIA'`, `'INGENIERIA'`, `'DISPONIBLE'`, `'EN_PROCESO'`, etc.
- Las tildes del `ENUM`/columna no existen: los valores de BD van sin tilde y la
  tilde se pone solo al **mostrar** (con `<c:choose>` en la vista).
- `PROPUESTAS_PROYECTO.estado` es `ENUM('DISPONIBLE','SELECCIONADA')` con
  `DEFAULT 'DISPONIBLE'`; `nivel_destinatario` es `ENUM('TECNOLOGIA','INGENIERIA')`.
  Cualquier otro valor produce error de SQL, por eso `guardar_propuesta.jsp`
  valida contra una lista blanca antes del `INSERT`.
- `PROYECTOS_GRADO.fase_actual` es FK a `FASES_CICLO.numero_fase`: insertar `1`
  exige que la fase 1 exista (las 6 fases vienen en `script1.sql`).
- `INTEGRANTES_PROYECTO` tiene `UNIQUE (id_estudiante)`: un estudiante solo puede
  vincularse a **un** proyecto. Es la red de seguridad de RF-07, pero las vistas
  comprueban antes con un `SELECT` para no mostrar una selección imposible.
- **`LAST_INSERT_ID()` no es fiable entre dos etiquetas `<sql:>`**: cada etiqueta
  toma su propia conexión del pool, así que el id generado en el `INSERT` se
  pierde. Para vincular el proyecto recién creado se consulta
  `SELECT MAX(g.id_proyecto) ... WHERE g.id_propuesta = ?` envuelto en tabla
  derivada (trampa 5).
- **`PAGOS_PROYECTO` no tiene `id_proyecto`**: solo `id_estudiante`, `tipo_pago`
  (`DERECHOS_GRADO` / `PRORROGA`), `ruta_comprobante_pdf`, `estado_pago`
  (`PENDIENTE` / `APROBADO` / `RECHAZADO`). Se une con el proyecto **por el
  estudiante líder** (`INTEGRANTES_PROYECTO.es_lider` + `UNIQUE(id_estudiante)`),
  que identifica al proyecto sin ambigüedad. Al listar, usar
  `MAX(id_pago)` por estudiante para no duplicar filas.
  Esto permite insertar el pago **antes** del proyecto (el enunciado del Paso 5
  lo pide así) sin violar ninguna FK.
- **`PROYECTOS_GRADO` no tiene columna de descripción.** Para no perder el texto
  de RF-09, la idea propia se guarda primero como fila de
  `PROPUESTAS_PROYECTO` (creador = el estudiante, `nivel_destinatario` = su nivel,
  `estado` = `SELECCIONADA`) y el proyecto apunta a ella con `id_propuesta`
  (paso 0 de `fase1_procesar.jsp`).
- `INTEGRANTES_PROYECTO.es_lider` es `BOOLEAN`: ver trampa 12 antes de
  compararlo en EL.
- **`SOLICITUDES_PRORROGA.id_pago` es `NOT NULL` con FK a `PAGOS_PROYECTO`**: la
  ruta del comprobante no se guarda en la solicitud. Hay que insertar primero el
  pago (`tipo_pago = 'PRORROGA'`, `estado_pago = 'PENDIENTE'`) y usar su id.
- **`SOLICITUDES_CAMBIO_DOCENTE` guarda `id_docente_actual` + `subrol_afectado`**,
  no la asignación: por eso el formulario envía `id_asignacion` y el proceso
  relee la fila de `ASIGNACIONES_DOCENTES` para derivar ambos valores (y así no
  se puede enviar un docente que no esté asignado al proyecto).
- **`PROYECTOS_GRADO.estado` admite `CANCELADO` y `EXONERADO`** (además de
  `EN_PROCESO`, `APROBADO`, `RECHAZADO`). Toda consulta que liste "pendientes"
  debe filtrar `estado = 'EN_PROCESO'`; si no, un proyecto cancelado sigue
  apareciendo como pendiente (así estaba `comite_fase1.jsp` hasta el Paso 7).
- **`ASIGNACIONES_DOCENTES` puede estar vacía**: ningún paso anterior la
  llenaba. La sección `0` de `test_paso7.ps1` siembra director (usuario 3) y
  evaluador (usuario 4) para los proyectos de demostración, porque sin
  asignaciones el formulario de cambio de docente no tiene "docente afectado"
  que ofrecer.
- **`SUSTENTACIONES`** solo tiene `id_proyecto`, `lugar_salon` (`VARCHAR(100)`) y
  `fecha_hora_programada` (`DATETIME`, ver trampa 14). **No** tiene estado ni
  `UNIQUE (id_proyecto)`: `programar_sustentacion.jsp` comprueba si ya existe
  para el proyecto y hace `UPDATE` (reprogramar) o `INSERT`. El "aprobado" del
  proyecto vive en `PROYECTOS_GRADO.estado`.

## 8. Cómo verificar los cambios (obligatorio antes de dar algo por terminado)

Nunca entregar un JSP sin haberlo compilado y pedido por HTTP.

1. **Servicios**: pedir al usuario que arranque Tomcat (y MySQL); el agente no los
   levanta (ver 3.1). Confirmar antes con `Test-NetConnection localhost -Port 8080`
   y `-Port 3306`.
2. **Páginas con sesión**: usar un *cookie jar* de curl, nunca `Invoke-WebRequest`
   con redirecciones automáticas (oculta el 302 del RBAC):

   ```powershell
   $base = "http://localhost:8080/segundo_parcial_java"
   # login (guarda la cookie)
   curl.exe -s -o "$env:TEMP\o.html" -D "$env:TEMP\o.hdr" -c "$env:TEMP\ck.txt" -b "$env:TEMP\ck.txt" `
     -X POST -d "correo=jsantiago@correo.uts.edu.co&contrasena=uts2026" "$base/validar_login.jsp"
   # página protegida
   curl.exe -s -o "$env:TEMP\p.html" -c "$env:TEMP\ck.txt" -b "$env:TEMP\ck.txt" "$base/dashboard.jsp"
   ```

3. **Qué mirar**: `HTTP/1.1 302` + `Location` correcto en las páginas de proceso;
   `200` y el contenido esperado en las vistas; `JasperException` o
   `Estado HTTP 500` en el cuerpo = fallo real.
4. **Codificación**: comprobar a nivel de bytes que **no** aparezca el par
   `C3 83` (firma de UTF-8 doble codificado). Comparar texto acentuado contra
   bytes, no contra literales de la consola (PowerShell 5.1 lee los `.ps1` sin BOM
   como CP1252 y muestra los acentos como `�`, lo que genera falsos negativos).

   Para los acentos **guardados en la BD**, la fuente de verdad es `HEX()`: la
   consola puede devolver el texto en CP850 (`ó` = `A2`) y hacer creer que el dato
   está corrupto. Ejemplo:
   ```powershell
   mysql -u root --default-character-set=utf8mb4 -N -B -e `
     "SELECT HEX(titulo) FROM uts_trabajos_grado.PROPUESTAS_PROYECTO WHERE id_propuesta=1"
   # esperado: ...69C3B36E...  (C3B3 = ó en UTF-8)
   ```
   Complemento: una aserción `-match 'programación'` sobre un `SELECT` que no
   incluye esa columna falla siempre; revisar la lista de columnas antes de
   culpar a la codificación.
5. **`c:redirect` con `Location` relativo**: `login.jsp?error=...` **no** es una
   URL válida para curl; hay que prefijar el contexto antes de repetir la petición.
   Además, si la petición va **sin cookie**, Tomcat reescribe la URL y el
   `Location` sale como `login.jsp;jsessionid=XXXX?error=...`: el `;jsessionid`
   va **antes** del `?`. Las aserciones deben tolerarlo
   (`login\.jsp(;jsessionid=\w+)?\?error`).
6. Al terminar: borrar los JSP de prueba, dejar los servicios como los puso el
   usuario y no borrar `work/Catalina/localhost/segundo_parcial_java` con Tomcat
   corriendo (trampa 8).

Suites automatizadas reutilizables (viven en `%TEMP%\opencode\`):

- `test_paso3.ps1` — 64 comprobaciones: login, RBAC, dashboard por rol, logout.
- `test_paso4.ps1` — 81 comprobaciones: banco de propuestas, RF-04 a RF-07,
  validaciones y regresión del Paso 3.
- `test_paso5.ps1` — 92 comprobaciones: Fase 1 (RF-08 y RF-09), duplas,
  `mi_proyecto.jsp`, `comite_fase1.jsp`, aprobación de pago y regresión.
- `test_paso7.ps1` — 91 comprobaciones: RF-23 a RF-29, validaciones, dictamen
  del comité, y regresión. **Requiere el escenario del Paso 5** (si la BD está
  vacía, ejecutar antes `test_paso5.ps1`); su sección `0` resetea solicitudes,
  pagos de prórroga, fases y asignaciones de docente, así que es idempotente.
- `test_paso8.ps1` — 82 comprobaciones: RF-16, RF-11, RF-30 y RF-32 a RF-35,
  menú por rol, filtros de los informes y regresión. **Requiere el escenario del
  Paso 7**; su sección `0` fija un proyecto en Fase 6 y otro en Fase 4, borra
  las sustentaciones y normaliza las asignaciones, así que es idempotente.
- `test_paso9.ps1` — 58 comprobaciones: RF-10 a RF-16 (asignación de docentes,
  subida de entregables, revisión jerárquica director → evaluador → comité,
  avance de fase y anonimato del evaluador). **Requiere el escenario del Paso 5**;
  su sección `0` borra entregables, revisiones, solicitudes y asignaciones, y
  fija ambos proyectos en Fase 2 `EN_PROCESO`.
- `test_e2e.ps1` — 37 comprobaciones: **recorrido completo de punta a punta** con
  un proyecto nuevo de `sramirez` (ST-1004): docente publica propuesta →
  estudiante la ve en el banco y la selecciona → pago → comité aprueba Fase 1 →
  asigna docentes → 4 ciclos de entregable (Fases 2 a 5) → Fase 6 y estado
  `APROBADO` → comité programa la sustentación. Su sección `0` limpia el
  proyecto previo de `sramirez` y la propuesta «E2E Ciclo Integral», así que es
  repetible. **Deja a `sramirez` con un proyecto en Fase 6**, por lo que después
  hay que re-ejecutarlo (o limpiar) antes de usar a ese estudiante como libre.
- **Panel admin**: no tiene suite `.ps1` propia. Se verificó manualmente con
  `curl` y `mysql` el 2026-10-20: login del admin, `dashboard_admin.jsp`,
  `admin_usuarios.jsp`, creación/edición/activación/clave, cambio de rol,
  bloqueo de rol con proyecto, suplantación de estudiante y docente, regreso con
  `admin_volver.jsp`, y bloqueo de acceso para un estudiante. Los usuarios y
  proyectos de prueba se eliminaron al terminar.

Todas hay que **re-guardarlas con BOM UTF-8** antes de `powershell -File`
(PowerShell 5.1 lee sin BOM como CP1252). `test_paso4.ps1` y `test_paso5.ps1`
traen una sección `0` que **resetea el estado** de la BD en orden correcto
(borra `REVISIONES_ENTREGABLE`, `ENTREGABLES`, `SUSTENTACIONES`, todas las
tablas de solicitudes, `ASIGNACIONES_DOCENTES`, `INTEGRANTES_PROYECTO`,
`PROYECTOS_GRADO`, `PAGOS_PROYECTO` y las propuestas creadas por estudiantes,
devuelve las propuestas a `DISPONIBLE`), así que se pueden repetir sin dejar
basura.

> El BOM se agrega **anteponiendo los bytes `EF BB BF`**, nunca re-codificando el
> archivo: si se lee un `.ps1` UTF-8 como CP1252 y se vuelve a escribir, los
> acentos dentro de los literales quedan dobles (`Líder` → `LÃ­der`) y las
> aserciones con acento fallan sin motivo.

Diagnóstico rápido:

- `Communications link failure` en el stacktrace = **MySQL/MariaDB caído**, no un
  fallo del JSP.
- 404 en **todo** el sitio + `SEVERE ... parseWebXml` = `web.xml` mal formado
  (trampa 7).
- `Date.toString()` (`Sun Oct 18 ... 2026`) donde debía ir una fecha = trampa 2.

## 9. Convenciones de trabajo

- **Texto en español con tildes correctas y codificación UTF-8** (decisión
  explícita del usuario en el Paso 3). El proyecto migró desde la convención
  heredada "sin tildes"; ya no se mezcla: las vistas nuevas van con tildes y los
  `.jspf` también. La codificación la garantiza `WEB-INF/web.xml`.
- Respetar el estilo y los comentarios institucionales de los `.jspf` (encabezado
  de bloque, secciones numeradas).
- Idiomas: código y comentarios en español, sin mezclar inglés.
- Un archivo por vista; nada de lógica compartida duplicada: lo común va en
  `WEB-INF/jspf/`.
- Sin lógica Java embebida: si algo "necesita" un scriptlet, buscar el
  equivalente JSTL/EL (`<c:choose>`, `<c:set>`, `fn:`, `<jsp:useBean>`).
- Los valores que vienen de la BD en comparaciones (`${u.rol eq 'ESTUDIANTE'}`)
  van **sin tilde y en mayúsculas**, exactamente como están en el `ENUM`.
