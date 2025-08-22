# Database Connection Fix - Prisma P1000 Error

This document explains how to fix the Prisma authentication error and database connection issues.

## The Problem

When running Prisma commands or Supabase development commands, you may encounter:

```
Error: P1000: Authentication failed against database server at `postgres`, the provided database credentials for `postgres` are not valid.
```

## Root Cause

The error occurs because:
1. Prisma schema is trying to connect to `postgres:5432` 
2. Your setup has databases at different locations:
   - **Supabase DB**: `db:5432` (internal Docker network) / `localhost:5432` (via pooler)
   - **Standalone PostgreSQL**: `localhost:5433` (external access)

## Permanent Solutions Applied

### 1. Environment Variables Setup
The `start_services.py` script now automatically sets:
```bash
DATABASE_URL="postgresql://postgres:eberebe32-PW@localhost:5433/postgres"
SUPABASE_DATABASE_URL="postgresql://postgres:eberebe32-PW@localhost:5432/postgres"
POSTGRES_HOST="localhost"
POSTGRES_PORT="5433"
```

### 2. Local Environment File
Created `/supabase/.env.local` with proper database URLs for development.

### 3. Connection Fix Script
Use `./fix-database-connection.sh` to set environment variables manually.

## Manual Fix (if needed)

If you encounter the error when running commands in the `supabase/` directory:

```bash
# Option 1: Use standalone PostgreSQL
export DATABASE_URL="postgresql://postgres:eberebe32-PW@localhost:5433/postgres"

# Option 2: Use Supabase via pooler
export DATABASE_URL="postgresql://postgres:eberebe32-PW@localhost:5432/postgres"

# Then run your command
pnpm build  # or whatever command was failing
```

## Available Database Connections

### 1. Standalone PostgreSQL (Recommended for Development)
- **Host**: `localhost:5433`
- **Connection**: `postgresql://postgres:eberebe32-PW@localhost:5433/postgres`
- **Use case**: External tools, Prisma migrations, development

### 2. Supabase Database (Internal)
- **Host**: `db:5432` (internal) / `localhost:5432` (via pooler)
- **Connection**: `postgresql://postgres:eberebe32-PW@localhost:5432/postgres`
- **Use case**: Supabase services, applications

## Testing Connections

```bash
# Test standalone PostgreSQL
docker exec localai-postgres-1 pg_isready -h localhost -p 5432 -U postgres

# Test Supabase database
docker exec supabase-db pg_isready -h localhost -p 5432 -U postgres

# Test external connections
psql "postgresql://postgres:eberebe32-PW@localhost:5433/postgres" -c "SELECT version();"
psql "postgresql://postgres:eberebe32-PW@localhost:5432/postgres" -c "SELECT version();"
```

## Common Commands That Might Trigger This Error

- `pnpm build` in the supabase directory
- `pnpm dev` in the supabase directory  
- `npx prisma migrate` or similar Prisma commands
- Any command that tries to connect to a database

## Prevention

The permanent fixes ensure that:
1. Environment variables are set automatically when starting services
2. Proper connection strings are available for development
3. Both database options are accessible

This prevents the P1000 error from recurring in future development work.