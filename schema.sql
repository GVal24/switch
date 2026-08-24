-- ============================================================
-- PROYECTO SWITCH: SCRIPT DE ESTRUCTURA DE BASE DE DATOS (schema.sql)
-- Motor: PostgreSQL 14+
-- ============================================================

-- ------------------------------------------------------------
-- 1. TABLA: usuarios
-- ------------------------------------------------------------
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(15) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    validado_mayor_edad BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_aceptacion_terminos TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rol VARCHAR(20) NOT NULL DEFAULT 'VECINO', -- 'VECINO', 'DELEGADO', 'ADMIN'
    activo BOOLEAN NOT NULL DEFAULT TRUE,      -- false => bloqueo permanente por administración
    suspendido_hasta TIMESTAMP NULL,           -- fecha de fin de suspensión temporal (NULL = sin suspensión)
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rol CHECK (rol IN ('VECINO', 'DELEGADO', 'ADMIN'))
);

-- ------------------------------------------------------------
-- 2. TABLA: instituciones
-- ------------------------------------------------------------
CREATE TABLE instituciones (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL, -- 'COMEDOR', 'HOGAR', 'BIBLIOTECA', 'CENTRO_DIA', etc.
    direccion VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    descripcion TEXT,
    latitud NUMERIC(10, 8) NOT NULL,
    longitud NUMERIC(11, 8) NOT NULL,
    qr_codigo_hash VARCHAR(255) UNIQUE NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 3. TABLA: cupos_necesidad
-- ------------------------------------------------------------
CREATE TABLE cupos_necesidad (
    id SERIAL PRIMARY KEY,
    institucion_id INT NOT NULL REFERENCES instituciones(id) ON DELETE CASCADE,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    -- La institución declara qué tan crítica es la necesidad para su población.
    -- Determina la vigencia base del Nexo Social de quien la cubre.
    prioridad VARCHAR(15) NOT NULL DEFAULT 'GENERAL',
    cupo_maximo INT NOT NULL CHECK (cupo_maximo > 0),
    cupo_actual INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE, -- false cuando se completa o se pausa
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_prioridad CHECK (prioridad IN ('GENERAL', 'PRIORITARIA', 'URGENTE')),
    CONSTRAINT chk_cupos_validos CHECK (cupo_actual <= cupo_maximo)
);

-- ------------------------------------------------------------
-- 4. TABLA: nexos_sociales
-- ------------------------------------------------------------
CREATE TABLE nexos_sociales (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    cupo_necesidad_id INT REFERENCES cupos_necesidad(id),
    institucion_id INT NOT NULL REFERENCES instituciones(id),
    metodo_validacion VARCHAR(20) NOT NULL DEFAULT 'QR_GPS', -- 'QR_GPS', 'APROBACION_DELEGADO'
    latitud_usuario NUMERIC(10, 8),
    longitud_usuario NUMERIC(11, 8),
    nivel_impacto VARCHAR(10) NOT NULL DEFAULT 'SIMPLE', -- 'SIMPLE', 'MEDIO', 'ALTO'
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO', -- 'ACTIVO', 'INACTIVO', 'EXPIRADO'
    fecha_activacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '60 days'),

    CONSTRAINT chk_metodo CHECK (metodo_validacion IN ('QR_GPS', 'APROBACION_DELEGADO')),
    CONSTRAINT chk_estado_nexo CHECK (estado IN ('ACTIVO', 'INACTIVO', 'EXPIRADO'))
);

-- ------------------------------------------------------------
-- 5. TABLA: publicaciones_p2p
-- ------------------------------------------------------------
CREATE TABLE publicaciones_p2p (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    nivel_esfuerzo VARCHAR(10) NOT NULL, -- 'SIMPLE', 'MEDIO', 'ALTO'
    tipo_item VARCHAR(20) NOT NULL DEFAULT 'GENERAL', -- 'GENERAL', 'OBJETO', 'SERVICIO'
    imagen_url TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo', -- 'Activo', 'Pausado', 'Completado'
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_nivel CHECK (nivel_esfuerzo IN ('SIMPLE', 'MEDIO', 'ALTO'))
);

-- ------------------------------------------------------------
-- 6. TABLA: mensajes_chat
--    emisor_id / receptor_id son VARCHAR para soportar tanto
--    IDs de usuarios ("1", "2") como instituciones ("inst_1")
-- ------------------------------------------------------------
CREATE TABLE mensajes_chat (
    id SERIAL PRIMARY KEY,
    emisor_id VARCHAR(50) NOT NULL,
    receptor_id VARCHAR(50) NOT NULL,
    texto TEXT NOT NULL,
    leido BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mensajes_conversacion ON mensajes_chat (emisor_id, receptor_id);
CREATE INDEX idx_mensajes_creado ON mensajes_chat (creado_en);

-- ------------------------------------------------------------
-- 7. TABLA: reportes (denuncias de la comunidad)
-- ------------------------------------------------------------
CREATE TABLE reportes (
    id SERIAL PRIMARY KEY,
    reportante_id VARCHAR(50) NOT NULL,
    reportante_nombre VARCHAR(101) NOT NULL DEFAULT '',
    reportado_id VARCHAR(50),                 -- NULL => inconveniente general (no apunta a un usuario)
    reportado_nombre VARCHAR(101) NOT NULL DEFAULT '',
    motivo TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE', -- 'PENDIENTE', 'DESESTIMADO', 'RESUELTO_BAN', 'RESUELTO_SUSPENSION'
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_estado_reporte CHECK (estado IN ('PENDIENTE', 'DESESTIMADO', 'RESUELTO_BAN', 'RESUELTO_SUSPENSION'))
);

-- ------------------------------------------------------------
-- 8. TABLA: intercambios (propuestas de Switch / trueques)
-- ------------------------------------------------------------
CREATE TABLE intercambios (
    id SERIAL PRIMARY KEY,
    publicacion_deseada_id INT NOT NULL REFERENCES publicaciones_p2p(id) ON DELETE CASCADE,
    titulo_deseado VARCHAR(100) NOT NULL DEFAULT '',
    dueno_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    ofertante_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    ofertante_nombre VARCHAR(101) NOT NULL DEFAULT '',
    items_ofrecidos JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{ "id": "3", "titulo": "..." }]
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE', -- 'PENDIENTE', 'ACEPTADA', 'RECHAZADA', 'COMPLETADO'
    confirmacion_dueno BOOLEAN NOT NULL DEFAULT FALSE,
    confirmacion_ofertante BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_estado_intercambio CHECK (estado IN ('PENDIENTE', 'ACEPTADA', 'RECHAZADA', 'COMPLETADO'))
);

CREATE INDEX idx_intercambios_creado ON intercambios (creado_en);
CREATE INDEX idx_intercambios_dueno ON intercambios (dueno_id);
CREATE INDEX idx_intercambios_ofertante ON intercambios (ofertante_id);

-- ------------------------------------------------------------
-- 9. TABLA: resenas (calificaciones entre vecinos tras un trueque)
-- ------------------------------------------------------------
CREATE TABLE resenas (
    id SERIAL PRIMARY KEY,
    intercambio_id INT NOT NULL REFERENCES intercambios(id) ON DELETE CASCADE,
    autor_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    destino_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    puntaje INT NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
    comentario TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_resena_por_intercambio UNIQUE (intercambio_id, autor_id)
);

-- Sugerencias de la comunidad sobre el nivel de esfuerzo de una publicación.
-- El clasificador automático puede equivocarse: los usuarios marcan el error
-- y administración decide si aplica la corrección.
CREATE TABLE sugerencias_esfuerzo (
    id SERIAL PRIMARY KEY,
    publicacion_id INT NOT NULL REFERENCES publicaciones_p2p(id) ON DELETE CASCADE,
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nivel_sugerido VARCHAR(10) NOT NULL CHECK (nivel_sugerido IN ('SIMPLE', 'MEDIO', 'ALTO')),
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_estado_sugerencia CHECK (estado IN ('PENDIENTE', 'APLICADA', 'DESCARTADA')),
    -- Un mismo usuario no puede sugerir dos veces para la misma publicación
    CONSTRAINT uq_sugerencia_por_usuario UNIQUE (publicacion_id, usuario_id)
);
