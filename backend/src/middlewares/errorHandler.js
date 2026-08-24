const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || "Ocurrió un error interno en el servidor de Switch.";

  // Manejo de códigos específicos de PostgreSQL
  if (err.code === '23505') { // Constraint UNIQUE violada (DNI o Teléfono duplicado)
    statusCode = 409;
    message = "El DNI o número de teléfono ya se encuentra registrado en Switch.";
  }

  if (err.code === '23503') { // Foreign Key no existente
    statusCode = 400;
    message = "La referencia a la institución o recurso no es válida.";
  }

  if (err.code === '22P02') { // Sintaxis inválida (ej. UUID mal formado)
    statusCode = 400;
    message = "El formato del identificador (UUID) ingresado no es válido.";
  }

  if (statusCode === 500) {
    console.error("🔴 ERROR CRÍTICO NO CONTROLADO:", err);
  } else {
    console.warn(`⚠️ Excepción de negocio [${statusCode}]: ${message}`);
  }

  res.status(statusCode).json({
    exito: false,
    codigoEstado: statusCode,
    mensaje: message,
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
};

module.exports = errorHandler;