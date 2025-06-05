#!/bin/bash

# This script runs when the container starts
# It sets up the database, users, and permissions

echo "Starting MariaDB initialization..."

# Start MariaDB in the background
# We need it running to execute SQL commands
service mariadb start

# Wait for MariaDB to fully start
# Database startup can take a few seconds
echo "Waiting for MariaDB to start..."
sleep 5

# Check if MariaDB is responding
while ! mysqladmin ping -h"localhost" --silent; do
    echo "Waiting for MariaDB to be ready..."
    sleep 1
done

echo "MariaDB is ready. Creating database and users..."

# Execute SQL commands to set up WordPress database and user
mysql -u root << EOF
-- Create WordPress database if it doesn't exist
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create WordPress user with specific permissions
-- '%' allows connections from any host (other containers)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant all privileges on WordPress database to WordPress user
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Set root password (initially, root has no password)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Apply all privilege changes
FLUSH PRIVILEGES;
EOF

echo "Database setup completed successfully!"

# Stop MariaDB (we'll restart it properly)
service mariadb stop

# Start MariaDB in foreground mode
# This keeps the container running
echo "Starting MariaDB in production mode..."
exec mysqld_safe