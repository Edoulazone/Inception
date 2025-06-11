#!/bin/bash

echo "Starting WordPress setup..."

# Wait for MariaDB to be fully ready
# Database container needs time to initialize
echo "Waiting for database to be ready..."
sleep 10

# Alternative database connectivity check using wp-cli
echo "Checking database connection..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if wp db check --allow-root --path=/var/www/html 2>/dev/null; then
        echo "Database connection successful!"
        break
    fi
    
    echo "Waiting for database connection... (attempt $((attempt + 1))/$max_attempts)"
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Failed to connect to database after $max_attempts attempts"
    exit 1
fi

echo "Database is ready!"

# Check if WordPress is already installed
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress not found. Installing..."
    
    # Download latest WordPress
    wp core download --allow-root --path=/var/www/html
    
    echo "Creating WordPress configuration..."
    
    # Create wp-config.php with database settings
    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root \
        --path=/var/www/html
    
    echo "Installing WordPress..."
    
    # Install WordPress with admin user
    wp core install \
        --url=${DOMAIN_NAME} \
        --title="Inception WordPress Site" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root \
        --path=/var/www/html
    
    echo "Creating additional WordPress user..."
    
    # Create second user (project requirement)
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --user_pass=${WP_USER_PASSWORD} \
        --role=author \
        --allow-root \
        --path=/var/www/html
    
    echo "WordPress installation completed!"
else
    echo "WordPress already installed!"
fi

# Set proper file permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
# Start PHP-FPM in foreground mode (keeps container running)
exec php-fpm7.4 -F