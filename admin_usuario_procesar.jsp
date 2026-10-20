<%--
    =====================================================================
    admin_usuario_procesar.jsp  -  Unidades Tecnológicas de Santander (UTS)
    Sistema de Gestión de Trabajos de Grado
    ---------------------------------------------------------------------
    Página de PROCESO del módulo de usuarios. No genera HTML.

    Acciones:
      crear       -> INSERT en USUARIOS + perfil según el rol.
      actualizar  -> UPDATE de datos, rol, estado, clave y perfil.
      toggle      -> activa o desactiva una cuenta.
      reset_clave -> restablece la clave a uts2026.

    Reglas:
      * Solo el ADMINISTRADOR real puede ejecutar estas acciones.
      * No se permite desactivar ni cambiar el rol de la propia cuenta.
      * No se cambia el rol de un usuario con proyecto o asignaciones:
        primero debe resolverse su situación académica.
      * No hay transacciones en JSTL; se valida todo antes de escribir.
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
        <c:param name="error" value="Debe iniciar sesión para administrar usuarios." />
    </c:redirect>
</c:if>

<c:if test="${sessionScope.usuario.rol ne 'ADMINISTRADOR' or not empty sessionScope.adminOriginal}">
    <c:redirect url="dashboard.jsp">
        <c:param name="error" value="La gestión de usuarios es exclusiva del rol ADMINISTRADOR." />
    </c:redirect>
</c:if>

<c:set var="accion" value="${param.accion}" />
<c:set var="error" value="" />
<c:set var="mensaje" value="" />

<%-- =========================================================
     2) CREAR / ACTUALIZAR USUARIO
     ========================================================= --%>
<c:if test="${accion eq 'crear' or accion eq 'actualizar'}">

    <c:set var="idUsuario" value="${fn:trim(param.id_usuario)}" />
    <c:set var="documento" value="${fn:trim(param.documento_identidad)}" />
    <c:set var="nombres" value="${fn:trim(param.nombres)}" />
    <c:set var="apellidos" value="${fn:trim(param.apellidos)}" />
    <c:set var="correo" value="${fn:trim(param.correo_institucional)}" />
    <c:set var="rol" value="${fn:trim(param.rol)}" />
    <c:set var="estado" value="${param.estado}" />
    <c:set var="idPrograma" value="${fn:trim(param.id_programa)}" />
    <c:set var="codigo" value="${fn:trim(param.codigo_estudiantil)}" />
    <c:set var="especialidad" value="${fn:trim(param.especialidad)}" />
    <c:set var="esEvaluador" value="${param.es_evaluador eq '1' ? 1 : 0}" />
    <c:set var="contrasena" value="${param.contrasena}" />

    <c:if test="${estado ne '1' and estado ne '0'}">
        <c:set var="estado" value="1" />
    </c:if>

    <%-- ---------- 2.a) Validaciones generales ---------- --%>
    <c:if test="${accion eq 'actualizar' and empty idUsuario}">
        <c:set var="error" value="No se recibió el usuario a actualizar." />
    </c:if>

    <c:if test="${empty error and (empty documento or empty nombres or empty apellidos or empty correo or empty rol)}">
        <c:set var="error" value="Complete documento, nombres, apellidos, correo y rol." />
    </c:if>

    <c:if test="${empty error and (fn:length(documento) gt 20 or fn:length(nombres) gt 100
                                   or fn:length(apellidos) gt 100 or fn:length(correo) gt 100)}">
        <c:set var="error" value="Alguno de los datos supera la longitud permitida." />
    </c:if>

    <c:if test="${empty error and (not fn:contains(correo, '@') or not fn:contains(correo, '.'))}">
        <c:set var="error" value="El correo institucional no tiene un formato válido." />
    </c:if>

    <c:if test="${empty error and rol ne 'ESTUDIANTE' and rol ne 'DOCENTE'
                  and rol ne 'COMITE' and rol ne 'ADMINISTRADOR'}">
        <c:set var="error" value="El rol seleccionado no es válido." />
    </c:if>

    <c:if test="${empty error and accion eq 'crear' and empty contrasena}">
        <c:set var="error" value="Debe indicar una contraseña para el usuario nuevo." />
    </c:if>

    <c:if test="${empty error and fn:length(contrasena) gt 255}">
        <c:set var="error" value="La contraseña supera la longitud permitida." />
    </c:if>

    <%-- ---------- 2.b) Validaciones del perfil ---------- --%>
    <c:if test="${empty error and rol eq 'ESTUDIANTE'}">
        <c:if test="${empty idPrograma or empty codigo}">
            <c:set var="error" value="Para un estudiante debe indicar programa académico y código estudiantil." />
        </c:if>
        <c:if test="${empty error and fn:length(codigo) gt 20}">
            <c:set var="error" value="El código estudiantil supera los 20 caracteres." />
        </c:if>
        <c:if test="${empty error}">
            <c:set var="errorPrograma" value="" />
            <c:catch var="errorPrograma">
                <sql:query var="resPrograma" dataSource="${db}">
                    SELECT COUNT(*) AS total
                      FROM PROGRAMAS_ACADEMICOS
                     WHERE id_programa = ?
                    <sql:param value="${idPrograma}" />
                </sql:query>
            </c:catch>
            <c:if test="${not empty errorPrograma or resPrograma.rows[0].total eq 0}">
                <c:set var="error" value="El programa académico seleccionado no existe." />
            </c:if>
        </c:if>
    </c:if>

    <c:if test="${empty error and rol eq 'DOCENTE' and empty especialidad}">
        <c:set var="error" value="Para un docente debe indicar la especialidad." />
    </c:if>

    <c:if test="${empty error and rol eq 'DOCENTE' and fn:length(especialidad) gt 150}">
        <c:set var="error" value="La especialidad supera los 150 caracteres." />
    </c:if>

    <%-- ---------- 2.c) Unicidad de correo y documento ---------- --%>
    <c:set var="idExcluir" value="${empty idUsuario ? 0 : idUsuario}" />

    <c:if test="${empty error}">
        <c:set var="errorUnico" value="" />
        <c:catch var="errorUnico">
            <sql:query var="resUnico" dataSource="${db}">
                SELECT COUNT(*) AS total
                  FROM USUARIOS
                 WHERE (correo_institucional = ? OR documento_identidad = ?)
                   AND id_usuario <> ?
                <sql:param value="${correo}" />
                <sql:param value="${documento}" />
                <sql:param value="${idExcluir}" />
            </sql:query>
        </c:catch>
        <c:choose>
            <c:when test="${not empty errorUnico}">
                <c:set var="error" value="No fue posible validar el correo y el documento." />
            </c:when>
            <c:when test="${resUnico.rows[0].total gt 0}">
                <c:set var="error" value="Ya existe otro usuario con ese correo o documento." />
            </c:when>
        </c:choose>
    </c:if>

    <%-- ---------- 2.d) Unicidad del código estudiantil ---------- --%>
    <c:if test="${empty error and rol eq 'ESTUDIANTE'}">
        <c:set var="errorCodigo" value="" />
        <c:catch var="errorCodigo">
            <sql:query var="resCodigo" dataSource="${db}">
                SELECT COUNT(*) AS total
                  FROM ESTUDIANTES_PERFIL
                 WHERE codigo_estudiantil = ?
                   AND id_estudiante <> ?
                <sql:param value="${codigo}" />
                <sql:param value="${idExcluir}" />
            </sql:query>
        </c:catch>
        <c:choose>
            <c:when test="${not empty errorCodigo}">
                <c:set var="error" value="No fue posible validar el código estudiantil." />
            </c:when>
            <c:when test="${resCodigo.rows[0].total gt 0}">
                <c:set var="error" value="Ya existe otro estudiante con ese código." />
            </c:when>
        </c:choose>
    </c:if>

    <%-- ---------- 2.e) Usuario actual, para cambios de rol ---------- --%>
    <c:set var="rolAnterior" value="" />
    <c:set var="proyectosUsuario" value="0" />
    <c:set var="asignacionesUsuario" value="0" />

    <c:if test="${accion eq 'actualizar' and empty error}">
        <c:set var="errorActual" value="" />
        <c:catch var="errorActual">
            <sql:query var="resActual" dataSource="${db}">
                SELECT t.*
                  FROM (
                      SELECT u.id_usuario,
                             r.nombre AS rol,
                             (SELECT COUNT(*) FROM INTEGRANTES_PROYECTO i
                               WHERE i.id_estudiante = u.id_usuario) AS proyectos,
                             (SELECT COUNT(*) FROM ASIGNACIONES_DOCENTES a
                               WHERE a.id_docente = u.id_usuario) AS asignaciones
                        FROM USUARIOS u
                             INNER JOIN ROLES r ON r.id_rol = u.id_rol
                       WHERE u.id_usuario = ?
                  ) t
                <sql:param value="${idUsuario}" />
            </sql:query>
        </c:catch>

        <c:choose>
            <c:when test="${not empty errorActual}">
                <c:set var="error" value="No fue posible consultar el usuario a actualizar." />
            </c:when>
            <c:when test="${empty resActual or resActual.rowCount eq 0}">
                <c:set var="error" value="El usuario a actualizar no existe." />
            </c:when>
            <c:otherwise>
                <c:set var="rolAnterior" value="${resActual.rows[0].rol}" />
                <c:set var="proyectosUsuario" value="${resActual.rows[0].proyectos}" />
                <c:set var="asignacionesUsuario" value="${resActual.rows[0].asignaciones}" />
            </c:otherwise>
        </c:choose>
    </c:if>

    <%-- ---------- 2.f) Protecciones de la propia cuenta ---------- --%>
    <c:if test="${empty error and accion eq 'actualizar'
                  and idUsuario eq sessionScope.usuario.id_usuario}">
        <c:if test="${rolAnterior ne rol}">
            <c:set var="error" value="No puede cambiar el rol de su propia cuenta." />
        </c:if>
        <c:if test="${empty error and estado eq '0'}">
            <c:set var="error" value="No puede desactivar su propia cuenta." />
        </c:if>
    </c:if>

    <%-- ---------- 2.g) Cambio de rol con dependencias ---------- --%>
    <c:if test="${empty error and accion eq 'actualizar' and rolAnterior ne rol
                  and (proyectosUsuario gt 0 or asignacionesUsuario gt 0)}">
        <c:set var="error" value="No puede cambiar el rol: el usuario tiene proyectos o asignaciones registradas." />
    </c:if>

    <%-- ---------- 2.h) Si hay error, volver al formulario ---------- --%>
    <c:if test="${not empty error}">
        <c:choose>
            <c:when test="${accion eq 'actualizar' and not empty idUsuario}">
                <c:redirect url="admin_usuario_form.jsp">
                    <c:param name="id_usuario" value="${idUsuario}" />
                    <c:param name="error" value="${error}" />
                </c:redirect>
            </c:when>
            <c:otherwise>
                <c:redirect url="admin_usuario_form.jsp">
                    <c:param name="error" value="${error}" />
                </c:redirect>
            </c:otherwise>
        </c:choose>
    </c:if>

    <%-- ---------- 2.i) Rol real desde la base ---------- --%>
    <c:set var="errorRol" value="" />
    <c:catch var="errorRol">
        <sql:query var="resRol" dataSource="${db}">
            SELECT id_rol FROM ROLES WHERE nombre = ?
            <sql:param value="${rol}" />
        </sql:query>
    </c:catch>

    <c:choose>
        <c:when test="${not empty errorRol or empty resRol or resRol.rowCount eq 0}">
            <c:redirect url="admin_usuario_form.jsp">
                <c:param name="error" value="No fue posible resolver el rol seleccionado." />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:set var="idRol" value="${resRol.rows[0].id_rol}" />
        </c:otherwise>
    </c:choose>

    <%-- ---------- 2.j) INSERT o UPDATE ---------- --%>
    <c:choose>

        <%-- ========== CREAR ========== --%>
        <c:when test="${accion eq 'crear'}">

            <c:set var="errorInsert" value="" />
            <c:catch var="errorInsert">
                <sql:update var="resInsert" dataSource="${db}">
                    INSERT INTO USUARIOS
                        (id_rol, documento_identidad, nombres, apellidos,
                         correo_institucional, contrasena_hash, estado_activo)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    <sql:param value="${idRol}" />
                    <sql:param value="${documento}" />
                    <sql:param value="${nombres}" />
                    <sql:param value="${apellidos}" />
                    <sql:param value="${correo}" />
                    <sql:param value="${contrasena}" />
                    <sql:param value="${estado}" />
                </sql:update>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorInsert}">
                    <c:redirect url="admin_usuario_form.jsp">
                        <c:param name="error" value="No fue posible crear el usuario. Verifique los datos e intente de nuevo." />
                    </c:redirect>
                </c:when>
                <c:otherwise>

                    <c:set var="errorNuevo" value="" />
                    <c:catch var="errorNuevo">
                        <sql:query var="resNuevo" dataSource="${db}">
                            SELECT id_usuario FROM USUARIOS WHERE correo_institucional = ?
                            <sql:param value="${correo}" />
                        </sql:query>
                    </c:catch>

                    <c:choose>
                        <c:when test="${not empty errorNuevo or empty resNuevo or resNuevo.rowCount eq 0}">
                            <c:redirect url="admin_usuarios.jsp">
                                <c:param name="error" value="El usuario se creó, pero no fue posible recuperar su identificador. Revise el listado." />
                            </c:redirect>
                        </c:when>
                        <c:otherwise>
                            <c:set var="idNuevo" value="${resNuevo.rows[0].id_usuario}" />
                        </c:otherwise>
                    </c:choose>

                    <c:set var="errorPerfil" value="" />
                    <c:catch var="errorPerfil">
                        <c:choose>
                            <c:when test="${rol eq 'ESTUDIANTE'}">
                                <sql:update dataSource="${db}">
                                    INSERT INTO ESTUDIANTES_PERFIL
                                        (id_estudiante, id_programa, codigo_estudiantil)
                                    VALUES (?, ?, ?)
                                    <sql:param value="${idNuevo}" />
                                    <sql:param value="${idPrograma}" />
                                    <sql:param value="${codigo}" />
                                </sql:update>
                            </c:when>
                            <c:when test="${rol eq 'DOCENTE'}">
                                <sql:update dataSource="${db}">
                                    INSERT INTO DOCENTES_PERFIL
                                        (id_docente, especialidad, es_evaluador)
                                    VALUES (?, ?, ?)
                                    <sql:param value="${idNuevo}" />
                                    <sql:param value="${especialidad}" />
                                    <sql:param value="${esEvaluador}" />
                                </sql:update>
                            </c:when>
                        </c:choose>
                    </c:catch>

                    <c:choose>
                        <c:when test="${not empty errorPerfil}">
                            <c:redirect url="admin_usuarios.jsp">
                                <c:param name="error" value="El usuario se creó, pero no fue posible guardar su perfil. Edítelo para completar los datos." />
                            </c:redirect>
                        </c:when>
                        <c:otherwise>
                            <c:redirect url="admin_usuarios.jsp">
                                <c:param name="msg" value="Usuario creado correctamente." />
                            </c:redirect>
                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>

        </c:when>

        <%-- ========== ACTUALIZAR ========== --%>
        <c:otherwise>

            <c:set var="errorUpdate" value="" />
            <c:catch var="errorUpdate">
                <c:choose>
                    <c:when test="${empty contrasena}">
                        <sql:update var="resUpdate" dataSource="${db}">
                            UPDATE USUARIOS
                               SET id_rol = ?,
                                   documento_identidad = ?,
                                   nombres = ?,
                                   apellidos = ?,
                                   correo_institucional = ?,
                                   estado_activo = ?
                             WHERE id_usuario = ?
                            <sql:param value="${idRol}" />
                            <sql:param value="${documento}" />
                            <sql:param value="${nombres}" />
                            <sql:param value="${apellidos}" />
                            <sql:param value="${correo}" />
                            <sql:param value="${estado}" />
                            <sql:param value="${idUsuario}" />
                        </sql:update>
                    </c:when>
                    <c:otherwise>
                        <sql:update var="resUpdate" dataSource="${db}">
                            UPDATE USUARIOS
                               SET id_rol = ?,
                                   documento_identidad = ?,
                                   nombres = ?,
                                   apellidos = ?,
                                   correo_institucional = ?,
                                   contrasena_hash = ?,
                                   estado_activo = ?
                             WHERE id_usuario = ?
                            <sql:param value="${idRol}" />
                            <sql:param value="${documento}" />
                            <sql:param value="${nombres}" />
                            <sql:param value="${apellidos}" />
                            <sql:param value="${correo}" />
                            <sql:param value="${contrasena}" />
                            <sql:param value="${estado}" />
                            <sql:param value="${idUsuario}" />
                        </sql:update>
                    </c:otherwise>
                </c:choose>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorUpdate}">
                    <c:redirect url="admin_usuario_form.jsp">
                        <c:param name="id_usuario" value="${idUsuario}" />
                        <c:param name="error" value="No fue posible actualizar el usuario. Verifique los datos e intente de nuevo." />
                    </c:redirect>
                </c:when>
                <c:otherwise>

                    <c:set var="errorPerfil" value="" />
                    <c:catch var="errorPerfil">

                        <c:choose>
                            <%-- ===== Perfil ESTUDIANTE ===== --%>
                            <c:when test="${rol eq 'ESTUDIANTE'}">

                                <sql:update var="resPerfilEst" dataSource="${db}">
                                    UPDATE ESTUDIANTES_PERFIL
                                       SET id_programa = ?,
                                           codigo_estudiantil = ?
                                     WHERE id_estudiante = ?
                                    <sql:param value="${idPrograma}" />
                                    <sql:param value="${codigo}" />
                                    <sql:param value="${idUsuario}" />
                                </sql:update>

                                <c:if test="${resPerfilEst eq 0}">
                                    <sql:update dataSource="${db}">
                                        INSERT INTO ESTUDIANTES_PERFIL
                                            (id_estudiante, id_programa, codigo_estudiantil)
                                        VALUES (?, ?, ?)
                                        <sql:param value="${idUsuario}" />
                                        <sql:param value="${idPrograma}" />
                                        <sql:param value="${codigo}" />
                                    </sql:update>
                                </c:if>

                                <c:if test="${rolAnterior ne 'ESTUDIANTE'}">
                                    <sql:update dataSource="${db}">
                                        DELETE FROM DOCENTES_PERFIL WHERE id_docente = ?
                                        <sql:param value="${idUsuario}" />
                                    </sql:update>
                                </c:if>

                            </c:when>

                            <%-- ===== Perfil DOCENTE ===== --%>
                            <c:when test="${rol eq 'DOCENTE'}">

                                <sql:update var="resPerfilDoc" dataSource="${db}">
                                    UPDATE DOCENTES_PERFIL
                                       SET especialidad = ?,
                                           es_evaluador = ?
                                     WHERE id_docente = ?
                                    <sql:param value="${especialidad}" />
                                    <sql:param value="${esEvaluador}" />
                                    <sql:param value="${idUsuario}" />
                                </sql:update>

                                <c:if test="${resPerfilDoc eq 0}">
                                    <sql:update dataSource="${db}">
                                        INSERT INTO DOCENTES_PERFIL
                                            (id_docente, especialidad, es_evaluador)
                                        VALUES (?, ?, ?)
                                        <sql:param value="${idUsuario}" />
                                        <sql:param value="${especialidad}" />
                                        <sql:param value="${esEvaluador}" />
                                    </sql:update>
                                </c:if>

                                <c:if test="${rolAnterior ne 'DOCENTE'}">
                                    <sql:update dataSource="${db}">
                                        DELETE FROM ESTUDIANTES_PERFIL WHERE id_estudiante = ?
                                        <sql:param value="${idUsuario}" />
                                    </sql:update>
                                </c:if>

                            </c:when>

                            <%-- ===== COMITE / ADMINISTRADOR ===== --%>
                            <c:otherwise>
                                <sql:update dataSource="${db}">
                                    DELETE FROM ESTUDIANTES_PERFIL WHERE id_estudiante = ?
                                    <sql:param value="${idUsuario}" />
                                </sql:update>
                                <sql:update dataSource="${db}">
                                    DELETE FROM DOCENTES_PERFIL WHERE id_docente = ?
                                    <sql:param value="${idUsuario}" />
                                </sql:update>
                            </c:otherwise>
                        </c:choose>

                    </c:catch>

                    <c:choose>
                        <c:when test="${not empty errorPerfil}">
                            <c:redirect url="admin_usuario_form.jsp">
                                <c:param name="id_usuario" value="${idUsuario}" />
                                <c:param name="error" value="Los datos de la cuenta se guardaron, pero no fue posible actualizar su perfil." />
                            </c:redirect>
                        </c:when>
                        <c:otherwise>
                            <c:redirect url="admin_usuarios.jsp">
                                <c:param name="msg" value="Usuario actualizado correctamente." />
                            </c:redirect>
                        </c:otherwise>
                    </c:choose>

                </c:otherwise>
            </c:choose>

        </c:otherwise>

    </c:choose>

</c:if>

<%-- =========================================================
     3) ACTIVAR / DESACTIVAR
     ========================================================= --%>
<c:if test="${accion eq 'toggle'}">

    <c:set var="idUsuario" value="${fn:trim(param.id_usuario)}" />

    <c:choose>
        <c:when test="${empty idUsuario}">
            <c:redirect url="admin_usuarios.jsp">
                <c:param name="error" value="No se recibió el usuario a activar o desactivar." />
            </c:redirect>
        </c:when>
        <c:when test="${idUsuario eq sessionScope.usuario.id_usuario}">
            <c:redirect url="admin_usuarios.jsp">
                <c:param name="error" value="No puede desactivar su propia cuenta." />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:set var="errorToggle" value="" />
            <c:catch var="errorToggle">
                <sql:update var="resToggle" dataSource="${db}">
                    UPDATE USUARIOS
                       SET estado_activo = NOT estado_activo
                     WHERE id_usuario = ?
                    <sql:param value="${idUsuario}" />
                </sql:update>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorToggle}">
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="error" value="No fue posible cambiar el estado del usuario." />
                    </c:redirect>
                </c:when>
                <c:when test="${resToggle eq 0}">
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="error" value="El usuario no existe." />
                    </c:redirect>
                </c:when>
                <c:otherwise>
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="msg" value="Estado del usuario actualizado." />
                    </c:redirect>
                </c:otherwise>
            </c:choose>
        </c:otherwise>
    </c:choose>

</c:if>

<%-- =========================================================
     4) RESTABLECER CLAVE
     ========================================================= --%>
<c:if test="${accion eq 'reset_clave'}">

    <c:set var="idUsuario" value="${fn:trim(param.id_usuario)}" />

    <c:choose>
        <c:when test="${empty idUsuario}">
            <c:redirect url="admin_usuarios.jsp">
                <c:param name="error" value="No se recibió el usuario para restablecer la clave." />
            </c:redirect>
        </c:when>
        <c:otherwise>
            <c:set var="errorReset" value="" />
            <c:catch var="errorReset">
                <sql:update var="resReset" dataSource="${db}">
                    UPDATE USUARIOS
                       SET contrasena_hash = 'uts2026'
                     WHERE id_usuario = ?
                    <sql:param value="${idUsuario}" />
                </sql:update>
            </c:catch>

            <c:choose>
                <c:when test="${not empty errorReset}">
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="error" value="No fue posible restablecer la clave." />
                    </c:redirect>
                </c:when>
                <c:when test="${resReset eq 0}">
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="error" value="El usuario no existe." />
                    </c:redirect>
                </c:when>
                <c:otherwise>
                    <c:redirect url="admin_usuarios.jsp">
                        <c:param name="msg" value="Clave restablecida a uts2026." />
                    </c:redirect>
                </c:otherwise>
            </c:choose>
        </c:otherwise>
    </c:choose>

</c:if>

<%-- =========================================================
     5) Acción no reconocida
     ========================================================= --%>
<c:if test="${empty accion or (accion ne 'crear' and accion ne 'actualizar'
                               and accion ne 'toggle' and accion ne 'reset_clave')}">
    <c:redirect url="admin_usuarios.jsp">
        <c:param name="error" value="Acción no reconocida." />
    </c:redirect>
</c:if>
