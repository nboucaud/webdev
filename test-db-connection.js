const postgres = require('postgres');

// Test with your connection string
//const sql = postgres('postgresql://postgres:YOUR_PASSWORD@webdev.infogito.com:54322/postgres');
const sql = postgres('postgresql://postgres:postgres@178.156.145.61:54322/postgres');

async function testConnection() {
    try {
        const result = await sql`SELECT version()`;
        console.log('✅ Database connection successful!');
        console.log('PostgreSQL version:', result[0].version);
        process.exit(0);
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        process.exit(1);
    }
}

testConnection();
