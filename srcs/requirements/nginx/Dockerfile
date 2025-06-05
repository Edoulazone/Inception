# Use Debian Bullseye as base image
FROM debian:bullseye

# Install nginx and openssl
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create SSL certificate directory
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=Student/CN=localhost"

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Create nginx user and set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 443 for HTTPS
EXPOSE 443

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]