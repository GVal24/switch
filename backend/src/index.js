const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env'), override: true });

const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');
const almacenImagenes = require('./services/almacenImagenes');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de Middlewares
app.use(cors());
app.use(express.json());

// Imágenes subidas por los usuarios (fotos de publicaciones)
// Imágenes del catálogo.
//
// Se sirven SOLO las que ya fueron aprobadas por moderación. Las que están
// en uploads/_cuarena/ quedan bloqueadas acá: si se sirvieran, cualquiera
// con el nombre del archivo podría ver una imagen que la plataforma todavía
// no aprobó (incluidas las marcadas como posible imagen de un menor).
app.use('/uploads', (req, res, next) => {
  const relativo = decodeURIComponent(req.path || '');
  const partes = relativo.split('/').filter(Boolean);

  if (partes.length === 0 || partes[0] === almacenImagenes.PREFIJO_CUARENA) {
    return res.status(404).json({
      exito: false,
      codigoEstado: 404,
      mensaje: 'La imagen no está disponible.',
    });
  }

  // Cualquier intento de meterse en una subcarpeta (subidas, ..) se rechaza:
  // el catálogo sólo tiene archivos sueltos en la raíz de uploads/.
  if (partes.length > 1) {
    return res.status(404).json({
      exito: false,
      codigoEstado: 404,
      mensaje: 'La imagen no está disponible.',
    });
  }

  return next();
});
app.use('/uploads', express.static(almacenImagenes.DIR_UPLOADS));

// Ruta Raíz - Estado de la API
app.get('/', (req, res) => {
  res.json({
    proyecto: 'Switch',
    estado: 'API REST Operativa',
    version: '2.0.0',
    comunidad: 'Switch'
  });
});

// Rutas de la API
app.use('/api', routes);

// Middleware Centralizado de Gestión de Errores (Siempre al final)
app.use(errorHandler);

// Se exporta la app para que las pruebas puedan levantarla en un puerto
// efímero. Sólo se inicia el servidor cuando el archivo se ejecuta directo.
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`🚀 Servidor Switch corriendo exitosamente en http://localhost:${PORT}`);
  });
}

module.exports = app;
