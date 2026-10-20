CREATE DATABASE IF NOT EXISTS uts_trabajos_grado DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE uts_trabajos_grado;

-- 1. ROLES
CREATE TABLE ROLES (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- 2. PROGRAMAS_ACADEMICOS
CREATE TABLE PROGRAMAS_ACADEMICOS (
    id_programa INT AUTO_INCREMENT PRIMARY KEY,
    nombre_programa VARCHAR(150) NOT NULL,
    nivel_formacion ENUM('TECNOLOGIA', 'INGENIERIA') NOT NULL
);

-- 3. USUARIOS
CREATE TABLE USUARIOS (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo_institucional VARCHAR(100) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    estado_activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_rol) REFERENCES ROLES(id_rol)
);

-- 4. ESTUDIANTES_PERFIL
CREATE TABLE ESTUDIANTES_PERFIL (
    id_estudiante INT PRIMARY KEY,
    id_programa INT NOT NULL,
    codigo_estudiantil VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (id_estudiante) REFERENCES USUARIOS(id_usuario),
    FOREIGN KEY (id_programa) REFERENCES PROGRAMAS_ACADEMICOS(id_programa)
);

-- 5. DOCENTES_PERFIL
CREATE TABLE DOCENTES_PERFIL (
    id_docente INT PRIMARY KEY,
    especialidad VARCHAR(150) NOT NULL,
    es_evaluador BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_docente) REFERENCES USUARIOS(id_usuario)
);

-- 6. PROPUESTAS_PROYECTO
CREATE TABLE PROPUESTAS_PROYECTO (
    id_propuesta INT AUTO_INCREMENT PRIMARY KEY,
    id_creador INT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT NOT NULL,
    nivel_destinatario ENUM('TECNOLOGIA', 'INGENIERIA') NOT NULL,
    estado ENUM('DISPONIBLE', 'SELECCIONADA') DEFAULT 'DISPONIBLE',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_creador) REFERENCES USUARIOS(id_usuario)
);

-- 7. FASES_CICLO
CREATE TABLE FASES_CICLO (
    numero_fase INT PRIMARY KEY,
    nombre_fase VARCHAR(100) NOT NULL
);

INSERT INTO FASES_CICLO (numero_fase, nombre_fase) VALUES
(1, 'Fase 1: Pago y Selección/Registro de Idea'),
(2, 'Fase 2: Asignación y Entregable 1'),
(3, 'Fase 3: Entregable 2'),
(4, 'Fase 4: Entregable 3 / Exoneración Saber'),
(5, 'Fase 5: Entregable 4 (Documento Final)'),
(6, 'Fase 6: Sustentación Final');

-- 8. PROYECTOS_GRADO
CREATE TABLE PROYECTOS_GRADO (
    id_proyecto INT AUTO_INCREMENT PRIMARY KEY,
    id_propuesta INT NULL,
    fase_actual INT DEFAULT 1,
    titulo VARCHAR(255) NOT NULL,
    estado ENUM('EN_PROCESO', 'APROBADO', 'RECHAZADO', 'CANCELADO', 'EXONERADO') DEFAULT 'EN_PROCESO',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_propuesta) REFERENCES PROPUESTAS_PROYECTO(id_propuesta),
    FOREIGN KEY (fase_actual) REFERENCES FASES_CICLO(numero_fase)
);

-- 9. INTEGRANTES_PROYECTO (Permite soporte para duplas/parejas de estudiantes)
CREATE TABLE INTEGRANTES_PROYECTO (
    id_integrante INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    id_estudiante INT NOT NULL,
    es_lider BOOLEAN DEFAULT FALSE,
    fecha_vinculacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto),
    FOREIGN KEY (id_estudiante) REFERENCES USUARIOS(id_usuario),
    CONSTRAINT unique_estudiante_proyecto UNIQUE (id_estudiante)
);

-- 10. PAGOS_PROYECTO
CREATE TABLE PAGOS_PROYECTO (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    tipo_pago ENUM('DERECHOS_GRADO', 'PRORROGA') NOT NULL,
    ruta_comprobante_pdf VARCHAR(255) NOT NULL,
    estado_pago ENUM('PENDIENTE', 'APROBADO', 'RECHAZADO') DEFAULT 'PENDIENTE',
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_estudiante) REFERENCES USUARIOS(id_usuario)
);

-- 11. ASIGNACIONES_DOCENTES
CREATE TABLE ASIGNACIONES_DOCENTES (
    id_asignacion INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    id_docente INT NOT NULL,
    subrol ENUM('DIRECTOR', 'EVALUADOR') NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto),
    FOREIGN KEY (id_docente) REFERENCES USUARIOS(id_usuario)
);

-- 12. ENTREGABLES
CREATE TABLE ENTREGABLES (
    id_entregable INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    fase_asociada INT NOT NULL,
    id_pago_asociado INT NULL,
    numero_entregable INT NOT NULL,
    ruta_pdf VARCHAR(255) NOT NULL,
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto),
    FOREIGN KEY (fase_asociada) REFERENCES FASES_CICLO(numero_fase),
    FOREIGN KEY (id_pago_asociado) REFERENCES PAGOS_PROYECTO(id_pago)
);

-- 13. REVISIONES_ENTREGABLE
CREATE TABLE REVISIONES_ENTREGABLE (
    id_revision INT AUTO_INCREMENT PRIMARY KEY,
    id_entregable INT NOT NULL,
    id_revisor INT NOT NULL,
    string_revisor ENUM('DIRECTOR', 'EVALUADOR', 'COMITE') NOT NULL,
    estado_evaluacion ENUM('APROBADO', 'RECHAZADO', 'AJUSTAR') NOT NULL,
    observaciones TEXT,
    fecha_revision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_entregable) REFERENCES ENTREGABLES(id_entregable),
    FOREIGN KEY (id_revisor) REFERENCES USUARIOS(id_usuario)
);

-- 14. SOLICITUDES_CAMBIO_DOCENTE
CREATE TABLE SOLICITUDES_CAMBIO_DOCENTE (
    id_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    id_docente_actual INT NOT NULL,
    subrol_afectado ENUM('DIRECTOR', 'EVALUADOR') NOT NULL,
    justificacion TEXT NOT NULL,
    estado ENUM('PENDIENTE', 'APROBADA', 'RECHAZADA') DEFAULT 'PENDIENTE',
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto),
    FOREIGN KEY (id_docente_actual) REFERENCES USUARIOS(id_usuario)
);

-- 15. SOLICITUDES_EXONERACION_SABER
CREATE TABLE SOLICITUDES_EXONERACION_SABER (
    id_exoneracion INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    tipo_prueba ENUM('SABER_TYT', 'SABER_PRO') NOT NULL,
    puntaje_obtenido INT NOT NULL,
    ruta_certificado_pdf VARCHAR(255) NOT NULL,
    estado ENUM('PENDIENTE', 'APROBADA', 'RECHAZADA') DEFAULT 'PENDIENTE',
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto)
);

-- 16. SOLICITUDES_PRORROGA
CREATE TABLE SOLICITUDES_PRORROGA (
    id_prorroga INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    id_pago INT NOT NULL,
    justificacion TEXT NOT NULL,
    estado ENUM('PENDIENTE', 'APROBADA', 'RECHAZADA') DEFAULT 'PENDIENTE',
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto),
    FOREIGN KEY (id_pago) REFERENCES PAGOS_PROYECTO(id_pago)
);

-- 17. SUSTENTACIONES
CREATE TABLE SUSTENTACIONES (
    id_sustentacion INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto INT NOT NULL,
    lugar_salon VARCHAR(100) NOT NULL,
    fecha_hora_programada DATETIME NOT NULL,
    FOREIGN KEY (id_proyecto) REFERENCES PROYECTOS_GRADO(id_proyecto)
);

-- -- DATOS INICIALES DE PRUEBA
-- INSERT INTO ROLES (nombre) VALUES ('ESTUDIANTE'), ('DOCENTE'), ('COMITE'), ('ADMINISTRADOR');

-- INSERT INTO PROGRAMAS_ACADEMICOS (nombre_programa, nivel_formacion) VALUES 
-- ('Tecnología en Desarrollo de Sistemas de Información', 'TECNOLOGIA'),
-- ('Ingeniería de Sistemas', 'INGENIERIA');

-- -- Usuarios Semilla (Contraseña por defecto: uts2026)
-- INSERT INTO USUARIOS (id_rol, documento_identidad, nombres, apellidos, correo_institucional, contrasena_hash) VALUES
-- (1, '1001234567', 'Jhoan', 'Santiago', 'jsantiago@correo.uts.edu.co', 'uts2026'),
-- (1, '1007654321', 'Carlos', 'Pérez', 'cperez@correo.uts.edu.co', 'uts2026'),
-- (2, '91234567', 'Director', 'Docente', 'director@correo.uts.edu.co', 'uts2026'),
-- (2, '91234568', 'Evaluador', 'Docente', 'evaluador@correo.uts.edu.co', 'uts2026'),
-- (3, '80123456', 'Comite', 'Grados', 'comite@correo.uts.edu.co', 'uts2026');

-- INSERT INTO ESTUDIANTES_PERFIL (id_estudiante, id_programa, codigo_estudiantil) VALUES
-- (1, 2, 'ST-1001'),
-- (2, 2, 'ST-1002');

-- INSERT INTO DOCENTES_PERFIL (id_docente, especialidad, es_evaluador) VALUES
-- (3, 'Desarrollo Web & Software', TRUE),
-- (4, 'Bases de Datos & Redes', TRUE);