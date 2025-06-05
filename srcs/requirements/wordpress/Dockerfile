# Use Debian Bullseye as base image
FROM debian:bullseye

# Install PHP-FPM and required extensions
# php7.4-fpm: FastCGI Process Manager
# php7.4-mysql: MySQL/MariaDB connectivity
# php7.4-curl: HTTP requests (for plugins, updates)
# php7.4-gd: Image processing
# php7.4-xml: XML processing
# php7.4-mbstring: Multibyte string handling
# php7.4-zip: ZIP archive handling
# php7.4-intl: Internationalization functions
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-xml \
    php7.4-mbstring \
    php7.4-zip \
    php7.4-intl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download and install WordPress CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create WordPress directory
RUN mkdir -p /var/www/html

# Configure PHP-FPM to listen on port 9000
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Copy WordPress configuration script
COPY tools/wordpress_setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress_setup.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Set working directory
WORKDIR /var/www/html

# Start PHP-FPM
CMD ["/usr/local/bin/wordpress_setup.sh"]