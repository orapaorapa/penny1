# PROTOTYPE : Xpra 8 + Chromium (Debian 13, sans Snap)
# NE PAS UTILISER POUR LA PRODUCTION AVANT VALIDATION.
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget gnupg openssl && \
    wget -q -O /usr/share/keyrings/xpra.asc https://xpra.org/xpra.asc && \
    wget -q -O /etc/apt/sources.list.d/xpra-beta.sources \
      https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/trixie/xpra-beta.sources && \
    apt-get update && apt-get install -y --no-install-recommends \
      xpra xpra-x11 xpra-html5 chromium xserver-xorg-core xserver-xorg-video-dummy \      
      xauth dbus-x11 xdotool wmctrl fonts-dejavu-core procps && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd -m -u 10001 -s /bin/bash pilote

COPY start.sh /usr/local/bin/start.sh
COPY launch-chromium.sh /usr/local/bin/launch-chromium.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/launch-chromium.sh && \
    mkdir -p /home/pilote/chromium-profile /home/pilote/certs /home/pilote/.run && \
    chown -R pilote:pilote /home/pilote

USER pilote
ENV HOME=/home/pilote XDG_RUNTIME_DIR=/home/pilote/.run
EXPOSE 14500
CMD ["/usr/local/bin/start.sh"]
