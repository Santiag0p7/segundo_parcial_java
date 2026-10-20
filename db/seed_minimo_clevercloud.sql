-- =====================================================================
-- seed_minimo_clevercloud.sql
-- Sistema de Gestión de Trabajos de Grado - UTS
-- ---------------------------------------------------------------------
-- Escenario mínimo:
--   * 1 estudiante de INGENIERIA (jsantiago)
--   * 2 docentes (director y evaluador)
--   * 1 usuario de comité
--   * 10 propuestas: 5 de TECNOLOGIA y 5 de INGENIERIA
--   * 1 proyecto en Fase 1 con pago PENDIENTE
--
-- NO incluye CREATE DATABASE ni USE: se ejecuta sobre la base ya creada.
-- Es idempotente: se puede ejecutar más de una vez sin duplicar.
-- Contraseña de todos los usuarios: uts2026
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Roles
-- ---------------------------------------------------------------------
INSERT IGNORE INTO ROLES (nombre) VALUES
('ESTUDIANTE'),
('DOCENTE'),
('COMITE'),
('ADMINISTRADOR');

SET @rol_estudiante = (SELECT id_rol FROM ROLES WHERE nombre = 'ESTUDIANTE' LIMIT 1);
SET @rol_docente    = (SELECT id_rol FROM ROLES WHERE nombre = 'DOCENTE' LIMIT 1);
SET @rol_comite     = (SELECT id_rol FROM ROLES WHERE nombre = 'COMITE' LIMIT 1);

-- ---------------------------------------------------------------------
-- 2. Programas académicos
-- ---------------------------------------------------------------------
SET @existe_prog_tec = (SELECT COUNT(*) FROM PROGRAMAS_ACADEMICOS WHERE nivel_formacion = 'TECNOLOGIA');
INSERT INTO PROGRAMAS_ACADEMICOS (nombre_programa, nivel_formacion)
SELECT 'Tecnología en Desarrollo de Sistemas de Información', 'TECNOLOGIA' FROM DUAL
WHERE @existe_prog_tec = 0;

SET @existe_prog_ing = (SELECT COUNT(*) FROM PROGRAMAS_ACADEMICOS WHERE nivel_formacion = 'INGENIERIA');
INSERT INTO PROGRAMAS_ACADEMICOS (nombre_programa, nivel_formacion)
SELECT 'Ingeniería de Sistemas', 'INGENIERIA' FROM DUAL
WHERE @existe_prog_ing = 0;

SET @prog_tec = (SELECT id_programa FROM PROGRAMAS_ACADEMICOS WHERE nivel_formacion = 'TECNOLOGIA' LIMIT 1);
SET @prog_ing = (SELECT id_programa FROM PROGRAMAS_ACADEMICOS WHERE nivel_formacion = 'INGENIERIA' LIMIT 1);

-- ---------------------------------------------------------------------
-- 3. Usuarios
-- ---------------------------------------------------------------------
SET @existe_jsantiago = (SELECT COUNT(*) FROM USUARIOS WHERE correo_institucional = 'jsantiago@correo.uts.edu.co');
INSERT INTO USUARIOS (id_rol, documento_identidad, nombres, apellidos, correo_institucional, contrasena_hash, estado_activo)
SELECT @rol_estudiante, '1001234567', 'Jhoan', 'Santiago', 'jsantiago@correo.uts.edu.co', 'uts2026', TRUE FROM DUAL
WHERE @existe_jsantiago = 0;

SET @existe_director = (SELECT COUNT(*) FROM USUARIOS WHERE correo_institucional = 'director@correo.uts.edu.co');
INSERT INTO USUARIOS (id_rol, documento_identidad, nombres, apellidos, correo_institucional, contrasena_hash, estado_activo)
SELECT @rol_docente, '91234567', 'Director', 'Docente', 'director@correo.uts.edu.co', 'uts2026', TRUE FROM DUAL
WHERE @existe_director = 0;

SET @existe_evaluador = (SELECT COUNT(*) FROM USUARIOS WHERE correo_institucional = 'evaluador@correo.uts.edu.co');
INSERT INTO USUARIOS (id_rol, documento_identidad, nombres, apellidos, correo_institucional, contrasena_hash, estado_activo)
SELECT @rol_docente, '91234568', 'Evaluador', 'Docente', 'evaluador@correo.uts.edu.co', 'uts2026', TRUE FROM DUAL
WHERE @existe_evaluador = 0;

SET @existe_comite = (SELECT COUNT(*) FROM USUARIOS WHERE correo_institucional = 'comite@correo.uts.edu.co');
INSERT INTO USUARIOS (id_rol, documento_identidad, nombres, apellidos, correo_institucional, contrasena_hash, estado_activo)
SELECT @rol_comite, '80123456', 'Comite', 'Grados', 'comite@correo.uts.edu.co', 'uts2026', TRUE FROM DUAL
WHERE @existe_comite = 0;

SET @id_jsantiago = (SELECT id_usuario FROM USUARIOS WHERE correo_institucional = 'jsantiago@correo.uts.edu.co' LIMIT 1);
SET @id_director  = (SELECT id_usuario FROM USUARIOS WHERE correo_institucional = 'director@correo.uts.edu.co' LIMIT 1);
SET @id_evaluador = (SELECT id_usuario FROM USUARIOS WHERE correo_institucional = 'evaluador@correo.uts.edu.co' LIMIT 1);
SET @id_comite    = (SELECT id_usuario FROM USUARIOS WHERE correo_institucional = 'comite@correo.uts.edu.co' LIMIT 1);

-- ---------------------------------------------------------------------
-- 4. Perfiles
-- ---------------------------------------------------------------------
SET @existe_perfil_jsantiago = (SELECT COUNT(*) FROM ESTUDIANTES_PERFIL WHERE id_estudiante = @id_jsantiago);
INSERT INTO ESTUDIANTES_PERFIL (id_estudiante, id_programa, codigo_estudiantil)
SELECT @id_jsantiago, @prog_ing, 'ST-1001' FROM DUAL
WHERE @existe_perfil_jsantiago = 0;

SET @existe_perfil_director = (SELECT COUNT(*) FROM DOCENTES_PERFIL WHERE id_docente = @id_director);
INSERT INTO DOCENTES_PERFIL (id_docente, especialidad, es_evaluador)
SELECT @id_director, 'Desarrollo Web & Software', TRUE FROM DUAL
WHERE @existe_perfil_director = 0;

SET @existe_perfil_evaluador = (SELECT COUNT(*) FROM DOCENTES_PERFIL WHERE id_docente = @id_evaluador);
INSERT INTO DOCENTES_PERFIL (id_docente, especialidad, es_evaluador)
SELECT @id_evaluador, 'Bases de Datos & Redes', TRUE FROM DUAL
WHERE @existe_perfil_evaluador = 0;

-- ---------------------------------------------------------------------
-- 5. Fases del ciclo
-- ---------------------------------------------------------------------
INSERT IGNORE INTO FASES_CICLO (numero_fase, nombre_fase) VALUES
(1, 'Fase 1: Pago y Selección/Registro de Idea'),
(2, 'Fase 2: Asignación y Entregable 1'),
(3, 'Fase 3: Entregable 2'),
(4, 'Fase 4: Entregable 3 / Exoneración Saber'),
(5, 'Fase 5: Entregable 4 (Documento Final)'),
(6, 'Fase 6: Sustentación Final');

-- ---------------------------------------------------------------------
-- 6. Propuestas: 5 de INGENIERIA y 5 de TECNOLOGIA
-- ---------------------------------------------------------------------
SET @existe_prop_1 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Plataforma web para la gestión de consultorios jurídicos');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_director, 'Plataforma web para la gestión de consultorios jurídicos', 'Sistema para registrar y hacer seguimiento a los casos atendidos en los consultorios jurídicos de la universidad.', 'INGENIERIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_1 = 0;

SET @existe_prop_2 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Módulo de analítica de datos para el observatorio de egresados');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_evaluador, 'Módulo de analítica de datos para el observatorio de egresados', 'Módulo para analizar los datos de egresados y generar indicadores para la toma de decisiones.', 'INGENIERIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_2 = 0;

SET @existe_prop_3 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Sistema de inventario para el laboratorio de electrónica');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_director, 'Sistema de inventario para el laboratorio de electrónica', 'Sistema para controlar el inventario y los préstamos de equipos del laboratorio de electrónica.', 'TECNOLOGIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_3 = 0;

SET @existe_prop_4 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Control de asistencia a prácticas formativas mediante código QR');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_evaluador, 'Control de asistencia a prácticas formativas mediante código QR', 'Aplicación para registrar la asistencia a las prácticas formativas mediante códigos QR.', 'TECNOLOGIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_4 = 0;

SET @existe_prop_5 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Sistema de gestión documental para la biblioteca');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_comite, 'Sistema de gestión documental para la biblioteca', 'Sistema para organizar y consultar los documentos académicos de la biblioteca.', 'INGENIERIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_5 = 0;

SET @existe_prop_6 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Plataforma de trazabilidad de proyectos de investigación');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_director, 'Plataforma de trazabilidad de proyectos de investigación', 'Plataforma para hacer seguimiento a los proyectos de investigación y sus productos.', 'INGENIERIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_6 = 0;

SET @existe_prop_7 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Sistema de alertas tempranas para riesgo académico');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_evaluador, 'Sistema de alertas tempranas para riesgo académico', 'Sistema que identifica estudiantes con riesgo académico y genera alertas tempranas.', 'INGENIERIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_7 = 0;

SET @existe_prop_8 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Plataforma de gestión de prácticas empresariales');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_comite, 'Plataforma de gestión de prácticas empresariales', 'Plataforma para gestionar la postulación y el seguimiento de las prácticas empresariales.', 'TECNOLOGIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_8 = 0;

SET @existe_prop_9 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Aplicación para el seguimiento de proyectos de aula');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_director, 'Aplicación para el seguimiento de proyectos de aula', 'Aplicación para que los estudiantes registren el avance de sus proyectos de aula.', 'TECNOLOGIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_9 = 0;

SET @existe_prop_10 = (SELECT COUNT(*) FROM PROPUESTAS_PROYECTO WHERE titulo = 'Sistema de reservas de salas y equipos');
INSERT INTO PROPUESTAS_PROYECTO (id_creador, titulo, descripcion, nivel_destinatario, estado)
SELECT @id_evaluador, 'Sistema de reservas de salas y equipos', 'Sistema para reservar salas, equipos y recursos de la universidad.', 'TECNOLOGIA', 'DISPONIBLE' FROM DUAL
WHERE @existe_prop_10 = 0;

-- La propuesta 1 queda seleccionada por el proyecto de jsantiago.
SET @prop_ing_1 = (SELECT id_propuesta FROM PROPUESTAS_PROYECTO WHERE titulo = 'Plataforma web para la gestión de consultorios jurídicos' LIMIT 1);
UPDATE PROPUESTAS_PROYECTO SET estado = 'SELECCIONADA' WHERE id_propuesta = @prop_ing_1;

-- ---------------------------------------------------------------------
-- 7. Proyecto en Fase 1 con pago pendiente
-- ---------------------------------------------------------------------
SET @existe_proyecto = (SELECT COUNT(*) FROM PROYECTOS_GRADO WHERE titulo = 'Plataforma web para la gestión de consultorios jurídicos');
INSERT INTO PROYECTOS_GRADO (id_propuesta, fase_actual, titulo, estado)
SELECT @prop_ing_1, 1, 'Plataforma web para la gestión de consultorios jurídicos', 'EN_PROCESO' FROM DUAL
WHERE @existe_proyecto = 0;

SET @proyecto_jsantiago = (SELECT id_proyecto FROM PROYECTOS_GRADO WHERE titulo = 'Plataforma web para la gestión de consultorios jurídicos' LIMIT 1);

SET @existe_miembro = (SELECT COUNT(*) FROM INTEGRANTES_PROYECTO WHERE id_estudiante = @id_jsantiago);
INSERT INTO INTEGRANTES_PROYECTO (id_proyecto, id_estudiante, es_lider)
SELECT @proyecto_jsantiago, @id_jsantiago, TRUE FROM DUAL
WHERE @existe_miembro = 0;

SET @existe_pago = (SELECT COUNT(*) FROM PAGOS_PROYECTO WHERE id_estudiante = @id_jsantiago AND tipo_pago = 'DERECHOS_GRADO');
INSERT INTO PAGOS_PROYECTO (id_estudiante, tipo_pago, ruta_comprobante_pdf, estado_pago)
SELECT @id_jsantiago, 'DERECHOS_GRADO', 'comprobantes/demo-pago-minimo.pdf', 'PENDIENTE' FROM DUAL
WHERE @existe_pago = 0;

-- ---------------------------------------------------------------------
-- 8. Verificación rápida
-- ---------------------------------------------------------------------
SELECT 'ROLES' AS tabla, COUNT(*) AS filas FROM ROLES
UNION ALL SELECT 'PROGRAMAS_ACADEMICOS', COUNT(*) FROM PROGRAMAS_ACADEMICOS
UNION ALL SELECT 'USUARIOS', COUNT(*) FROM USUARIOS
UNION ALL SELECT 'ESTUDIANTES_PERFIL', COUNT(*) FROM ESTUDIANTES_PERFIL
UNION ALL SELECT 'DOCENTES_PERFIL', COUNT(*) FROM DOCENTES_PERFIL
UNION ALL SELECT 'FASES_CICLO', COUNT(*) FROM FASES_CICLO
UNION ALL SELECT 'PROPUESTAS_PROYECTO', COUNT(*) FROM PROPUESTAS_PROYECTO
UNION ALL SELECT 'PROYECTOS_GRADO', COUNT(*) FROM PROYECTOS_GRADO
UNION ALL SELECT 'INTEGRANTES_PROYECTO', COUNT(*) FROM INTEGRANTES_PROYECTO
UNION ALL SELECT 'PAGOS_PROYECTO', COUNT(*) FROM PAGOS_PROYECTO;

SELECT u.correo_institucional, r.nombre AS rol
FROM USUARIOS u
JOIN ROLES r ON r.id_rol = u.id_rol
ORDER BY u.id_usuario;

SELECT nivel_destinatario, COUNT(*) AS total
FROM PROPUESTAS_PROYECTO
GROUP BY nivel_destinatario;

SELECT p.titulo, p.fase_actual, p.estado, pg.tipo_pago, pg.estado_pago
FROM PROYECTOS_GRADO p
JOIN INTEGRANTES_PROYECTO i ON i.id_proyecto = p.id_proyecto AND i.es_lider = TRUE
JOIN PAGOS_PROYECTO pg ON pg.id_estudiante = i.id_estudiante AND pg.tipo_pago = 'DERECHOS_GRADO'
WHERE p.id_proyecto = @proyecto_jsantiago;
