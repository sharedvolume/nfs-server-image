# nfs-server

A handy NFS Server image comprising Alpine Linux and NFS v4 only, over TCP on port 2049.

## Overview

This image is based on:

- [Alpine Linux](https://alpinelinux.org/) v3.22.0 — a security-oriented, lightweight Linux distribution.
- NFS v4 only, over TCP on port 2049. Rpcbind is enabled to overcome a bug with slow startup, but shouldn't be required for NFSv4.

This image is inspired by [sjiveson/nfs-server-alpine](https://github.com/sjiveson/nfs-server-alpine) but updated for Alpine 3.22 and simplified for modern container environments.

When run, this container will make whatever directory is specified by the environment variable `SHARED_DIRECTORY` available to NFS v4 clients.

## Usage

```bash
docker run -d --name nfs-server --privileged \
  -v /some/where/fileshare:/nfsshare \
  -e SHARED_DIRECTORY=/nfsshare \
  docker.io/bilgehannal/nfs-server:alpine-3.22.0
```

Add `--net=host` or `-p 2049:2049` to make the shares externally accessible via the host networking stack.

### Environment Variables

- `SHARED_DIRECTORY` (required): Path to export inside the container (must be mounted).
- `PERMITTED` (optional): Allowed clients (e.g. `*`, `10.11.99.*`). Default: `*`.
- `READ_ONLY` (optional): Set to any value for read-only, unset for read-write (default).
- `SYNC` (optional): Set to any value for `sync` mode, unset for `async` (default).
- `SHARED_DIRECTORY_2` (optional): Second directory to export (must be subdirectory of the root share).

### Example: Read-only, sync, restricted clients

```bash
docker run -d --name nfs-server --privileged \
  -v /data:/nfsshare \
  -e SHARED_DIRECTORY=/nfsshare \
  -e PERMITTED="10.11.99.*" \
  -e READ_ONLY=1 \
  -e SYNC=1 \
  docker.io/bilgehannal/nfs-server:alpine-3.22.0
```

### Multiple Shares

To export multiple directories (must be subdirectories of the root share):

```bash
docker run -d --name nfs-server --privileged \
  -v /fileshare:/nfsshare \
  -v /another:/nfsshare/another \
  -e SHARED_DIRECTORY=/nfsshare \
  -e SHARED_DIRECTORY_2=/nfsshare/another \
  docker.io/bilgehannal/nfs-server:alpine-3.22.0
```

You can then mount them from clients as:

```bash
sudo mount -v <nfs-server-ip>:/ /mnt/one
sudo mount -v <nfs-server-ip>:/another /mnt/two
```

### Mounting from a Client

```bash
sudo mount -t nfs4 <nfs-server-ip>:/ /mnt
```

### What Good Looks Like

A successful server start should produce log output like this:

```
Writing SHARED_DIRECTORY to /etc/exports file
The PERMITTED environment variable is unset or null, defaulting to '*'.
This means any client can mount.
The READ_ONLY environment variable is unset or null, defaulting to 'rw'.
Clients have read/write access.
The SYNC environment variable is unset or null, defaulting to 'async' mode.
Writes will not be immediately written to disk.
Displaying /etc/exports contents:
/nfsshare *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)

Starting rpcbind...
Displaying rpcbind status...
   program version netid     address                service    owner
    100000    4    tcp6      ::.0.111               -          superuser
    100000    3    tcp6      ::.0.111               -          superuser
    100000    4    udp6      ::.0.111               -          superuser
    100000    3    udp6      ::.0.111               -          superuser
    100000    4    tcp       0.0.0.0.0.111          -          superuser
    100000    3    tcp       0.0.0.0.0.111          -          superuser
    100000    2    tcp       0.0.0.0.0.111          -          superuser
    100000    4    udp       0.0.0.0.0.111          -          superuser
    100000    3    udp       0.0.0.0.0.111          -          superuser
    100000    2    udp       0.0.0.0.0.111          -          superuser
    100000    4    local     /var/run/rpcbind.sock  -          superuser
    100000    3    local     /var/run/rpcbind.sock  -          superuser
Starting NFS in the background...
rpc.nfsd: knfsd is currently down
rpc.nfsd: Writing version string to kernel: -2 -3 +4.1 +4.2
rpc.nfsd: Created AF_INET TCP socket.
rpc.nfsd: Created AF_INET6 TCP socket.
Exporting File System...
exporting *:/nfsshare
/nfsshare     	<world>
Starting Mountd in the background...These
Startup successful.
```

## Privileged Mode

Privileged mode is required for NFS server operation in Docker. You may try using capabilities (`SYS_ADMIN`, `SETPCAP`) but privileged mode is the most reliable.

### Kubernetes

```yaml
spec:
  containers:
  - name: nfs-server
    image: docker.io/bilgehannal/nfs-server:alpine-3.22.0
    securityContext:
      privileged: true
```

Or with capabilities:

```yaml
spec:
  containers:
  - name: nfs-server
    image: docker.io/bilgehannal/nfs-server:alpine-3.22.0
    securityContext:
      capabilities:
        add: ["SYS_ADMIN", "SETPCAP"]
```

### Docker Compose

```yaml
services:
  nfs-server:
    image: docker.io/bilgehannal/nfs-server:alpine-3.22.0
    privileged: true
    environment:
      - SHARED_DIRECTORY=/nfsshare
    volumes:
      - ./data:/nfsshare
    ports:
      - 2049:2049
```

Or with capabilities:

```yaml
services:
  nfs-server:
    image: docker.io/bilgehannal/nfs-server:alpine-3.22.0
    cap_add:
      - SYS_ADMIN
      - SETPCAP
```

## OverlayFS

OverlayFS does not support NFS export. Use ext4-backed directories for your NFS shares.

## Other Operating Systems

Ensure the `nfs` and `nfsd` kernel modules are loaded (`modprobe nfs nfsd`).

## Dockerfile

The Dockerfile used to create this image is available at the root of the repository.

## Credits

- Inspired by [sjiveson/nfs-server-alpine](https://github.com/sjiveson/nfs-server-alpine)

## License

[GNU GPL v3](LICENSE)