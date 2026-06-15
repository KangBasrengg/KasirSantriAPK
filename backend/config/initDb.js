const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const pool = require('./db');

async function initDatabase() {
  try {
    console.log('🔄 Initializing database...\n');

    // Read and execute schema
    const schemaPath = path.join(__dirname, '..', 'models', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Split by semicolons and execute each statement
    const statements = schema.split(';').filter(s => s.trim().length > 0);

    for (const statement of statements) {
      try {
        await pool.query(statement);
      } catch (err) {
        // Skip errors for IF NOT EXISTS statements
        if (!err.message.includes('already exists')) {
          console.warn(`⚠️  Warning: ${err.message}`);
        }
      }
    }

    // Create proper admin user with correct bcrypt hash
    const adminPassword = await bcrypt.hash('admin123', 10);
    await pool.query(
      `INSERT INTO users (nama, email, password_hash, role) VALUES ($1, $2, $3, $4) ON CONFLICT (email) DO UPDATE SET password_hash = $3`,
      ['Admin', 'admin@tokokas.com', adminPassword, 'admin']
    );

    console.log('✅ Database initialized successfully!');
    console.log('👤 Default admin: admin@tokokas.com / admin123\n');

    process.exit(0);
  } catch (err) {
    console.error('❌ Database initialization failed:', err);
    process.exit(1);
  }
}

initDatabase();
