#!/bin/bash
# Fix database connection issues for Prisma and Supabase development

echo "🔧 Fixing database connection configuration..."

# Set environment variables for current session
export DATABASE_URL="postgresql://postgres:eberebe32-PW@localhost:5433/postgres"
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5433"
export POSTGRES_DB="postgres" 
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="eberebe32-PW"

# Check if databases are running
echo "📊 Checking database connectivity..."

# Check Supabase database (internal)
if docker exec supabase-db pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
    echo "✅ Supabase database (db:5432) is ready"
    SUPABASE_DB_READY=true
else
    echo "❌ Supabase database is not ready"
    SUPABASE_DB_READY=false
fi

# Check standalone PostgreSQL (external)
if docker exec localai-postgres-1 pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
    echo "✅ Standalone PostgreSQL (localhost:5433) is ready"
    STANDALONE_DB_READY=true
else
    echo "❌ Standalone PostgreSQL is not ready"
    STANDALONE_DB_READY=false
fi

# Test connections
echo "🧪 Testing database connections..."

if $SUPABASE_DB_READY; then
    echo "🔗 Supabase DB connection string: postgresql://postgres:eberebe32-PW@localhost:8000/postgres"
fi

if $STANDALONE_DB_READY; then
    echo "🔗 Standalone DB connection string: postgresql://postgres:eberebe32-PW@localhost:5433/postgres"
fi

echo "✅ Database connection fix complete!"
echo ""
echo "If running Prisma commands, use:"
echo "export DATABASE_URL=\"postgresql://postgres:eberebe32-PW@localhost:5433/postgres\""
echo "or connect via Supabase pooler:"
echo "export DATABASE_URL=\"postgresql://postgres:eberebe32-PW@localhost:5432/postgres\""