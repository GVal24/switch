const path = require('path');
const fs = require('fs');
const multer = require('multer');
const asyncWrapper = require('../middlewares/asyncWrapper');
const { ValidationError, ForbiddenError } = require('../utils/customErrors');
const { clasificarEsfuerzo } = require('../utils/clasificadorEsfuerzo');
const P2PModel = require('../models/p2pModel');
const VoluntariadoModel = require('../models/voluntariadoModel');

// ==========================================
// Configuración de subida de imágenes
// ==========================================
const UPLOADS_DIR = path.resolve(__dirname, '../../uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Extensión segura según el mimetype REAL del archivo (no confiamos en el
// nombre original, que puede venir vacío o con mayúsculas desde el celular).
const EXTENSION_POR_MIMETYPE = {
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
  'image/heic': '.heic',
  'image/heif': '.heif',
  'image/bmp': '.bmp'
};

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    const ext = EXTENSION_POR_MIMETYPE[(file.mimetype || '').toLowerCase()] || '.jpg';
    cb(null, `pub_${req.usuario.id}_${Date.now()}${ext}`);
  }
});

const subirImagenMiddleware = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const mimetype = (file.mimetype || '').toLowerCase();
    // Se acepta cualquier imagen que el teléfono pueda producir (JPEG, PNG,
    // WEBP, GIF, HEIC/HEIF de iPhone, BMP). Se excluye SVG porque puede
    // contener código ejecutable.
    if (!mimetype.startsWith('image/') || mimetype === 'image/svg+xml') {
      return cb(new ValidationError('El archivo no es una imagen válida.'));
    }
    cb(null, true);
  }
});

/**
 * Obtener todas las publicaciones del Catálogo General P2P
 */
const listarCatálogoP2P = asyncWrapper(async (req, res) => {
  const { tipoItem, nivelEsfuerzo, busqueda } = req.query;

  const publicaciones = await P2PModel.obtenerCatalogoDisponible({ 
    tipoItem, 
    nivelEsfuerzo: nivelEsfuerzo || req.query.nivel_esfuerzo, 
    busqueda 
  });

  res.status(200).json({
    exito: true,
    datos: publicaciones
  });
});

/**
 * GET /api/catalogo/mis-publicaciones
 * Publicaciones activas del usuario logueado (para ofrecer en un trueque).
 * El usuario viene SIEMPRE del token.
 */
const listarMisPublicaciones = asyncWrapper(async (req, res) => {
  const publicaciones = await P2PModel.obtenerPublicacionesDeUsuario(req.usuario.id);

  res.status(200).json({
    exito: true,
    datos: publicaciones
  });
});

/**
 * POST /api/catalogo/clasificar-esfuerzo
 * Previsualiza el nivel de esfuerzo que se le asignará a una publicación.
 * Body: { titulo, descripcion, tipoItem }
 */
const previsualizarEsfuerzo = asyncWrapper(async (req, res) => {
  const { titulo, descripcion, tipoItem } = req.body;
  const nivelEsfuerzo = clasificarEsfuerzo(titulo, descripcion, tipoItem);

  res.status(200).json({
    exito: true,
    datos: { nivelEsfuerzo }
  });
});

/**
 * POST /api/catalogo/imagen (multipart, campo "imagen")
 * Guarda la foto elegida desde el dispositivo y devuelve su URL pública.
 */
const subirImagen = asyncWrapper(async (req, res) => {
  if (!req.file) {
    throw new ValidationError('No se recibió ninguna imagen.');
  }

  const url = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

  res.status(201).json({
    exito: true,
    mensaje: 'Imagen subida correctamente.',
    datos: { url }
  });
});

/**
 * Crear nueva publicación en el Catálogo P2P (Requiere Nexo Social Activo).
 * El nivel de esfuerzo se calcula automáticamente según lo que se ofrece:
 * no se acepta el valor enviado por el cliente.
 */
const crearPublicacionP2P = asyncWrapper(async (req, res) => {
  // El oferente siempre es el usuario de la sesión (no se confía en el body)
  const usuarioId = req.usuario.id;
  const tipoItem = req.body.tipoItem || req.body.tipo_item || 'OBJETO';
  const imagenUrl = req.body.imagenUrl || req.body.imagen_url;
  const { titulo, descripcion } = req.body;

  if (!titulo || !descripcion) {
    throw new ValidationError('El título y la descripción son obligatorios.');
  }

  if (!['OBJETO', 'SERVICIO'].includes(tipoItem)) {
    throw new ValidationError('El tipo de publicación debe ser OBJETO o SERVICIO.');
  }

  // Clasificación automática del nivel de esfuerzo
  const nivelEsfuerzo = clasificarEsfuerzo(titulo, descripcion, tipoItem);

  const tieneNexoActivo = await VoluntariadoModel.verificarNexoSocialActivo(usuarioId);

  if (!tieneNexoActivo) {
    throw new ForbiddenError("Debes colaborar previamente en una institución comunitaria para activar tu Nexo Social antes de publicar en el catálogo.");
  }

  const nuevaPublicacion = await P2PModel.crearPublicacion({
    usuarioId,
    titulo,
    descripcion,
    nivelEsfuerzo,
    tipoItem,
    imagenUrl
  });

  res.status(201).json({
    exito: true,
    mensaje: `Publicación creada con éxito. Esfuerzo calculado automáticamente: ${nivelEsfuerzo}.`,
    datos: nuevaPublicacion
  });
});

module.exports = {
  listarCatálogoP2P,
  listarMisPublicaciones,
  previsualizarEsfuerzo,
  subirImagen,
  subirImagenMiddleware,
  crearPublicacionP2P
};
