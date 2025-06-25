#!/bin/bash

echo "🔍 Docker Network Connectivity Test for tRPC Timeout Debug"
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_connection() {
    local host=$1
    local port=$2
    local service=$3
    
    echo -n "Testing $service ($host:$port)... "
    
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Check if running inside Docker
if [ -f /.dockerenv ]; then
    echo -e "${YELLOW}Running inside Docker container${NC}"
    CONTEXT="container"
else
    echo -e "${YELLOW}Running on host machine${NC}"
    CONTEXT="host"
fi

echo ""
echo "Testing PostgreSQL connections:"
echo "-------------------------------"

# Test different PostgreSQL connection options
if [ "$CONTEXT" = "container" ]; then
    test_connection "host.docker.internal" 54322 "PostgreSQL (host.docker.internal)"
    test_connection "172.17.0.1" 54322 "PostgreSQL (Docker gateway)"
    test_connection "127.0.0.1" 54322 "PostgreSQL (localhost - should fail in container)"
else
    test_connection "127.0.0.1" 54322 "PostgreSQL (localhost)"
    test_connection "172.17.0.1" 54322 "PostgreSQL (Docker gateway)"
fi

echo ""
echo "Testing Supabase API connections:"
echo "---------------------------------"

# Test different Supabase API connection options
if [ "$CONTEXT" = "container" ]; then
    test_connection "host.docker.internal" 54321 "Supabase API (host.docker.internal)"
    test_connection "172.17.0.1" 54321 "Supabase API (Docker gateway)"
    test_connection "127.0.0.1" 54321 "Supabase API (localhost - should fail in container)"
else
    test_connection "127.0.0.1" 54321 "Supabase API (localhost)"
    test_connection "172.17.0.1" 54321 "Supabase API (Docker gateway)"
fi

echo ""
echo "Docker Information:"
echo "------------------"

# Show Docker network info
echo "Docker networks:"
docker network ls 2>/dev/null || echo "Docker command not available"

echo ""
echo "Container connectivity from nginx:"
if docker exec onlook-nginx nslookup onlook-container 2>/dev/null >/dev/null; then
    echo -e "${GREEN}✓ nginx can resolve onlook-container${NC}"
else
    echo -e "${RED}✗ nginx cannot resolve onlook-container${NC}"
fi

echo ""
echo "Environment Variables (if running in Next.js container):"
echo "--------------------------------------------------------"
if [ "$CONTEXT" = "container" ]; then
    echo "SUPABASE_DATABASE_URL: ${SUPABASE_DATABASE_URL:-'NOT SET'}"
    echo "NEXT_PUBLIC_SUPABASE_URL: ${NEXT_PUBLIC_SUPABASE_URL:-'NOT SET'}"
    echo "DOCKER_CONTAINER: ${DOCKER_CONTAINER:-'NOT SET'}"
fi

echo ""
echo "Quick PostgreSQL Connection Test:"
echo "---------------------------------"

# Test actual PostgreSQL connection if psql is available
if command -v psql >/dev/null 2>&1; then
    echo "Testing PostgreSQL connection with psql..."
    
    if [ "$CONTEXT" = "container" ]; then
        PGHOST="host.docker.internal"
    else
        PGHOST="127.0.0.1"
    fi
    
    if PGPASSWORD=postgres psql -h "$PGHOST" -p 54322 -U postgres -d postgres -c "SELECT 1 as test;" 2>/dev/null | grep -q "1"; then
        echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
    else
        echo -e "${RED}✗ PostgreSQL connection failed${NC}"
        echo "Trying alternative hosts..."
        
        for host in "172.17.0.1" "localhost"; do
            if PGPASSWORD=postgres psql -h "$host" -p 54322 -U postgres -d postgres -c "SELECT 1;" 2>/dev/null >/dev/null; then
                echo -e "${GREEN}✓ PostgreSQL connection successful via $host${NC}"
                break
            fi
        done
    fi
else
    echo "psql not available, skipping database connection test"
fi

echo ""
echo "Recommendations:"
echo "---------------"

if [ "$CONTEXT" = "container" ]; then
    echo "1. Use 'host.docker.internal' for connecting to host services from container"
    echo "2. If host.docker.internal fails, try '172.17.0.1' (Docker gateway)"
    echo "3. Avoid '127.0.0.1' when connecting from container to host services"
else
    echo "1. Use '127.0.0.1' or 'localhost' for local connections"
    echo "2. Ensure Supabase is running: 'bun run backend:start'"
    echo "3. Check if ports 54321 and 54322 are open and not blocked"
fi

echo ""
echo "🔍 Test completed. Check the results above to configure your environment variables." 