# Installing Wildcard SSL Certificates in Caddy

This tutorial shows how to install custom SSL certificates (like wildcard certificates) in a Dockerized Caddy setup instead of using Let's Encrypt automatic certificates.

## Prerequisites

- Docker Compose setup with Caddy
- SSL certificate files (certificate and private key)
- Domain names configured in DNS

## Step 1: Prepare Certificate Files

First, locate your certificate files. In this example, we had:
- `~/tmp/Certyfikat SSL Wildcard.txt` (certificate file)
- `~/tmp/privateKey (1).txt` (private key file)

Create a certificates directory in your project:
```bash
mkdir -p /path/to/your/project/certs
```

Copy and rename your certificate files with proper extensions:
```bash
# Copy certificate file
cp "~/tmp/Certyfikat SSL Wildcard.txt" /path/to/your/project/certs/wildcard.crt

# Copy private key file  
cp "~/tmp/privateKey (1).txt" /path/to/your/project/certs/wildcard.key
```

## Step 2: Set Correct File Permissions

Set appropriate permissions for the certificate files:
```bash
# Make certificate readable by Caddy container user (UID 100)
sudo chown 100:100 /path/to/your/project/certs/wildcard.crt
sudo chown 100:100 /path/to/your/project/certs/wildcard.key

# Set proper permissions
sudo chmod 644 /path/to/your/project/certs/wildcard.crt
sudo chmod 644 /path/to/your/project/certs/wildcard.key
```

## Step 3: Mount Certificates in Docker Compose

Edit your `docker-compose.yml` file to mount the certificates directory into the Caddy container:

```yaml
services:
  caddy:
    container_name: caddy
    image: docker.io/library/caddy:2-alpine
    restart: unless-stopped
    ports:
      - 80:80/tcp
      - 443:443/tcp
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy-addon:/etc/caddy/addons:ro
      - ./certs:/etc/caddy/certs:ro  # Add this line
      - caddy-data:/data:rw
      - caddy-config:/config:rw
    environment:
      # Your environment variables...
```

## Step 4: Configure Caddyfile

Update your `Caddyfile` to use the custom certificates instead of Let's Encrypt:

### Original configuration:
```caddyfile
# N8N
{$N8N_HOSTNAME} {
    # For domains, Caddy will automatically use Let's Encrypt
    reverse_proxy n8n:5678
}
```

### Updated configuration with custom certificate:
```caddyfile
# N8N
{$N8N_HOSTNAME} {
    tls /etc/caddy/certs/wildcard.crt /etc/caddy/certs/wildcard.key
    reverse_proxy n8n:5678
}
```

Apply the same pattern to all your services:
```caddyfile
# Open WebUI
{$WEBUI_HOSTNAME} {
    tls /etc/caddy/certs/wildcard.crt /etc/caddy/certs/wildcard.key
    reverse_proxy open-webui:8080
}

# Flowise
{$FLOWISE_HOSTNAME} {
    tls /etc/caddy/certs/wildcard.crt /etc/caddy/certs/wildcard.key
    reverse_proxy flowise:3001
}

# Add to other services as needed...
```

## Step 5: Restart Caddy

Restart the Caddy container to apply the new configuration:
```bash
docker compose -p your-project-name restart caddy
```

Check if Caddy started successfully:
```bash
docker compose -p your-project-name ps caddy
docker compose -p your-project-name logs caddy --tail 10
```

## Step 6: Test HTTPS Access

Test that HTTPS is working with your custom certificate:

```bash
# Test with certificate validation (may show warnings if chain is incomplete)
curl -I https://your-domain.com

# Test ignoring certificate validation (should work)
curl -k -I https://your-domain.com

# Test full page access
curl -k https://your-domain.com
```

## Troubleshooting

### Common Issues and Solutions

1. **Permission Denied Error**
   ```
   Error: open /etc/caddy/certs/wildcard.key: permission denied
   ```
   **Solution:** Fix file ownership and permissions:
   ```bash
   sudo chown 100:100 /path/to/certs/*
   sudo chmod 644 /path/to/certs/*
   ```

2. **File Not Found Error**
   ```
   Error: open /etc/caddy/certs/wildcard.crt: no such file or directory
   ```
   **Solution:** Verify the mount path in docker-compose.yml and that files exist:
   ```bash
   ls -la /path/to/your/project/certs/
   docker exec caddy ls -la /etc/caddy/certs/
   ```

3. **Certificate Chain Issues**
   If browsers show certificate warnings, your certificate might need the full chain. Contact your certificate provider for the complete certificate chain.

4. **Caddy Won't Start**
   Check Caddy logs for specific errors:
   ```bash
   docker compose logs caddy --tail 20
   ```

### Verification Steps

1. **Check certificate file format:**
   ```bash
   head -1 /path/to/certs/wildcard.crt  # Should show: -----BEGIN CERTIFICATE-----
   head -1 /path/to/certs/wildcard.key  # Should show: -----BEGIN PRIVATE KEY-----
   ```

2. **Verify mount inside container:**
   ```bash
   docker exec caddy ls -la /etc/caddy/certs/
   ```

3. **Test domain resolution:**
   ```bash
   getent hosts your-domain.com
   ping your-domain.com
   ```

## Security Notes

- Keep private key files secure with minimal permissions (600 or 644)
- Regularly update certificates before expiration
- Consider using a secrets management system for production deployments
- Monitor certificate expiration dates

## Example Environment Variables

Make sure your `.env` file has the correct hostnames:
```env
N8N_HOSTNAME=n8n.yourdomain.com
WEBUI_HOSTNAME=openwebui.yourdomain.com
FLOWISE_HOSTNAME=flowise.yourdomain.com
LETSENCRYPT_EMAIL=your@email.com
```

This tutorial provides a complete guide to replacing Let's Encrypt automatic certificates with your own SSL certificates in a Dockerized Caddy setup.