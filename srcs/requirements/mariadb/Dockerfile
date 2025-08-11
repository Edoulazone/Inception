# Utilise l'image officielle Debian Bullseye comme base
FROM debian:bullseye

# Met à jour la liste des paquets et applique les mises à jour disponibles
RUN apt-get update && apt-get upgrade -y

# Installe le serveur MariaDB (fork libre de MySQL)
RUN apt-get install mariadb-server -y

# Supprime les fichiers temporaires liés à apt pour alléger l'image finale
RUN rm -rf /var/lib/apt/lists/*

# Copie le fichier de configuration personnalisé de MariaDB
# dans le dossier de configuration utilisé par Debian/MariaDB
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copie le script d'initialisation dans le conteneur
COPY tools/setup_mariadb.sh /setup.sh

# Rend ce script exécutable
RUN chmod +x /setup.sh

# Définit le script comme point d'entrée : il sera exécuté au démarrage du conteneur
ENTRYPOINT ["bash", "/setup.sh"]