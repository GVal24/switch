const jwt = require('jsonwebtoken');

/**
 * Verifica que la petición traiga un token de sesión válido.
 * Deja los datos del usuario en req.usuario = { id, rol }.
 */
function requerirSesion(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({
      exito: false,
      codigoEstado: 401,
      mensaje: 'Necesitás iniciar sesión para hacer esta operación.'
    });
  }

  try {
    req.usuario = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch (e) {
    return res.status(401).json({
      exito: false,
      codigoEstado: 401,
      mensaje: 'Tu sesión expiró o no es válida. Iniciá sesión de nuevo.'
    });
  }
}

/**
 * Restringe el acceso a usuarios con rol ADMIN.
 * Debe usarse SIEMPRE después de requerirSesion.
 */
function requerirAdmin(req, res, next) {
  if (!req.usuario || req.usuario.rol !== 'ADMIN') {
    return res.status(403).json({
      exito: false,
      codigoEstado: 403,
      mensaje: 'Esta sección es exclusiva de la administración de Switch.'
    });
  }
  return next();
}

module.exports = {
  requerirSesion,
  requerirAdmin
};
