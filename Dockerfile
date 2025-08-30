FROM alpine:3.22.0

# Metadata
LABEL maintainer="Bilgehan NAL <bilgehan.nal@gmail.com>"
LABEL org.opencontainers.image.title="NFS Server"
LABEL org.opencontainers.image.description="Lightweight NFS v4 server based on Alpine Linux"
LABEL org.opencontainers.image.url="https://github.com/sharedvolume/nfs-server-image"
LABEL org.opencontainers.image.source="https://github.com/sharedvolume/nfs-server-image"
LABEL org.opencontainers.image.vendor="SharedVolume"
LABEL org.opencontainers.image.licenses="MIT"

# Install required packages and clean up
RUN apk add --no-cache bash coreutils iproute2 nfs-utils \
 && rm -rf /var/cache/apk/* /tmp/* /sbin/halt /sbin/poweroff /sbin/reboot \
 && mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery \
 && echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab \
 && echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab

# Copy configuration and entrypoint
COPY exports /etc/
COPY nfsd.sh /usr/bin/nfsd.sh
RUN chmod +x /usr/bin/nfsd.sh

# Expose NFS ports
EXPOSE 2049/tcp 20048/tcp 111/tcp 111/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD showmount -e localhost || exit 1

ENTRYPOINT ["/usr/bin/nfsd.sh"]