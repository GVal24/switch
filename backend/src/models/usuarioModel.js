const db = require('../config/db');
const { calcularImpacto } = require('../utils/gamificacion');

class UsuarioModel {
  /**
   * Busca un usuario por DNI incluyendo su contraseña encriptada (para Login)
   */
  static async buscarPorDni(dni) {
    const query = `
      SELECT 
        id, 
        dni, 
        nombre, 
        apellido, 
        telefono, 
        password,
        validado_mayor_edad, 
        rol, 
        activo,
        suspendido_hasta,
        TO_CHAR(creado_en AT TIME ZONE 'America/Argentina/Buenos_Aires', 'DD/MM/YYYY HH24:MI') AS creado_en
      FROM usuarios 
      WHERE dni = $1 
      LIMIT 1;
    `;
    const result = await db.query(query, [dni]);
    return result.rows[0] || null;
  }

  /**
   * Busca un usuario por DNI o Teléfono para verificar duplicados
   */
  static async buscarPorDniOTelefono(dni, telefono) {
    const query = `
      SELECT id, dni, telefono 
      FROM usuarios 
      WHERE dni = $1 OR telefono = $2 
      LIMIT 1;
    `;
    const result = await db.query(query, [dni, telefono]);
    return result.rows[0] || null;
  }

  /**
   * Inserta un nuevo usuario guardando el hash de la contraseña
   */
  static async crear({ dni, nombre, apellido, telefono, esMayorEdad, password }) {
    const query = `
      INSERT INTO usuarios (dni, nombre, apellido, telefono, validado_mayor_edad, password)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, dni, nombre, apellido, telefono, validado_mayor_edad, rol, creado_en;
    `;
    const values = [dni, nombre, apellido, telefono, esMayorEdad, password];
    
    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Da de baja lógica definitiva a un usuario (bloqueo permanente por administración)
   */
  static async darDeBaja(usuarioId) {
    const query = `
      UPDATE usuarios
      SET activo = FALSE, suspendido_hasta = NULL
      WHERE id = $1
      RETURNING id, dni, nombre, apellido, activo;
    `;
    const result = await db.query(query, [usuarioId]);
    return result.rows[0] || null;
  }

  /**
   * Suspende a un usuario por una cantidad de días (bloqueo temporal).
   * Si dias es null o 0, levanta la suspensión.
   */
  static async suspender(usuarioId, dias) {
    if (!dias || Number(dias) <= 0) {
      return this.levantarSuspension(usuarioId);
    }
    const query = `
      UPDATE usuarios
      SET suspendido_hasta = CURRENT_TIMESTAMP + ($2 || ' days')::interval,
          activo = TRUE
      WHERE id = $1
      RETURNING id, dni, nombre, apellido, TO_CHAR(suspendido_hasta AT TIME ZONE 'America/Argentina/Buenos_Aires', 'DD/MM/YYYY') AS suspendido_hasta;
    `;
    const result = await db.query(query, [usuarioId, String(Number(dias))]);
    return result.rows[0] || null;
  }

  /**
   * Levanta la suspensión de un usuario
   */
  static async levantarSuspension(usuarioId) {
    const result = await db.query(
      `UPDATE usuarios SET suspendido_hasta = NULL 
       WHERE id = $1
       RETURNING id, dni, nombre, apellido;`,
      [usuarioId]
    );
    return result.rows[0] || null;
  }

  /**
   * Devuelve los datos del usuario junto a sus estadísticas reales:
   * trueques completados, voluntariados y reputación (reseñas recibidas).
   */
  static async obtenerPerfilConEstadisticas(usuarioId) {
    const queryUsuario = `
      SELECT 
        id, 
        dni, 
        nombre, 
        apellido, 
        telefono, 
        validado_mayor_edad, 
        rol,
        TO_CHAR(creado_en AT TIME ZONE 'America/Argentina/Buenos_Aires', 'DD/MM/YYYY') AS miembro_desde
      FROM usuarios 
      WHERE id = $1 AND activo = TRUE
      LIMIT 1;
    `;

    const queryStats = `
      SELECT
        (SELECT COUNT(*) FROM intercambios
          WHERE estado = 'COMPLETADO' AND (dueno_id = $1 OR ofertante_id = $1)) AS trueques_completados,
        (SELECT COUNT(*) FROM nexos_sociales WHERE usuario_id = $1) AS voluntariados,
        (SELECT COALESCE(ROUND(AVG(puntaje)::numeric, 1), 0) FROM resenas WHERE destino_id = $1) AS calificacion_promedio,
        (SELECT COUNT(*) FROM resenas WHERE destino_id = $1) AS cantidad_resenas,
        (SELECT COUNT(*) FROM nexos_sociales
          WHERE usuario_id = $1 AND EXTRACT(HOUR FROM (fecha_activacion AT TIME ZONE 'America/Argentina/Buenos_Aires')) < 8) AS voluntariados_madrugada;
    `;

    const [resUsuario, resStats] = await Promise.all([
      db.query(queryUsuario, [usuarioId]),
      db.query(queryStats, [usuarioId])
    ]);

    if (resUsuario.rowCount === 0) return null;

    const stats = resStats.rows[0];
    const estadisticas = {
      truequesCompletados: Number(stats.trueques_completados),
      voluntariados: Number(stats.voluntariados),
      calificacionPromedio: parseFloat(stats.calificacion_promedio),
      cantidadResenas: Number(stats.cantidad_resenas),
      // Pionero: uno de los primeros vecinos en registrarse en la plataforma
      esPionero: Number(resUsuario.rows[0].id) <= 10,
      voluntariadosMadrugada: Number(stats.voluntariados_madrugada)
    };

    return {
      ...resUsuario.rows[0],
      estadisticas,
      impacto: calcularImpacto(estadisticas)
    };
  }

  /**
   * Devuelve el nombre de pila de un usuario (para propuestas de trueque).
   */
  static async obtenerNombrePorId(usuarioId) {
    const result = await db.query(
      `SELECT nombre FROM usuarios WHERE id = $1 LIMIT 1;`,
      [usuarioId]
    );
    return result.rows[0]?.nombre || 'Vecino/a';
  }
}

module.exports = UsuarioModel;