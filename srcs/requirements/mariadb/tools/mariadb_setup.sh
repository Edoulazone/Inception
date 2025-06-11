#!/bin/bash

echo "Starting MariaDB initialization..."

# Install MariaDB if not already done (in case of minimal base image)
service mariadb start

echo "Waiting for MariaDB to start..."
# Wait for MariaDB to be fully ready
while ! mysqladmin ping -h"localhost" --silent; do
    echo "Waiting for MariaDB to be ready..."
    sleep 1
done

echo "MariaDB is ready. Creating database and users..."

# Set root password first (this might be why auth is failing)
mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Now use the root password for subsequent commands
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Database setup completed successfully!"

# Properly shutdown MariaDB using mysqladmin
echo "Shutting down MariaDB..."
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

# Wait a moment for clean shutdown
sleep 2

echo "Starting MariaDB in production mode..."
# Start MariaDB in foreground mode
exec mysqld_safe