![inception](https://github.com/Edoulazone/gifs/blob/master/inception.gif)
# Inception - Docker Infrastructure Project

## 📋 Project Overview

Inception is a containerized web application infrastructure built with Docker. The project demonstrates modern DevOps practices by creating a complete web stack with multiple services, each running in isolated containers and orchestrated using Docker Compose.

## 🏗️ Architecture

This project creates a complete web application stack using Docker containers:

- **NGINX**: Web server with TLSv1.2/TLSv1.3 SSL encryption
- **WordPress**: Content management system with PHP-FPM
- **MariaDB**: Database server for WordPress

All services are containerized and orchestrated using Docker Compose, with data persistence through Docker volumes.

## 📁 Project Structure

```
inception/
├── Makefile                    # Build automation
├── README.md                   # This file
└── srcs/
    ├── docker-compose.yml      # Container orchestration
    ├── .env                    # Environment variables
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile      # MariaDB container setup
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── setup_mariadb.sh
        ├── wordpress/
        │   ├── Dockerfile      # WordPress container setup
        │   └── tools/
        │       └── setup_wordpress.sh
        └── nginx/
            ├── Dockerfile      # NGINX container setup
            └── conf/
                └── nginx.conf
```

## 🚀 Getting Started

### Prerequisites

- Docker Engine (v20.10+)
- Docker Compose (v2.0+)
- Make
- Linux/macOS environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Configure environment variables**
   ```bash
   # Edit the .env file in srcs/ directory
   nano srcs/.env
   ```
   
   Update the following variables:
   - `DOMAIN_NAME`: Your domain (e.g., your-login.42.fr)
   - Database credentials
   - WordPress admin credentials

3. **Build and start the infrastructure**
   ```bash
   make
   ```

## 🛠️ Available Commands

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build images and start containers |
| `make build` | Build all Docker images |
| `make up` | Start all containers |
| `make down` | Stop all containers |
| `make logs` | View container logs |
| `make status` | Show container status |
| `make clean` | Clean up containers and images |
| `make fclean` | Full cleanup including data |
| `make re` | Rebuild everything from scratch |

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Domain configuration
DOMAIN_NAME=your-login.42.fr

# MariaDB configuration
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_wp_password

# WordPress configuration
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
WP_USER_PASSWORD=your_user_password
```

### SSL Configuration

The project automatically generates self-signed SSL certificates for HTTPS. In production, replace these with proper certificates.

### Data Persistence

Data is stored in Docker volumes and host directories:
- MariaDB data: `/home/$USER/data/mysql`
- WordPress files: `/home/$USER/data/wordpress`

## 🌐 Services

### NGINX (Port 443)
- **Image**: Custom Debian-based
- **Features**: 
  - SSL/TLS encryption (TLSv1.2/1.3)
  - Reverse proxy to WordPress
  - Static file serving
- **Config**: `srcs/requirements/nginx/conf/nginx.conf`

### WordPress (Port 9000)
- **Image**: Custom Debian-based with PHP-FPM
- **Features**:
  - WordPress CLI integration
  - Automatic installation and configuration
  - Multi-user setup
- **Setup**: `srcs/requirements/wordpress/tools/setup_wordpress.sh`

### MariaDB (Port 3306)
- **Image**: Custom Debian-based
- **Features**:
  - Secure installation
  - Database and user creation
  - Persistent data storage
- **Setup**: `srcs/requirements/mariadb/tools/setup_mariadb.sh`

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied (Docker)**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Port Already in Use**
   ```bash
   # Check what's using the port
   sudo lsof -i :443
   sudo lsof -i :3306
   ```

3. **Database Connection Issues**
   - Verify environment variables in `.env`
   - Check MariaDB container logs: `make logs`
   - Ensure containers can communicate via Docker network

4. **SSL Certificate Issues**
   - Certificates are auto-generated on first build
   - For custom certificates, replace files in nginx container

### Debugging

```bash
# View all container logs
make logs

# Check container status
make status

# Access container shell
docker exec -it inception-nginx-1 /bin/bash
docker exec -it inception-wordpress-1 /bin/bash
docker exec -it inception-mariadb-1 /bin/bash

# View Docker networks
docker network ls
docker network inspect inception_inception-network
```

## 📚 Learning Objectives

This project demonstrates:
- **Containerization**: Docker fundamentals and best practices
- **Orchestration**: Multi-container applications with Docker Compose
- **Networking**: Container networking and service discovery
- **Security**: SSL/TLS configuration and container security
- **System Administration**: Service configuration and automation
- **Infrastructure as Code**: Reproducible deployments

## 🔒 Security Considerations

- All passwords should be strong and unique
- SSL certificates should be properly configured
- Database access is restricted to WordPress container
- Containers run with minimal privileges
- Regular security updates should be applied

## 🏛️ Architecture Features

- ✅ Each service runs in a dedicated container
- ✅ Custom Dockerfiles built from base OS images
- ✅ Docker Compose for orchestration
- ✅ Persistent data storage with Docker volumes
- ✅ Secure inter-container communication
- ✅ Environment-based configuration
- ✅ Automated deployment with Makefile
- ✅ SSL/TLS encryption for web traffic
- ✅ Multi-user WordPress setup

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available for educational and development purposes.

## 🆘 Support

For issues related to:
- **Docker**: Check Docker documentation
- **Configuration**: Review logs and configuration files
- **Networking**: Verify container connectivity and port mappings

---

**Note**: This project demonstrates modern containerization practices and is suitable for development and learning environments. For production use, additional security hardening and monitoring should be implemented.
