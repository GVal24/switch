const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'switch_db', 
  password: process.env.DB_PASSWORD || '1234', 
  port: process.env.DB_PORT || 5432,
});

pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Error al conectar con PostgreSQL:', err.stack);
  } else {
    console.log('🟢 Conexión exitosa a PostgreSQL (switch_db)');
    release();
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};