-- ============================================================
-- PROYECTO SWITCH: DATOS DE PRUEBA E INICIALIZACIÓN (seed.sql)
-- Requiere haber ejecutado schema.sql sobre una base vacía.
--
-- Contraseñas de prueba:
--   - Usuarios VECINO/DELEGADO => clave123
--   - Usuario ADMIN            => Switch2024!
-- ============================================================

TRUNCATE TABLE sugerencias_esfuerzo, resenas, intercambios, reportes, mensajes_chat, publicaciones_p2p, nexos_sociales, cupos_necesidad, instituciones, usuarios RESTART IDENTITY CASCADE;

-- 1. Usuarios (passwords hasheadas con bcrypt)
INSERT INTO usuarios (id, dni, nombre, apellido, telefono, password, validado_mayor_edad, rol, activo) VALUES
  (1, '38450912', 'Guillermina', 'Valdez',    '2281459821', '$2b$10$X8zsNck2lcV7hSnWMkcYSuGHxl.uHQdkgU1etRjRgQc/QJ8zvH5r.', TRUE, 'VECINO',   TRUE),
  (2, '35123456', 'Carlos',      'Rodríguez', '2281506070', '$2b$10$X8zsNck2lcV7hSnWMkcYSuGHxl.uHQdkgU1etRjRgQc/QJ8zvH5r.', TRUE, 'VECINO',   TRUE),
  (3, '28999888', 'María',       'Gómez',     '2281667788', '$2b$10$X8zsNck2lcV7hSnWMkcYSuGHxl.uHQdkgU1etRjRgQc/QJ8zvH5r.', TRUE, 'DELEGADO', TRUE),
  (4, '11111111', 'Admin',       'Switch',    '2281000001', '$2b$10$48vPvsxai5PjqkrqvtNAp.zKqMIUUPfVjiWl2pRe.wArYoZOA5Ew.', TRUE, 'ADMIN',    TRUE);

-- 2. Instituciones comunitarias
INSERT INTO instituciones (id, nombre, tipo, direccion, latitud, longitud, qr_codigo_hash) VALUES
  (1, 'Comedor Infantil El Sol',                   'COMEDOR',    'Calle Rivas 123', -36.778100, -59.858400, 'QR_HASH_COMEDOR_ELSOL_2026'),
  (2, 'Hogar San José para Personas Mayores',      'HOGAR',      'Av. Mitre 840',   -36.782500, -59.861200, 'QR_HASH_HOGAR_SANJOSE_2026'),
  (3, 'Biblioteca Popular Bartolomé J. Ronco',     'BIBLIOTECA', 'Burgos 687',      -36.779500, -59.858200, 'QR_HASH_BIBLIO_RONCO_2026');

-- 3. Cupos de necesidad
INSERT INTO cupos_necesidad (id, institucion_id, titulo, descripcion, prioridad, cupo_maximo, cupo_actual, activo) VALUES
  (1, 1, 'Donación de Leche en Polvo',        'Se necesitan paquetes de leche para la merienda comunitaria.', 'PRIORITARIA', 20, 14, TRUE),
  (2, 1, 'Apoyo en Cocina (Tarde)',           'Ayuda voluntaria de 2 horas para fraccionar viandas.',         'URGENTE',     3,  3, FALSE),
  (3, 2, 'Elementos de Higiene Personal',     'Jabones de tocador, lavandina y toallas de mano.',             'GENERAL',     15, 6, TRUE),
  (4, 3, 'Taller de Lectura para Niños',      'Acompañamiento literario sábados de 10 a 12 hs.',              'GENERAL',      5, 2, TRUE);

-- 4. Nexo Social activo para Guillermina (habilita a publicar)
INSERT INTO nexos_sociales (usuario_id, cupo_necesidad_id, institucion_id, metodo_validacion, latitud_usuario, longitud_usuario, nivel_impacto, estado, fecha_activacion, fecha_expiracion) VALUES
  (1, 1, 1, 'QR_GPS', -36.778120, -59.858410, 'MEDIO', 'ACTIVO', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP + INTERVAL '85 days');

-- 5. Publicaciones del catálogo P2P (estado 'Activo')
INSERT INTO publicaciones_p2p (id, usuario_id, titulo, descripcion, nivel_esfuerzo, tipo_item, imagen_url, estado, creado_en) VALUES
  (1, 1, 'Cochecito de Bebé Plegable',            'En muy buen estado de conservación. Ideal para bebés de hasta 2 años.', 'SIMPLE', 'OBJETO',   NULL, 'Activo', CURRENT_TIMESTAMP - INTERVAL '2 days'),
  (2, 2, 'Clases de Apoyo Escolar en Matemática', 'Ofrezco 2 horas semanales para nivel primario.',                'ALTO',   'SERVICIO', NULL, 'Activo', CURRENT_TIMESTAMP - INTERVAL '4 days'),
  (3, 3, 'Bicicleta Rodado 26',                   'Lista para usar. Le hice mantenimiento completo de cadena y frenos.',   'MEDIO',  'OBJETO',   NULL, 'Activo', CURRENT_TIMESTAMP - INTERVAL '6 days'),
  (4, 2, 'Reparación de PC / Laptop',             'Formateo, limpieza y optimización a domicilio.',         'ALTO',   'SERVICIO', NULL, 'Activo', CURRENT_TIMESTAMP - INTERVAL '9 days'),
  (5, 1, 'Libros Infantiles (lote x10)',          'Cuentos para primeras lecturas, en muy buen estado.',                   'SIMPLE', 'OBJETO',   NULL, 'Activo', CURRENT_TIMESTAMP - INTERVAL '12 days');

-- 6. Mensajes de chat de prueba (entre Carlos "2" y Guillermina "1")
INSERT INTO mensajes_chat (emisor_id, receptor_id, texto, leido, creado_en) VALUES
  ('2', '1', '¡Hola Guillermina! Me interesa el cochecito. ¿Sigue disponible?',              TRUE,  CURRENT_TIMESTAMP - INTERVAL '3 hours'),
  ('1', '2', '¡Hola Carlos! Sí, está impecable. ¿Cuándo lo querés venir a ver?',            TRUE,  CURRENT_TIMESTAMP - INTERVAL '2 hours'),
  ('2', '1', '¿Te sirve el sábado por la mañana? Puedo llevar las clases de apoyo como cambio.', FALSE, CURRENT_TIMESTAMP - INTERVAL '1 hour');

-- 7. Reportes / denuncias pendientes para el panel de administración
INSERT INTO reportes (reportante_id, reportante_nombre, reportado_id, reportado_nombre, motivo, estado, creado_en) VALUES
  ('1', 'Guillermina Valdez', '3', 'María Gómez', 'El producto entregado no coincide con las fotos publicadas.', 'PENDIENTE', CURRENT_TIMESTAMP - INTERVAL '1 day'),
  ('2', 'Carlos Rodríguez',   '3', 'María Gómez', 'Lenguaje inapropiado en el chat de negociación.',             'PENDIENTE', CURRENT_TIMESTAMP - INTERVAL '2 days');

-- 8. Intercambios históricos (alimentan métricas, gráficos y reputación)
-- Distribución: Mar=1, Abr=2, May=2, Jun=2, Jul=2, Ago=3  (Total: 12)
-- Los más antiguos quedan COMPLETADOS con confirmaciones mutuas; los recientes quedan jugables.
INSERT INTO intercambios (publicacion_deseada_id, titulo_deseado, dueno_id, ofertante_id, ofertante_nombre, items_ofrecidos, estado, confirmacion_dueno, confirmacion_ofertante, creado_en) VALUES
  (1, 'Cochecito de Bebé Plegable',            1, 2, 'Carlos Rodríguez', '[{"id": "2", "titulo": "Clases de Apoyo Escolar"}]'::jsonb,  'COMPLETADO', TRUE, TRUE,  DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '5 months' + INTERVAL '3 days'),
  (2, 'Clases de Apoyo Escolar en Matemática', 2, 3, 'María Gómez',      '[{"id": "5", "titulo": "Libros Infantiles"}]'::jsonb,        'COMPLETADO', TRUE, TRUE,  DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '4 months' + INTERVAL '2 days'),
  (3, 'Bicicleta Rodado 26',                   3, 1, 'Guillermina Valdez', '[{"id": "1", "titulo": "Cochecito de Bebé"}]'::jsonb,      'COMPLETADO', TRUE, TRUE,  DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '4 months' + INTERVAL '20 days'),
  (4, 'Reparación de PC / Laptop',             2, 3, 'María Gómez',      '[{"id": "3", "titulo": "Bicicleta Rodado 26"}]'::jsonb,      'RECHAZADA', FALSE, FALSE, DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '3 months' + INTERVAL '6 days'),
  (5, 'Libros Infantiles (lote x10)',          1, 2, 'Carlos Rodríguez', '[{"id": "2", "titulo": "Clases de Apoyo Escolar"}]'::jsonb,  'COMPLETADO', TRUE, TRUE,  DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '3 months' + INTERVAL '18 days'),
  (2, 'Clases de Apoyo Escolar en Matemática', 2, 1, 'Guillermina Valdez', '[{"id": "5", "titulo": "Libros Infantiles"}]'::jsonb,      'COMPLETADO', TRUE, TRUE,  DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '2 months' + INTERVAL '9 days'),
  (3, 'Bicicleta Rodado 26',                   3, 2, 'Carlos Rodríguez', '[{"id": "4", "titulo": "Reparación de PC"}]'::jsonb,         'PENDIENTE', FALSE, FALSE, DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '2 months' + INTERVAL '21 days'),
  (1, 'Cochecito de Bebé Plegable',            1, 3, 'María Gómez',      '[{"id": "3", "titulo": "Bicicleta Rodado 26"}]'::jsonb,      'ACEPTADA', FALSE, FALSE, DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '1 month' + INTERVAL '4 days'),
  (4, 'Reparación de PC / Laptop',             2, 1, 'Guillermina Valdez', '[{"id": "1", "titulo": "Cochecito de Bebé"}]'::jsonb,      'ACEPTADA', FALSE, FALSE, DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '1 month' + INTERVAL '16 days'),
  (5, 'Libros Infantiles (lote x10)',          1, 3, 'María Gómez',      '[{"id": "2", "titulo": "Clases de Apoyo Escolar"}]'::jsonb,  'ACEPTADA', FALSE, FALSE, CURRENT_TIMESTAMP - INTERVAL '5 days'),
  (3, 'Bicicleta Rodado 26',                   3, 1, 'Guillermina Valdez', '[{"id": "5", "titulo": "Libros Infantiles"}]'::jsonb,      'PENDIENTE', FALSE, FALSE, CURRENT_TIMESTAMP - INTERVAL '2 days'),
  (2, 'Clases de Apoyo Escolar en Matemática', 2, 3, 'María Gómez',      '[{"id": "4", "titulo": "Reparación de PC"}]'::jsonb,         'ACEPTADA', FALSE, FALSE, CURRENT_TIMESTAMP - INTERVAL '1 day');

-- 9. Reseñas de los trueques completados (reputación)
INSERT INTO resenas (intercambio_id, autor_id, destino_id, puntaje, comentario) VALUES
  (1, 1, 2, 5, 'Carlos entregó las clases pactadas. Súper recomendable.'),
  (1, 2, 1, 5, 'El cochecito estaba impecable, tal cual la descripción.'),
  (2, 2, 3, 4, 'Buena disposición, aunque llegamos a reprogramar una clase.'),
  (2, 3, 2, 5, 'Excelente profe, mi hijo quedó encantado.'),
  (3, 3, 1, 5, 'Guillermina cuidó la bici como si fuera propia.'),
  (3, 1, 3, 4, 'Todo bien, coordinamos rápido por el chat.'),
  (5, 1, 2, 5, 'Gran persona, además dejó material extra de apoyo.'),
  (5, 2, 1, 4, 'Los libros estaban muy cuidados.'),
  (6, 2, 1, 5, 'Puntual y amable, un gusto truequear así.');

-- 10. Reajustar las secuencias tras los inserts con ID explícito
SELECT setval('usuarios_id_seq', (SELECT MAX(id) FROM usuarios));
SELECT setval('instituciones_id_seq', (SELECT MAX(id) FROM instituciones));
SELECT setval('cupos_necesidad_id_seq', (SELECT MAX(id) FROM cupos_necesidad));
SELECT setval('nexos_sociales_id_seq', (SELECT MAX(id) FROM nexos_sociales));
SELECT setval('publicaciones_p2p_id_seq', (SELECT MAX(id) FROM publicaciones_p2p));
SELECT setval('mensajes_chat_id_seq', (SELECT MAX(id) FROM mensajes_chat));
SELECT setval('reportes_id_seq', (SELECT MAX(id) FROM reportes));
SELECT setval('intercambios_id_seq', (SELECT MAX(id) FROM intercambios));
SELECT setval('resenas_id_seq', (SELECT MAX(id) FROM resenas));
