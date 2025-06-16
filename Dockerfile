FROM alpine:3.22.0

LABEL maintainer="Bilgehan NAL <bilgehan.nal@gmail.com>"
LABEL source="https://github.com/sharedVolume/nfs-server"
LABEL branch="main"

# Install required packages and clean up
RUN apk add --no-cache nfs-utils bash iproute2 \
 && rm -rf /var/cache/apk/* /tmp/* /sbin/halt /sbin/poweroff /sbin/reboot \
 && mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery \
 && echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab \
 && echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab

# Copy configuration and entrypoint
COPY exports /etc/
COPY nfsd.sh /usr/bin/nfsd.sh
RUN chmod +x /usr/bin/nfsd.sh

ENTRYPOINT ["/usr/bin/nfsd.sh"]