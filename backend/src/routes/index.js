const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const instController = require('../controllers/instController');
const p2pController = require('../controllers/p2pController');
const adminController = require('../controllers/adminController');
const chatController = require('../controllers/chatController');
const reporteController = require('../controllers/reporteController');
const intercambioController = require('../controllers/intercambioController');
const usuarioController = require('../controllers/usuarioController');
const sugerenciaController = require('../controllers/sugerenciaController');

const { requerirSesion, requerirAdmin } = require('../middlewares/auth');

// Rutas de Autenticación / Registro (públicas)
router.post('/auth/registro', authController.registrarUsuario);
router.post('/auth/login', authController.loginUsuario);

// Rutas de Instituciones y Cupos de Necesidad (lectura pública)
router.get('/instituciones', instController.listarInstituciones);
router.get('/instituciones/:institucionId/cupos', instController.obtenerCuposAbiertos);
router.post('/instituciones/registro', instController.registrarInstitucion);
router.post('/validaciones/qr-scan', requerirSesion, instController.validarPresenciaQR);

// Rutas del Catálogo P2P (lectura pública, escritura con sesión)
router.get('/catalogo', p2pController.listarCatálogoP2P);
router.get('/catalogo/mis-publicaciones', requerirSesion, p2pController.listarMisPublicaciones);
router.post('/catalogo/clasificar-esfuerzo', p2pController.previsualizarEsfuerzo);
router.post('/catalogo/imagen', requerirSesion, p2pController.subirImagenMiddleware.single('imagen'), p2pController.subirImagen);
router.post('/catalogo/publicar', requerirSesion, p2pController.crearPublicacionP2P);
router.post('/catalogo/:publicacionId/sugerir-esfuerzo', requerirSesion, sugerenciaController.sugerirEsfuerzo);

// Rutas de Chat / Mensajería (privadas)
router.get('/mensajes', requerirSesion, chatController.obtenerMensajes);
router.post('/mensajes/enviar', requerirSesion, chatController.enviarMensaje);

// Rutas de Intercambios / Trueques
router.post('/intercambios/proponer', requerirSesion, intercambioController.proponerIntercambio);
router.get('/intercambios/mis-propuestas', requerirSesion, intercambioController.listarMisPropuestas);
router.post('/intercambios/:id/responder', requerirSesion, intercambioController.responderPropuesta);
router.post('/intercambios/:id/confirmar', requerirSesion, intercambioController.confirmarTrueque);

// Rutas de Reportes / Denuncias
router.post('/reportes', requerirSesion, reporteController.reportarUsuario);

// Rutas de Perfil de Usuario
router.get('/usuarios/perfil', requerirSesion, usuarioController.obtenerMiPerfil);

// 🟢 Rutas de Administración (Dashboard y Moderación) — solo rol ADMIN
router.get('/admin/estadisticas', requerirSesion, requerirAdmin, adminController.obtenerEstadisticasAdmin);
router.get('/admin/reportes', requerirSesion, requerirAdmin, reporteController.listarReportes);
router.post('/admin/reportes/:reporteId/desestimar', requerirSesion, requerirAdmin, reporteController.desestimarReporte);
router.post('/admin/dar-de-baja', requerirSesion, requerirAdmin, reporteController.darDeBajaUsuario);
router.post('/admin/suspender', requerirSesion, requerirAdmin, reporteController.suspenderUsuario);
router.get('/admin/sugerencias-esfuerzo', requerirSesion, requerirAdmin, sugerenciaController.listarSugerencias);
router.post('/admin/sugerencias-esfuerzo/:id/aplicar', requerirSesion, requerirAdmin, sugerenciaController.aplicarSugerencia);
router.post('/admin/sugerencias-esfuerzo/:id/descartar', requerirSesion, requerirAdmin, sugerenciaController.descartarSugerencia);

module.exports = router;
