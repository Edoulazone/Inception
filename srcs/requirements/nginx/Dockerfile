# Utilise l'image officielle Debian Bullseye comme base
FROM debian:bullseye

# Met à jour la liste des paquets et installe NGINX
RUN apt-get update && apt-get install nginx -y

# Installe OpenSSL (nécessaire pour créer et gérer les certificats SSL)
RUN apt-get install openssl -y

# Supprime les fichiers temporaires de la liste des paquets pour alléger l'image
RUN rm -rf /var/lib/apt/lists/*

# Supprime la configuration NGINX par défaut (sites "default")
RUN rm -f /etc/nginx/sites-enabled/default
RUN rm -f /etc/nginx/sites-available/default

# Copie le fichier de configuration personnalisé de NGINX dans le conteneur
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copie le script de configuration SSL dans le conteneur et le place à la racine
COPY tools/setup_ssl.sh /setup.sh

# Rend le script exécutable
RUN chmod +x /setup.sh

# Donne au propriétaire (root) tous les droits (lecture/écriture/exécution)
# et aux autres utilisateurs lecture/exécution uniquement sur /var/www/html
RUN chmod -R 755 /var/www/html

# Change le propriétaire et le groupe de /var/www/html pour 'www-data'
# (utilisateur par défaut de NGINX pour exécuter les services web)
RUN chown -R www-data:www-data /var/www/html

# Informe Docker que le conteneur écoutera sur le port 443 (HTTPS)
EXPOSE 443

# Définit le script SSL comme point d’entrée : il sera exécuté automatiquement
# lorsque le conteneur démarrera
ENTRYPOINT ["bash", "/setup.sh"]