#!/bin/sh
set -eu

# Cette commande est lancee une seule fois par le serveur Xpra.
# Une unique instance Chromium recoit deux commandes --new-window,
# sur UN SEUL affichage X11 (et non deux DISPLAY differents).
sleep 3
chromium \
    --user-data-dir="$HOME/chromium-profile" \
    --no-first-run --no-default-browser-check \
    --disable-dev-shm-usage \
    --new-window 'https://example.org' &

sleep 5
chromium \
    --user-data-dir="$HOME/chromium-profile" \
    --no-first-run --no-default-browser-check \
    --disable-dev-shm-usage \
    --new-window 'https://www.debian.org' || true

# Ne ferme pas le conteneur lors d'une fermeture d'onglet par un client.
wait || true
