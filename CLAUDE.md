# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a **self-hosted AI platform** built on Docker Compose that combines multiple AI and infrastructure services:

### Core Components
- **n8n** - Low-code automation platform with AI workflow capabilities (port 5678)
- **Ollama** - Local LLM serving platform with GPU support (port 11434)
- **Open WebUI** - ChatGPT-like interface for interacting with local models and n8n agents (port 3000/8080)
- **Supabase** - Complete backend-as-a-service with PostgreSQL, authentication, and APIs
- **Qdrant** - Vector database for RAG applications (port 6333)

### Additional Services
- **Flowise** - Visual AI agent builder (port 3001)
- **Neo4j** - Graph database for knowledge graphs (ports 7473/7474/7687)
- **Langfuse** - LLM observability and analytics platform (port 3000)
- **SearXNG** - Privacy-focused search engine aggregator (port 8080)
- **Caddy** - Reverse proxy with automatic HTTPS (ports 80/443)

## Common Commands

### Starting Services
Use the Python script to manage all services:

```bash
# Start with CPU-only
python start_services.py --profile cpu

# Start with NVIDIA GPU support
python start_services.py --profile gpu-nvidia

# Start with AMD GPU support (Linux only)
python start_services.py --profile gpu-amd

# Local Ollama (no containerized LLM)
python start_services.py --profile none

# Production deployment (closed ports except 80/443)
python start_services.py --profile gpu-nvidia --environment public
```

### Docker Compose Management
The project uses a unified Docker Compose setup with the project name "localai":

```bash
# Stop all services
docker compose -p localai -f docker-compose.yml --profile <profile> down

# View logs
docker compose -p localai logs -f [service-name]

# Update containers
docker compose -p localai pull
```

### Service Access Points
- n8n: http://localhost:5678
- Open WebUI: http://localhost:3000
- Flowise: http://localhost:3001
- Supabase Studio: http://localhost:3000 (via Caddy routing)
- Langfuse: http://localhost:3002 (via Caddy routing)

## Environment Configuration

### Required Environment Variables
The `.env` file must include:
- **N8N_ENCRYPTION_KEY**, **N8N_USER_MANAGEMENT_JWT_SECRET** - n8n security
- **POSTGRES_PASSWORD** - Database password for Supabase
- **JWT_SECRET**, **ANON_KEY**, **SERVICE_ROLE_KEY** - Supabase authentication
- **NEO4J_AUTH** - Neo4j credentials (format: neo4j/password)
- **LANGFUSE_SALT**, **NEXTAUTH_SECRET**, **ENCRYPTION_KEY** - Langfuse security
- **CLICKHOUSE_PASSWORD**, **MINIO_ROOT_PASSWORD** - Backend service credentials

### GPU Profiles
The system supports multiple GPU configurations via Docker Compose profiles:
- `cpu` - CPU-only execution
- `gpu-nvidia` - NVIDIA GPU with CUDA support
- `gpu-amd` - AMD GPU with ROCm support (Linux only)

## Service Integration

### n8n Workflows
Pre-configured workflows are automatically imported from `/n8n/backup/workflows/`:
- V1_Local_RAG_AI_Agent.json
- V2_Local_Supabase_RAG_AI_Agent.json  
- V3_Local_Agentic_RAG_AI_Agent.json

### Open WebUI Integration
The `n8n_pipe.py` function enables n8n workflow execution from Open WebUI chat interface.

### Database Connections
- **n8n database**: PostgreSQL via Supabase (host: `db`, port: 5432)
- **Qdrant**: Vector operations (host: `qdrant`, port: 6333)
- **Neo4j**: Graph operations (host: `neo4j`, ports: 7474/7687)

## Development Notes

### File Sharing
- Local files accessible in n8n at `/data/shared` (mapped from `./shared` directory)
- Flowise data persisted in `~/.flowise`
- All service data persisted via Docker volumes

### Security Considerations
- Production deployments should use `--environment public` to close non-essential ports
- Caddy provides automatic HTTPS with Let's Encrypt when domain names are configured
- SearXNG requires secret key generation (handled automatically by start script)

### Troubleshooting
- Supabase pooler issues: Add `POOLER_DB_POOL_SIZE=5` to .env
- GPU support: Follow Ollama Docker GPU setup instructions
- SearXNG first-run: Script temporarily disables security constraints for initialization

## Supabase Development (supabase/ directory)

The embedded Supabase instance includes standard development commands:
```bash
cd supabase
pnpm build          # Build all packages
pnpm dev            # Start development servers
pnpm lint           # Lint codebase
pnpm typecheck      # Type checking
```