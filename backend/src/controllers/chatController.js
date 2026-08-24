const asyncWrapper = require('../middlewares/asyncWrapper');
const { ValidationError } = require('../utils/customErrors');
const ChatModel = require('../models/chatModel');

/**
 * GET /api/mensajes?emisorId=..&receptorId=..
 * Devuelve la conversación entre dos participantes.
 */
const obtenerMensajes = asyncWrapper(async (req, res) => {
  // El emisor siempre es el usuario de la sesión (no se confía en el query)
  const emisorId = req.usuario.id;
  const receptorId = req.query.receptorId || req.query.receptor_id;

  if (!receptorId) {
    throw new ValidationError("Se requiere el parámetro 'receptorId'.");
  }

  const mensajes = await ChatModel.obtenerConversacion(emisorId, receptorId);

  res.status(200).json({
    exito: true,
    datos: mensajes,
    mensajes
  });
});

/**
 * POST /api/mensajes/enviar
 * Body: { emisorId, receptorId, receptorNombre?, texto }
 */
const enviarMensaje = asyncWrapper(async (req, res) => {
  // El emisor siempre es el usuario de la sesión (no se confía en el body)
  const emisorId = req.usuario.id;
  const receptorId = req.body.receptorId || req.body.receptor_id;
  const receptorNombre = req.body.receptorNombre || 'Contacto';
  const texto = req.body.texto || req.body.mensaje;

  if (!receptorId) {
    throw new ValidationError("Se requiere 'receptorId'.");
  }
  if (!texto || String(texto).trim() === '') {
    throw new ValidationError('El mensaje no puede estar vacío.');
  }

  const nuevoMensaje = await ChatModel.crearMensaje({
    emisorId,
    receptorId,
    texto: String(texto).trim()
  });

  // Respuesta automática simulada si el receptor es una institución ("inst_X")
  if (String(receptorId).startsWith('inst_')) {
    setTimeout(async () => {
      try {
        await ChatModel.crearMensaje({
          emisorId: receptorId,
          receptorId: emisorId,
          texto: `¡Hola! Gracias por comunicarte con ${receptorNombre}. Podés coordinar con nosotros tu día de voluntariado.`
        });
      } catch (e) {
        console.error('Error en la respuesta automática del chat:', e.message);
      }
    }, 1200);
  }

  res.status(201).json({
    exito: true,
    mensaje: nuevoMensaje
  });
});

module.exports = {
  obtenerMensajes,
  enviarMensaje
};
