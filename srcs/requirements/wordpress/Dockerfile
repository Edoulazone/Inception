# Utilise l'image officielle Debian Bullseye comme base
FROM debian:bullseye

# Met à jour les paquets et installe :
# - wget : pour télécharger des fichiers
# - php7.4-fpm et php7.4-mysql : PHP-FPM avec extension MySQL pour WordPress
# - mariadb-client : client MySQL/MariaDB pour communiquer avec la base de données
# Ensuite supprime le cache APT pour réduire la taille de l'image
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y wget \
        php7.4-fpm php7.4-mysql \
        mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Copie la configuration personnalisée de PHP-FPM (pool www)
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Télécharge WP-CLI (outil en ligne de commande pour WordPress) et le place dans /usr/local/bin/wp
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

# Crée le dossier racine qui contiendra les fichiers WordPress
RUN mkdir -p /var/www/html

# Copie le script d’installation/configuration de WordPress dans le conteneur
COPY tools/setup_wordpress.sh /setup.sh

# Rend le script exécutable
RUN chmod +x /setup.sh

# Expose le port 9000 (port par défaut utilisé par PHP-FPM)
EXPOSE 9000

# Définit le répertoire de travail par défaut à /var/www/html
# Ainsi, les commandes WP-CLI et le script s’exécuteront directement dans ce dossier
WORKDIR /var/www/html

# Définit le script d’installation comme point d’entrée du conteneur
ENTRYPOINT ["bash", "/setup.sh"]