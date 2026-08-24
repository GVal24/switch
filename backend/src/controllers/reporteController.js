const asyncWrapper = require('../middlewares/asyncWrapper');
const { ValidationError, NotFoundError } = require('../utils/customErrors');
const ReporteModel = require('../models/reporteModel');
const UsuarioModel = require('../models/usuarioModel');

/**
 * POST /api/reportes
 * Body: { reportanteId, reportanteNombre?, reportadoId, reportadoNombre?, motivo }
 */
const reportarUsuario = asyncWrapper(async (req, res) => {
  const { reportanteNombre, reportadoId, reportadoNombre, motivo } = req.body;
  // El reportante siempre es el usuario de la sesión (no se confía en el body)
  const reportanteId = req.usuario.id;

  // El reportado es opcional: un reporte sin él es un "inconveniente general"
  if (!motivo || String(motivo).trim() === '') {
    throw new ValidationError('Se requiere el motivo de la denuncia.');
  }

  await ReporteModel.crear({
    reportanteId,
    reportanteNombre,
    reportadoId,
    reportadoNombre,
    motivo: String(motivo).trim()
  });

  res.status(201).json({
    exito: true,
    mensaje: 'Reporte enviado a administración con éxito.'
  });
});

/**
 * GET /api/admin/reportes
 */
const listarReportes = asyncWrapper(async (req, res) => {
  const reportes = await ReporteModel.obtenerTodos();
  res.status(200).json({
    exito: true,
    reportes
  });
});

/**
 * POST /api/admin/reportes/:reporteId/desestimar
 */
const desestimarReporte = asyncWrapper(async (req, res) => {
  const { reporteId } = req.params;

  const actualizado = await ReporteModel.actualizarEstado(reporteId, 'DESESTIMADO');
  if (!actualizado) {
    throw new NotFoundError('El reporte indicado no existe.');
  }

  res.status(200).json({
    exito: true,
    mensaje: 'Reporte desestimado.',
    datos: actualizado
  });
});

/**
 * POST /api/admin/dar-de-baja
 * Body: { usuarioId, reporteId? }
 * Da de baja al usuario y marca el reporte asociado como RESUELTO_BAN.
 */
const darDeBajaUsuario = asyncWrapper(async (req, res) => {
  const { usuarioId, reporteId } = req.body;

  if (!usuarioId) {
    throw new ValidationError("Se requiere el 'usuarioId' a dar de baja.");
  }

  const usuarioBajado = await UsuarioModel.darDeBaja(usuarioId);
  if (!usuarioBajado) {
    throw new NotFoundError('El usuario indicado no existe.');
  }

  if (reporteId) {
    await ReporteModel.actualizarEstado(reporteId, 'RESUELTO_BAN');
  }

  res.status(200).json({
    exito: true,
    mensaje: `El usuario ${usuarioBajado.nombre} ${usuarioBajado.apellido} fue dado de baja definitivamente.`,
    datos: usuarioBajado
  });
});

/**
 * POST /api/admin/suspender
 * Body: { usuarioId, dias, reporteId? }
 * Suspende al usuario por N días y marca el reporte como RESUELTO_SUSPENSION.
 */
const suspenderUsuario = asyncWrapper(async (req, res) => {
  const { usuarioId, dias, reporteId } = req.body;

  if (!usuarioId) {
    throw new ValidationError("Se requiere el 'usuarioId' a suspender.");
  }

  // dias = 0 o null => levanta la suspensión existente
  if (dias != null && Number(dias) !== 0 && (!dias || Number(dias) < 0)) {
    throw new ValidationError('La cantidad de días debe ser positiva (o 0 para levantar la suspensión).');
  }

  const usuarioSuspendido = await UsuarioModel.suspender(usuarioId, dias ? Number(dias) : 0);
  if (!usuarioSuspendido) {
    throw new NotFoundError('El usuario indicado no existe.');
  }

  if (reporteId) {
    await ReporteModel.actualizarEstado(reporteId, 'RESUELTO_SUSPENSION');
  }

  const mensaje = dias && Number(dias) > 0
    ? `El usuario ${usuarioSuspendido.nombre} ${usuarioSuspendido.apellido} fue suspendido hasta el ${usuarioSuspendido.suspendido_hasta}.`
    : `Se levantó la suspensión de ${usuarioSuspendido.nombre} ${usuarioSuspendido.apellido}.`;

  res.status(200).json({
    exito: true,
    mensaje,
    datos: usuarioSuspendido
  });
});

module.exports = {
  reportarUsuario,
  listarReportes,
  desestimarReporte,
  darDeBajaUsuario,
  suspenderUsuario
};
