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
        │       └── mariadb_setup.sh
        ├── wordpress/
        │   ├── Dockerfile      # WordPress container setup
        │   └── tools/
        │       └── wordpress_setup.sh
        └── nginx/
            ├── Dockerfile      # NGINX container setup
            └── conf/
            |   └── nginx.conf
            └── tools/
                └── setup_ssl.sh
```
