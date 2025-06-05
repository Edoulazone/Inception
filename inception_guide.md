# 42 Inception Project - Detailed Step-by-Step Guide

## Understanding the Project Architecture

Before diving into implementation, it's crucial to understand what we're building:

**The Goal**: Create a multi-container WordPress application using Docker, where each service runs in its own isolated container but they communicate through a Docker network.

**The Stack**:
- **NGINX**: Web server that handles HTTPS requests and forwards PHP requests to WordPress
- **WordPress + PHP-FPM**: Content management system with PHP FastCGI Process Manager
- **MariaDB**: Database server that stores WordPress data

**Key Concepts**:
- **Containers**: Isolated environments that package applications with their dependencies
- **Docker Compose**: Tool to define and run multi-container applications
- **Volumes**: Persistent storage that survives container restarts
- **Networks**: Allow containers to communicate with each other

## Project Requirements Deep Dive

### Why These Specific Requirements?

1. **Each service in its own container**: Follows microservices architecture principles
2. **No pre-built images**: Forces you to understand how each service works
3. **Alpine/Debian base**: Lightweight, secure base images
4. **TLS encryption**: Modern web security standard
5. **Volumes for persistence**: Data must survive container restarts
6. **Custom domain**: Simulates real-world deployment

## Step 1: Project Structure Setup

### Creating the Directory Structure

```bash
# Create the main project directory
mkdir -p inception/srcs/requirements/{mariadb,nginx,wordpress}/{conf,tools}
mkdir -p inception/secrets
cd inception
```

**Why this structure?**
- `srcs/`: Contains all source files (Docker Compose requirement)
- `requirements/`: Each service has its own directory
- `conf/`: Configuration files for each service
- `tools/`: Setup scripts and utilities
- `secrets/`: Sensitive data (passwords, keys)

### Understanding the Directory Purpose

```
inception/
├── Makefile                    # Build automation
├── secrets/                    # Sensitive data storage
└── srcs/
    ├── docker-compose.yml      # Container orchestration
    ├── .env                    # Environment variables
    └── requirements/
        ├── mariadb/            # Database container
        ├── nginx/              # Web server container
        └── wordpress/          # Application container
```

## Step 2: Environment Configuration (.env file)

### Why We Need Environment Variables

Environment variables allow us to:
- Keep sensitive data separate from code
- Configure services without rebuilding containers
- Make the setup portable across different environments

### Creating the .env File

Location: `srcs/.env`

```bash
# Domain configuration - This will be your local domain
DOMAIN_NAME=yourusername.42.fr

# MariaDB Root Configuration
# Root user has full database privileges
MYSQL_ROOT_PASSWORD=SecureRootPass123!

# WordPress Database Configuration  
# Dedicated database for WordPress
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=SecureWpPass123!

# WordPress Admin User (Full admin privileges)
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=AdminPass123!
WP_ADMIN_EMAIL=admin@yourusername.42.fr

# WordPress Regular User (Limited privileges)
WP_USER=editor
WP_USER_PASSWORD=EditorPass123!
WP_USER_EMAIL=editor@yourusername.42.fr

# Volume Paths - Where data will be stored on host
MYSQL_DATA_PATH=/home/yourusername/data/mysql
WP_DATA_PATH=/home/yourusername/data/wordpress
```

**Important Notes**:
- Replace `yourusername` with your actual 42 login
- Use strong passwords (mix of letters, numbers, symbols)
- These paths will be created on your host system

### Creating Secrets Files

Secrets files provide an additional layer of security:

```bash
# Create secrets directory
mkdir -p secrets

# Database password
echo "SecureWpPass123!" > secrets/db_password.txt

# Database root password
echo "SecureRootPass123!" > secrets/db_root_password.txt

# WordPress admin password
echo "AdminPass123!" > secrets/wordpress_admin_password.txt

# Set proper permissions (only owner can read)
chmod 600 secrets/*
```

## Step 3: MariaDB Container - Detailed Breakdown

### Understanding MariaDB's Role

MariaDB is the database that will store:
- WordPress posts, pages, comments
- User accounts and permissions
- Site configuration and themes
- Plugin data

### MariaDB Dockerfile Explained

Location: `srcs/requirements/mariadb/Dockerfile`

```dockerfile
# Use Debian Bullseye as base image
FROM debian:bullseye

# Install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy MariaDB configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy database initialization script
COPY tools/mariadb_setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb_setup.sh

# Create mysql data directory
RUN mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /var/lib/mysql

# Expose port 3306
EXPOSE 3306

# Start MariaDB
CMD ["/usr/local/bin/mariadb_setup.sh"]
```

### MariaDB Configuration File

Location: `srcs/requirements/mariadb/conf/50-server.cnf`

```ini
[server]
[mysqld]
# Run as mysql user for security
user                    = mysql

# Process ID file location
pid-file                = /run/mysqld/mysqld.pid

# MariaDB installation directory
basedir                 = /usr

# Database files location
datadir                 = /var/lib/mysql

# Temporary files location
tmpdir                  = /tmp

# Language settings
lc-messages-dir         = /usr/share/mysql
lc-messages             = en_US

# Disable external file locking (better performance in containers)
skip-external-locking

# CRITICAL: Bind to all interfaces, not just localhost
# This allows other containers to connect
bind-address            = 0.0.0.0

# Log file retention
expire_logs_days        = 10

# Character set configuration (supports emojis and international characters)
character-set-server    = utf8mb4
collation-server        = utf8mb4_general_ci

[embedded]
[mariadb]
[mariadb-10.5]
```

**Key Configuration Points**:
- `bind-address = 0.0.0.0`: Allows connections from other containers
- `utf8mb4`: Full UTF-8 support including emojis
- Security settings appropriate for containerized environment

### Database Initialization Script

Location: `srcs/requirements/mariadb/tools/mariadb_setup.sh`

```bash
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
```

**Script Breakdown**:
1. **Start MariaDB temporarily** to run setup commands
2. **Wait for startup** to ensure database is ready
3. **Create database and user** with proper permissions
4. **Set root password** for security
5. **Restart in production mode** (foreground) to keep container alive

## Step 4: WordPress Container - Detailed Breakdown

### Understanding WordPress + PHP-FPM

**Why PHP-FPM instead of Apache?**
- **Performance**: PHP-FPM is faster and uses less memory
- **Separation of concerns**: NGINX handles web serving, PHP-FPM handles PHP processing
- **Scalability**: Can scale web server and PHP processor independently
- **Modern architecture**: Industry standard for high-performance PHP applications

### WordPress Dockerfile Explained

Location: `srcs/requirements/wordpress/Dockerfile`

```dockerfile
# Use Debian Bullseye as base image
FROM debian:bullseye

# Install PHP-FPM and required extensions
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
```

### PHP-FPM Configuration

Location: `srcs/requirements/wordpress/conf/www.conf`

```ini
[www]
# User and group for PHP-FPM processes
user = www-data
group = www-data

# Listen on all interfaces, port 9000
# This allows NGINX container to connect
listen = 0.0.0.0:9000

# Socket ownership (for file permissions)
listen.owner = www-data
listen.group = www-data

# Process management strategy
pm = dynamic

# Maximum number of child processes
pm.max_children = 5

# Number of processes started on startup
pm.start_servers = 2

# Minimum idle processes
pm.min_spare_servers = 1

# Maximum idle processes
pm.max_spare_servers = 3
```

**Configuration Explanation**:
- **Dynamic process management**: Automatically adjusts PHP processes based on load
- **Resource limits**: Prevents excessive memory usage
- **Network configuration**: Allows connections from NGINX container

### WordPress Setup Script

Location: `srcs/requirements/wordpress/tools/wordpress_setup.sh`

```bash
#!/bin/bash

echo "Starting WordPress setup..."

# Wait for MariaDB to be fully ready
# Database container needs time to initialize
echo "Waiting for database to be ready..."
sleep 10

# Additional database connectivity check
while ! mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "Waiting for database connection..."
    sleep 2
done

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
```

**Script Flow**:
1. **Wait for database**: Ensures MariaDB is ready before WordPress setup
2. **Check existing installation**: Prevents reinstalling WordPress
3. **Download WordPress**: Gets latest version from wordpress.org
4. **Configure database connection**: Creates wp-config.php
5. **Install WordPress**: Sets up initial site configuration
6. **Create users**: Admin and regular user (project requirement)
7. **Set permissions**: Ensures proper file access
8. **Start PHP-FPM**: Begins serving PHP requests

## Step 5: NGINX Container - Detailed Breakdown

### Understanding NGINX's Role

NGINX acts as:
- **Reverse proxy**: Forwards requests to appropriate backend services
- **SSL terminator**: Handles HTTPS encryption/decryption
- **Static file server**: Serves images, CSS, JavaScript directly
- **Load balancer**: Can distribute load (though we have only one backend)

### NGINX Dockerfile Explained

Location: `srcs/requirements/nginx/Dockerfile`

```dockerfile
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
```

### NGINX Configuration

Location: `srcs/requirements/nginx/conf/nginx.conf`

```nginx
# Global events block - handles connection processing
events {
    # Maximum number of simultaneous connections per worker process
    worker_connections 1024;
}

# HTTP block - main web server configuration
http {
    # Include MIME types for proper file handling
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Server block - defines our virtual host
    server {
        # Listen on port 443 with SSL and HTTP/2
        listen 443 ssl http2;
        
        # Server name must match our domain
        server_name yourusername.42.fr;

        # SSL Certificate paths
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        # SSL Protocols (TLSv1.2 and TLSv1.3 as required)
        ssl_protocols TLSv1.2 TLSv1.3;

        # Document root - where WordPress files are located
        root /var/www/html;
        
        # Default files to serve
        index index.php index.html index.htm;

        # Main location block - handles all requests
        location / {
            # Try to serve file directly, then directory, then WordPress
            try_files $uri $uri/ /index.php?$args;
        }

        # PHP file processing
        location ~ \.php$ {
            # Split path info for proper PHP handling
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            
            # Forward to WordPress container on port 9000
            fastcgi_pass wordpress:9000;
            
            # Default PHP file
            fastcgi_index index.php;
            
            # Include FastCGI parameters
            include fastcgi_params;
            
            # Set script filename for PHP
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        # Security: deny access to .htaccess files
        location ~ /\.ht {
            deny all;
        }
    }
}
```

**Configuration Breakdown**:
- **SSL configuration**: Enforces HTTPS with modern protocols
- **FastCGI**: Forwards PHP requests to WordPress container
- **Try files**: WordPress-friendly URL rewriting
- **Security**: Blocks access to sensitive files

### SSL Setup Script

Location: `srcs/requirements/nginx/tools/setup_ssl.sh`

```bash
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
```

**SSL Certificate Fields**:
- **C**: Country (BE for Belgium)
- **ST**: State (Brussels)
- **L**: Locality (Brussels)
- **O**: Organization (42School)
- **OU**: Organizational Unit (student)
- **CN**: Common Name (your domain)

## Step 6: Docker Compose - Orchestration Explained

### Understanding Docker Compose

Docker Compose allows us to:
- **Define multiple containers** in a single file
- **Manage container dependencies** (startup order)
- **Create networks** for container communication
- **Manage volumes** for data persistence
- **Set environment variables** consistently across services

### Docker Compose Configuration

Location: `srcs/docker-compose.yml`

```yaml
version: '3.8'

# Define all services (containers)
services:
  
  # MariaDB Database Service
  mariadb:
    # Build from local Dockerfile
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    
    # Container name for easy reference
    container_name: mariadb
    
    # Load environment variables from .env file
    env_file: .env
    
    # Mount persistent volume for database data
    volumes:
      - mariadb_data:/var/lib/mysql
    
    # Connect to custom network
    networks:
      - inception
    
    # Restart policy
    restart: unless-stopped

  # WordPress + PHP-FPM Service
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    
    container_name: wordpress
    env_file: .env
    
    # Mount persistent volume for WordPress files
    volumes:
      - wordpress_data:/var/www/html
    
    networks:
      - inception
    
    # Wait for MariaDB to start first
    depends_on:
      - mariadb
    
    restart: unless-stopped

  # NGINX Web Server Service
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    
    container_name: nginx
    env_file: .env
    
    # Expose port 443 to host system
    ports:
      - "443:443"
    
    # Share WordPress files with NGINX
    volumes:
      - wordpress_data:/var/www/html
    
    networks:
      - inception
    
    # Wait for WordPress to start first
    depends_on:
      - wordpress
    
    restart: unless-stopped

# Define persistent volumes
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      # Bind mount to host directory
      device: ${MYSQL_DATA_PATH}
  
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      # Bind mount to host directory
      device: ${WP_DATA_PATH}

# Define custom network
networks:
  inception:
    driver: bridge
```

**Key Concepts Explained**:

1. **depends_on**: Ensures containers start in correct order
2. **volumes**: Persistent data storage that survives container deletion
3. **networks**: Isolated network for secure container communication
4. **bind mounts**: Link container directories to host filesystem
5. **restart policies**: Automatic container restart on failure

### Why This Architecture Works

1. **Isolation**: Each service runs in its own container
2. **Communication**: Services communicate through Docker network
3. **Persistence**: Data survives container restarts/updates
4. **Security**: Only necessary ports are exposed to host
5. **Scalability**: Can easily add more services or scale existing ones

## Step 7: Makefile - Build Automation

### Understanding Make

Make is a build automation tool that:
- **Defines build targets** (like recipes)
- **Manages dependencies** between targets
- **Provides convenient commands** for common tasks
- **Ensures consistency** across different environments

### Makefile Explained

Location: `Makefile`

```makefile
# Project name
NAME = inception

# Path to Docker Compose file
COMPOSE_FILE = srcs/docker-compose.yml

# Data storage path on host
DATA_PATH = /home/$(USER)/data

# Default target (runs when you type 'make')
all: build up

# Build all Docker images
build:
	@echo "Building Docker images..."
	# Create data directories if they don't exist
	@mkdir -p $(DATA_PATH)/mysql $(DATA_PATH)/wordpress
	# Build all services defined in docker-compose.yml
	@docker-compose -f $(COMPOSE_FILE) build

# Start all containers
up:
	@echo "Starting containers..."
	# Start containers in detached mode (-d)
	@docker-compose -f $(COMPOSE_FILE) up -d

# Stop all containers
down:
	@echo "Stopping containers..."
	# Stop and remove containers
	@docker-compose -f $(COMPOSE_FILE) down

# Clean up containers and images
clean: down
	@echo "Cleaning up..."
	# Remove unused containers, networks, images
	@docker system prune -af
	# Remove unused volumes
	@docker volume prune -f

# Full cleanup including data
fclean: clean
	@echo "Full cleanup..."
	# Remove data directories (WARNING: deletes all data!)
	@sudo rm -rf $(DATA_PATH)
	# Remove everything Docker-related
	@docker system prune -af --volumes

# Rebuild everything from scratch
re: fclean all

# Show container logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Show container status
status:
	@docker-compose -f $(COMPOSE_FILE) ps

# Declare phony targets (not actual files)
.PHONY: all build up down clean fclean re logs status
```

**Makefile Commands**:
- `make` or `make all`: Build and start everything
- `make build`: Build Docker images
- `make up`: Start containers
- `make down`: Stop containers
- `make clean`: Remove containers and images
- `make fclean`: Full cleanup including data
- `make re`: Rebuild everything
- `make logs`: View container logs
- `make status`: Check container status

## Step 8: System Configuration

### Adding Domain to Hosts File

```bash
# Edit hosts file (requires sudo)
sudo nano /etc/hosts

# Add this line:
127.0.0.1 yourusername.42.fr
```

**Why this is needed**:
- Maps your custom domain to localhost
- Allows browser to resolve yourusername.42.fr to your local machine
- Simulates DNS resolution for local development

### Creating Data Directories

```bash
# Create directories for persistent data
mkdir -p /home/$USER/data/mysql
mkdir -p /home/$USER/data/wordpress

# Set proper permissions
chmod 755 /home/$USER/data
chmod 755 /home/$USER/data/mysql
chmod 755 /home/$USER/data/wordpress
```

**Why these directories**:
- **mysql**: Stores database files (tables, indexes, logs)
- **wordpress**: Stores WordPress files (themes, plugins, uploads)
- **Permissions**: Ensure Docker can read/write to these directories

## Step 9: Build and Run Process

### Step-by-Step Execution

1. **Navigate to project directory**:
   ```bash
   cd inception
   ```

2. **Build the Docker images**:
   ```bash
   make build
   ```
   
   **What happens**:
   - Creates data directories
   - Builds MariaDB image from Dockerfile
   - Builds WordPress image from Dockerfile
   - Builds NGINX image from Dockerfile
   - Downloads base images if not present

3. **Start the services**:
   ```bash
   make up
   ```
   
   **What happens**:
   - Creates Docker network 'inception_inception'
   - Starts MariaDB container first
   - Waits for MariaDB, then starts WordPress container
   - Waits for WordPress, then starts NGINX container
   - Mounts volumes for data persistence

4. **Check status**:
   ```bash
   make status
   ```
   
   **Expected output**:
   ```
   Name       Command            State           Ports
   --------------------------------------------------------
   mariadb    /usr/local/bin/... Up              3306/tcp
   nginx      /usr/local/bin/... Up              0.0.0.0:443->443/tcp
   wordpress  /usr/local/bin/... Up              9000/tcp
   ```

5. **View logs** (if needed):
   ```bash
   make logs
   ```

6. **Access your site**:
   - Open browser
   - Go to `https://yourusername.42.fr`
   - Accept SSL certificate warning (self-signed)
   - You should see WordPress installation

## Step 10: Understanding Container Communication

### How Containers Communicate

1. **Docker Network**: All containers are on the same network
2. **Container Names**: Used as hostnames within the network
3. **Port Mapping**: Only NGINX port 443 is exposed to host

### Communication Flow

```
Browser → NGINX (443) → WordPress (9000) → MariaDB (3306)
```

1. **Browser requests** `https://yourusername.42.fr`
2. **NGINX receives** HTTPS request on port 443
3. **NGINX forwards** PHP requests to `wordpress:9000`
4. **WordPress connects** to database at `mariadb:3306`
5. **Response travels back** through the same path

### Volume Sharing

- **WordPress volume**: Shared between WordPress and NGINX containers
- **MariaDB volume**: Exclusive to MariaDB container
- **Host binding**: Both volumes are bound to host directories

## Step 11: Troubleshooting Guide

### Common Issues and Solutions

#### 1. Permission Denied Errors

**Problem**: Docker can't access host directories
**Solution**:
```bash
sudo chown -R $USER:$USER /home/$USER/data
chmod -R 755 /home/$USER/data
```

#### 2. Port Already in Use

**Problem**: Port 443 is occupied
**Check**:
```bash
sudo netstat -tlnp | grep :443
```
**Solution**: Stop the conflicting service or change port mapping

#### 3. Database Connection Errors

**Problem**: WordPress can't connect to MariaDB
**Debug**:
```bash
# Check MariaDB container logs
docker logs mariadb

# Check if MariaDB is running
docker exec -it mariadb mysql -u root -p

# Test connection from WordPress container
docker exec -it wordpress mysql -h mariadb -u wp_user -p
```

#### 4. SSL Certificate Warnings

**Problem**: Browser shows security warning
**Explanation**: Self-signed certificates aren't trusted by browsers
**Solution**: Click "Advanced" → "Proceed to site" (or equivalent)

#### 5. WordPress Installation Issues

**Problem**: WordPress setup fails
**Debug**:
```bash
# Check WordPress container logs
docker logs wordpress

# Check file permissions
docker exec -it wordpress ls -la /var/www/html

# Manual WordPress setup
docker exec -it wordpress wp core install --allow-root --path=/var/www/html
```

### Useful Debugging Commands

```bash
# Enter a container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Check container logs
docker logs mariadb
docker logs wordpress
docker logs nginx

# Inspect Docker network
docker network inspect inception_inception

# Check container resource usage
docker stats

# Restart specific service
docker-compose -f srcs/docker-compose.yml restart nginx

# Rebuild specific service
docker-compose -f srcs/docker-compose.yml build --no-cache nginx
```

## Step 12: Security Considerations

### Password Security

1. **Use strong passwords** in .env file
2. **Keep secrets files secure**:
   ```bash
   chmod 600 secrets/*
   ```
3. **Add sensitive files to .gitignore**:
   ```
   .env
   secrets/
   ```

### Container Security

1. **Run as non-root users** where possible
2. **Use minimal base images** (Alpine/Debian)
3. **Keep images updated** regularly
4. **Limit exposed ports** (only 443 in our case)

### File Permissions

```bash
# WordPress files should be owned by www-data
chown -R www-data:www-data /var/www/html

# Database files should be owned by mysql
chown -R mysql:mysql /var/lib/mysql
```

### Network Security

1. **Isolated network**: Containers communicate only within Docker network
2. **No unnecessary ports**: Only HTTPS (443) exposed to host
3. **Internal communication**: Services use container names as hostnames

## Step 13: Testing Your Installation

### Verification Checklist

#### 1. Container Health Check
```bash
# All containers should be running
make status

# Expected output:
# mariadb    Up
# wordpress  Up  
# nginx      Up      0.0.0.0:443->443/tcp
```

#### 2. Network Connectivity Test
```bash
# Test database connection from WordPress
docker exec -it wordpress mysql -h mariadb -u wp_user -p${MYSQL_PASSWORD} -e "SHOW DATABASES;"

# Expected output should include 'wordpress' database
```

#### 3. Web Server Test
```bash
# Test NGINX configuration
docker exec -it nginx nginx -t

# Expected output: "syntax is ok" and "test is successful"
```

#### 4. SSL Certificate Test
```bash
# Check SSL certificate details
openssl s_client -connect yourusername.42.fr:443 -servername yourusername.42.fr

# Should show certificate information without errors
```

#### 5. WordPress Functionality Test

**Frontend Test**:
1. Open `https://yourusername.42.fr`
2. Should see WordPress homepage
3. SSL certificate warning is normal (self-signed)

**Backend Test**:
1. Go to `https://yourusername.42.fr/wp-admin`
2. Login with admin credentials from .env file
3. Should access WordPress dashboard successfully

**User Test**:
1. In WordPress admin, go to Users
2. Should see both admin and regular user accounts
3. Test login with regular user credentials

## Step 14: Understanding the Data Flow

### Request Processing Flow

#### Static File Request (CSS, JS, Images)
```
Browser → NGINX → Static File → Browser
```
1. Browser requests static file (e.g., style.css)
2. NGINX checks `/var/www/html` directory
3. If file exists, NGINX serves it directly
4. Response sent back to browser

#### Dynamic PHP Request (WordPress Pages)
```
Browser → NGINX → PHP-FPM → WordPress → MariaDB → Response Chain
```
1. Browser requests WordPress page (e.g., /about)
2. NGINX receives request, recognizes PHP needed
3. NGINX forwards to WordPress container (PHP-FPM on port 9000)
4. WordPress processes PHP code
5. WordPress queries MariaDB for content
6. MariaDB returns data to WordPress
7. WordPress generates HTML response
8. Response travels back through NGINX to browser

#### Database Operations
```
WordPress ←→ MariaDB (port 3306)
```
- WordPress connects using: `mariadb:3306`
- Authentication: wp_user / password from .env
- Database: wordpress
- Operations: SELECT, INSERT, UPDATE, DELETE

### Volume Data Persistence

#### WordPress Volume (`/var/www/html`)
**Shared between**:
- WordPress container (read/write)
- NGINX container (read-only)

**Contains**:
```
/var/www/html/
├── wp-config.php          # Database configuration
├── wp-content/            # Themes, plugins, uploads
│   ├── themes/
│   ├── plugins/
│   └── uploads/
├── wp-admin/              # WordPress admin interface
├── wp-includes/           # WordPress core files
└── index.php              # Main entry point
```

#### MariaDB Volume (`/var/lib/mysql`)
**Exclusive to MariaDB container**

**Contains**:
```
/var/lib/mysql/
├── mysql/                 # System database
├── wordpress/             # WordPress database
│   ├── wp_posts.frm       # Posts table structure
│   ├── wp_posts.MYD       # Posts data
│   ├── wp_users.frm       # Users table structure
│   └── wp_users.MYD       # Users data
└── ibdata1                # InnoDB system tablespace
```

## Step 15: Advanced Configuration Options

### Performance Tuning

#### PHP-FPM Optimization
Location: `srcs/requirements/wordpress/conf/www.conf`

```ini
# For higher traffic (adjust based on server resources)
pm.max_children = 20
pm.start_servers = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 8

# Process management tuning
pm.max_requests = 500
pm.process_idle_timeout = 10s
```

#### MariaDB Optimization
Location: `srcs/requirements/mariadb/conf/50-server.cnf`

```ini
# Memory optimization
innodb_buffer_pool_size = 128M
query_cache_size = 16M
query_cache_limit = 1M

# Connection optimization
max_connections = 100
thread_cache_size = 8
```

#### NGINX Optimization
Location: `srcs/requirements/nginx/conf/nginx.conf`

```nginx
http {
    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/css application/javascript application/json;
    
    # Browser caching for static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Security Hardening

#### NGINX Security Headers
```nginx
server {
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Hide NGINX version
    server_tokens off;
}
```

#### MariaDB Security
```sql
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Flush privileges
FLUSH PRIVILEGES;
```

## Step 16: Monitoring and Maintenance

### Health Checks

#### Container Health Monitoring
```bash
# Check container resource usage
docker stats --no-stream

# Check container uptime
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Monitor logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f --tail=50
```

#### Database Health Check
```bash
# Check database size
docker exec -it mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "
SELECT 
    table_schema as 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) as 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema='wordpress'
GROUP BY table_schema;"
```

#### WordPress Health Check
```bash
# Check WordPress version and updates
docker exec -it wordpress wp core version --allow-root
docker exec -it wordpress wp core check-update --allow-root

# Check plugin status
docker exec -it wordpress wp plugin list --allow-root

# Check theme status
docker exec -it wordpress wp theme list --allow-root
```

### Backup Strategies

#### Database Backup
```bash
# Create database backup
docker exec mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database backup
docker exec -i mariadb mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress < backup_file.sql
```

#### WordPress Files Backup
```bash
# Create WordPress files backup
tar -czf wordpress_backup_$(date +%Y%m%d_%H%M%S).tar.gz /home/$USER/data/wordpress

# Restore WordPress files
tar -xzf wordpress_backup_file.tar.gz -C /
```

#### Automated Backup Script
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/home/$USER/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker exec mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress > $BACKUP_DIR/db_$DATE.sql

# WordPress files backup
tar -czf $BACKUP_DIR/wp_$DATE.tar.gz /home/$USER/data/wordpress

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

### Update Procedures

#### Updating WordPress
```bash
# Update WordPress core
docker exec -it wordpress wp core update --allow-root

# Update plugins
docker exec -it wordpress wp plugin update --all --allow-root

# Update themes
docker exec -it wordpress wp theme update --all --allow-root
```

#### Updating Docker Images
```bash
# Rebuild with latest base images
make clean
docker-compose -f srcs/docker-compose.yml build --no-cache
make up
```

## Step 17: Bonus Features (Optional)

### Adding Redis Cache

#### Redis Dockerfile
Location: `srcs/requirements/bonus/redis/Dockerfile`

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y redis-server && rm -rf /var/lib/apt/lists/*

COPY conf/redis.conf /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]
```

#### Redis Configuration
Location: `srcs/requirements/bonus/redis/conf/redis.conf`

```conf
bind 0.0.0.0
port 6379
maxmemory 64mb
maxmemory-policy allkeys-lru
```

#### Adding Redis to Docker Compose
```yaml
services:
  redis:
    build:
      context: ./requirements/bonus/redis
      dockerfile: Dockerfile
    container_name: redis
    networks:
      - inception
    restart: unless-stopped
```

### Adding FTP Server

#### vsftpd Dockerfile
Location: `srcs/requirements/bonus/ftp/Dockerfile`

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y vsftpd && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup_ftp.sh /usr/local/bin/setup_ftp.sh
RUN chmod +x /usr/local/bin/setup_ftp.sh

EXPOSE 21

ENTRYPOINT ["/usr/local/bin/setup_ftp.sh"]
```

### Adding Adminer (Database Management)

#### Adminer Dockerfile
Location: `srcs/requirements/bonus/adminer/Dockerfile`

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -O /var/www/html/index.php

EXPOSE 9001

CMD ["php", "-S", "0.0.0.0:9001", "-t", "/var/www/html"]
```

## Step 18: Project Submission Guidelines

### Final Checklist

#### Code Quality
- [ ] All Dockerfiles use only Alpine or Debian base images
- [ ] No pre-built images used (except base OS)
- [ ] Each service runs in separate container
- [ ] All containers restart automatically
- [ ] No passwords in Dockerfiles

#### Functionality
- [ ] NGINX serves HTTPS only (TLSv1.2 or TLSv1.3)
- [ ] WordPress works with PHP-FPM (no Apache)
- [ ] MariaDB database functional
- [ ] Two WordPress users created
- [ ] Volumes persist data after restart
- [ ] Domain name configured correctly

#### File Structure
- [ ] All source files in `srcs/` directory
- [ ] Makefile present and functional
- [ ] Environment variables in `.env` file
- [ ] Secrets properly managed
- [ ] Directory structure follows requirements

#### Testing
- [ ] `make` builds and starts everything
- [ ] Website accessible via HTTPS
- [ ] WordPress admin login works
- [ ] Database connection functional
- [ ] Volumes persist after `make down` and `make up`

### Common Evaluation Points

#### Security
- Strong passwords used
- No hardcoded secrets in code
- Proper file permissions
- SSL/TLS properly configured

#### Architecture
- Clean separation of services
- Proper container communication
- Appropriate use of volumes and networks
- Following Docker best practices

#### Documentation
- Clear README (if provided)
- Code comments where necessary
- Environment variables documented

## Conclusion

This comprehensive guide covers every aspect of the 42 Inception project. The key to success is understanding each component's role and how they work together:

1. **MariaDB** provides persistent data storage
2. **WordPress + PHP-FPM** handles dynamic content generation
3. **NGINX** serves as the web server and SSL terminator
4. **Docker Compose** orchestrates the entire stack
5. **Volumes** ensure data persistence
6. **Networks** enable secure inter-container communication

Remember to:
- Test each component individually before integrating
- Check logs when troubleshooting issues
- Keep security in mind throughout development
- Follow Docker best practices
- Document any custom configurations

The project teaches valuable skills in containerization, system administration, and modern web architecture that are essential in today's development landscape.
