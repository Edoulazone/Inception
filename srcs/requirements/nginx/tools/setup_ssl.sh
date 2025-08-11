#!/bin/bash

echo "🔒 Setting up SSL certificates..."

# S'assure que la variable DOMAIN_NAME ne soit pas vide (-z)
if [ -z "$DOMAIN_NAME" ]; then
	echo "❌ Missing required environment variables (DOMAIN_NAME)."
	exit 1
fi

# Vérifie et crée le dossier s'il n'est pas encore existant
mkdir -p /etc/nginx/ssl

# Vérifie si le certificat existe déjà (évite de le recréer à chaque démarrage)
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "📜 Generating self-signed SSL certificate..."
    
    # Utilise OpenSSL pour générer un certificat auto-signé valable 1 an (365 jours)
    # -x509 : format de certificat
    # -nodes : pas de mot de passe sur la clé privée
    # -newkey rsa:2048 : crée une nouvelle clé RSA de 2048 bits
    # -keyout : où écrire la clé privée
    # -out : où écrire le certificat public
    # -subj : informations sur l’émetteur (personnalisées ici pour 42 à Bruxelles)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BE/ST=Brussels/L=Brussels/O=42School/OU=student/CN=${DOMAIN_NAME}"

    echo "✅ SSL certificate generated successfully!"
else
    echo "🔁 SSL certificate already exists, skipping..."
fi

echo "🚀 Starting NGINX..."
# Lance le serveur NGINX en avant-plan (nécessaire pour Docker)
exec nginx -g "daemon off;"