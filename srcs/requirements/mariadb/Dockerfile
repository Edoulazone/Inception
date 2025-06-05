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