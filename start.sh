#!/bin/sh
set -eu

: "${XPRA_PASSWORD:?Configurer XPRA_PASSWORD dans Coolify}"
: "${SERVER_LAN_IP:?Configurer SERVER_LAN_IP dans Coolify}"

mkdir -p "$HOME/chromium-profile" "$HOME/certs" "$XDG_RUNTIME_DIR"
chmod 700 "$HOME/certs" "$XDG_RUNTIME_DIR"

# Certificat temporaire auto-signe : POC uniquement.
# Stocke dans un volume pour ne pas le regenerer a chaque redemarrage.
if [ ! -s "$HOME/certs/server.key" ] || [ ! -s "$HOME/certs/server.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$HOME/certs/server.key" \
        -out "$HOME/certs/server.crt" \
        -subj "/CN=${SERVER_LAN_IP}" \
        -addext "subjectAltName=IP:${SERVER_LAN_IP}"
    chmod 600 "$HOME/certs/server.key"
fi

# Xdummy est requis pour creer dynamiquement une zone par PC.
# La commande xpra set enregistre ce choix pour le profil utilisateur du conteneur.
xpra set xvfb Xdummy

xpra --version
printf '%s\n' 'Lancement du prototype Xpra (mode combine) sur :100, port 14500/TLS.'
exec xpra seamless :100 \
    --sharing=combine \
    --resize-display=yes \
    --daemon=no \
    --html=on \
    --mdns=no \
    --bind-ssl=0.0.0.0:14500,auth=env \
    --ssl-cert="$HOME/certs/server.crt" \
    --ssl-key="$HOME/certs/server.key" \
    --exit-with-children=no \
    --start-child=/usr/local/bin/launch-chromium.sh
