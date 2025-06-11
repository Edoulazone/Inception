# Use Debian Bullseye as base image
FROM debian:bullseye

# Install nginx and openssl
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Remove default nginx configurations to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default
RUN rm -f /etc/nginx/sites-available/default

# Create SSL certificate directory
RUN mkdir -p /etc/nginx/ssl

# Copy nginx configuration to the correct location
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy SSL setup script (adjust path as needed)
COPY setup_ssl.sh /usr/local/bin/setup_ssl.sh
RUN chmod +x /usr/local/bin/setup_ssl.sh

# Create nginx user and set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 443 for HTTPS
EXPOSE 443

# Use setup script as entrypoint
CMD ["/usr/local/bin/setup_ssl.sh"]