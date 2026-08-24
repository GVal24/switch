const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env'), override: true });

const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de Middlewares
app.use(cors());
app.use(express.json());

// Imágenes subidas por los usuarios (fotos de publicaciones)
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads')));

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

// Iniciar Servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor Switch corriendo exitosamente en http://localhost:${PORT}`);
});
