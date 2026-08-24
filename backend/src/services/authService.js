const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UsuarioModel = require('../models/usuarioModel');
const { ValidationError, NotFoundError, ConflictError, UnauthorizedError, ForbiddenError } = require('../utils/customErrors');

class AuthService {
  /**
   * Valida reglas de negocio y registra un nuevo usuario
   */
  static async registrarUsuario({ dni, nombre, apellido, telefono, password, esMayorEdad, aceptoTerminos }) {
    if (!dni || !nombre || !apellido || !telefono || !password) {
      throw new ValidationError("Todos los campos (incluyendo la contraseña) son obligatorios.");
    }

    if (password.length < 6) {
      throw new ValidationError("La contraseña debe tener al menos 6 caracteres.");
    }

    if (esMayorEdad !== true) {
      throw new ValidationError("Es requisito obligatorio ser mayor de 18 años para registrarse en Switch.");
    }

    if (aceptoTerminos !== true) {
      throw new ValidationError("Es obligatorio aceptar los Términos y Condiciones.");
    }

    const usuarioExistente = await UsuarioModel.buscarPorDniOTelefono(dni, telefono);

    if (usuarioExistente) {
      const existeDni = usuarioExistente.dni === dni;
      const existeTelefono = usuarioExistente.telefono === telefono;

      if (existeDni && existeTelefono) {
        throw new ConflictError("El DNI y el teléfono ingresados ya se encuentran registrados.");
      } else if (existeDni) {
        throw new ConflictError("El DNI ingresado ya pertenece a un usuario registrado en Switch.");
      } else {
        throw new ConflictError("El número de teléfono ya se encuentra registrado en Switch.");
      }
    }

    // Encriptado de contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    return await UsuarioModel.crear({
      dni,
      nombre,
      apellido,
      telefono,
      esMayorEdad,
      password: hashedPassword
    });
  }

  /**
   * Autentica credenciales de ingreso
   */
  static async loginUsuario({ dni, password }) {
    if (!dni || !password) {
      throw new ValidationError("DNI y contraseña son requeridos para ingresar.");
    }

    const usuario = await UsuarioModel.buscarPorDni(dni);

    if (!usuario) {
      throw new NotFoundError("No encontramos ningún usuario registrado con ese DNI.");
    }

    if (usuario.activo === false) {
      throw new ForbiddenError("Tu cuenta fue bloqueada permanentemente por la administración de Switch. Comunicate con soporte.");
    }

    // Suspensión temporal: si ya venció se limpia automáticamente
    if (usuario.suspendido_hasta) {
      const fin = new Date(usuario.suspendido_hasta);
      if (fin > new Date()) {
        const fecha = `${String(fin.getDate()).padStart(2, '0')}/${String(fin.getMonth() + 1).padStart(2, '0')}/${fin.getFullYear()}`;
        throw new ForbiddenError(`Tu cuenta está suspendida hasta el ${fecha}. No podés ingresar hasta esa fecha.`);
      }
      await UsuarioModel.levantarSuspension(usuario.id);
    }

    // Verificar la contraseña con bcrypt
    const passwordValida = await bcrypt.compare(password, usuario.password);

    if (!passwordValida) {
      throw new UnauthorizedError("Contraseña incorrecta. Por favor verificá tus datos.");
    }

    // Limpiamos el hash por seguridad antes de retornarlo
    delete usuario.password;
    delete usuario.activo;
    delete usuario.suspendido_hasta;

    // Token de sesión válido por 7 días
    const token = jwt.sign(
      { id: usuario.id, rol: usuario.rol },
      process.env.JWT_SECRET || 'switch_secreto_temporal',
      { expiresIn: '7d' }
    );

    return { ...usuario, token };
  }
}

module.exports = AuthService;