/**
 * Migracion: agrega `usuarios.motivo_suspension`.
 *
 * Por que: al marcar una publicacion sin imagen como "posible imagen de
 * menor" (Ley 26.061) el modelo escribe el motivo de la suspension en esa
 * columna. La columna no existia, asi que ese camino reventaba con un error
 * de PostgreSQL (42703: la columna "motivo_suspension" no existe) y la
 * cuenta del autor nunca quedaba suspendida.
 *
 * Es idempotente: se puede correr las veces que haga falta.
 */
require('dotenv').config();
const db = require('../src/config/db');

(async () => {
  try {
    const existe = await db.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_name = 'usuarios' AND column_name = 'motivo_suspension'`
    );

    if (existe.rowCount > 0) {
      console.log('La columna usuarios.motivo_suspension ya existe. Nada que hacer.');
    } else {
      await db.query('ALTER TABLE usuarios ADD COLUMN motivo_suspension TEXT NULL');
      console.log('Columna usuarios.motivo_suspension agregada.');
    }

    const cols = await db.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_name = 'usuarios' ORDER BY ordinal_position`
    );
    console.log('Columnas actuales:', cols.rows.map((c) => c.column_name).join(', '));
  } catch (err) {
    console.error('Fallo la migracion:', err.message);
    process.exitCode = 1;
  } finally {
    process.exit();
  }
})();
