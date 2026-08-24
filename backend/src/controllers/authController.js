const asyncWrapper = require('../middlewares/asyncWrapper');
const AuthService = require('../services/authService');

const registrarUsuario = asyncWrapper(async (req, res) => {
  const aceptoTerminos = req.body.aceptoTerminos ?? req.body.acepto_terminos;
  const esMayorEdad = req.body.esMayorEdad ?? req.body.es_mayor_edad;

  const nuevoUsuario = await AuthService.registrarUsuario({
    ...req.body,
    aceptoTerminos,
    esMayorEdad
  });

  res.status(201).json({
    exito: true,
    mensaje: "Usuario registrado exitosamente en Switch.",
    datos: nuevoUsuario
  });
});

const loginUsuario = asyncWrapper(async (req, res) => {
  const usuario = await AuthService.loginUsuario(req.body);

  res.status(200).json({
    exito: true,
    mensaje: `¡Bienvenido/a de nuevo, ${usuario.nombre}!`,
    datos: usuario
  });
});

module.exports = {
  registrarUsuario,
  loginUsuario
};