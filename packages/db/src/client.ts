import * as schema from '@onlook/db/src/schema';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

/**
 * Cache the database connection in development. This avoids creating a new connection on every HMR
 * update.
 */
const globalForDb = globalThis as unknown as {
    conn: postgres.Sql | undefined;
};

/**
 * Get the appropriate database URL based on environment
 * - Docker container: use container name and internal port
 * - External: use external IP and port
 */
function getDatabaseUrl(): string {
    const baseUrl = process.env.SUPABASE_DATABASE_URL!;

    // Check if we're running in a Docker container
    const isDocker =
        process.env.DOCKER_CONTAINER === 'true' ||
        process.env.NODE_ENV === 'production' ||
        process.env.CONTAINER_NAME ||
        process.env.HOSTNAME?.startsWith('docker') ||
        require('fs').existsSync('/.dockerenv');

    // If in Docker and using external IP, convert to container networking
    if (isDocker && baseUrl.includes('178.156.145.61:54322')) {
        const dockerUrl = baseUrl.replace('178.156.145.61:54322', 'supabase_db_onlook-web:5432');
        console.log('🐳 Using Docker container networking:', dockerUrl);
        return dockerUrl;
    }

    console.log('🌐 Using external database connection:', baseUrl);
    return baseUrl;
}

// Enhanced connection options for better reliability
const connectionOptions: postgres.Options<{}> = {
    prepare: false,
    // Timeout settings
    connect_timeout: 15, // 15 seconds to connect
    idle_timeout: 30, // 30 seconds idle timeout
    max_lifetime: 3600, // 1 hour max lifetime
    // Connection pool
    max: 10,
    // Transform undefined to null
    transform: {
        undefined: null,
    },
    // Connection parameters
    connection: {
        application_name: 'onlook-app',
        timezone: 'UTC',
    },
};

const conn = globalForDb.conn ?? postgres(getDatabaseUrl(), connectionOptions);
if (process.env.NODE_ENV !== 'production') globalForDb.conn = conn;

export const db = drizzle(conn, { schema });
