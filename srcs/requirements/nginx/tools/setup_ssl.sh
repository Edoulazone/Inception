#!/bin/bash

echo "Setting up SSL certificates..."

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate..."
    
    # Create self-signed certificate valid for 365 days
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=student/CN=${DOMAIN_NAME}"
    
    echo "SSL certificate generated successfully!"
else
    echo "SSL certificate already exists!"
fi

echo "Starting NGINX..."
# Start NGINX in foreground mode
exec nginx -g "daemon off;"