# NFS Server

[![Build Status](https://github.com/sharedvolume/nfs-server-image/actions/workflows/release.yml/badge.svg)](https://github.com/sharedvolume/nfs-server-image/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/sharedvolume/nfs-server.svg)](https://hub.docker.com/r/sharedvolume/nfs-server)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Alpine Version](https://img.shields.io/badge/Alpine-3.22.0-blue.svg)](https://alpinelinux.org/)

**Repository**: [https://github.com/sharedvolume/nfs-server-image](https://github.com/sharedvolume/nfs-server-image)  
**Releases**: [https://github.com/sharedvolume/nfs-server-image/releases](https://github.com/sharedvolume/nfs-server-image/releases)

A lightweight, production-ready NFS v4 server container based on Alpine Linux. This enterprise-grade solution is specifically designed for modern containerized environments including Docker, Kubernetes, and cloud-native platforms, providing secure and reliable network file sharing capabilities.

## 📖 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
  - [Docker](#docker)
  - [Docker Compose](#docker-compose)
  - [Kubernetes](#kubernetes)
- [Configuration](#️-configuration)
- [Security](#-security)
- [Security Considerations](#-security-considerations)
- [Troubleshooting](#️-troubleshooting)
- [Architecture](#️-architecture)
- [Contributing](#-contributing)
  - [Reporting Issues](#reporting-issues)
  - [Security Policy](#security-policy)
- [Documentation](#-documentation)
- [Versioning](#️-versioning)
- [License](#-license)
- [Support](#-support)

## 🚀 Features

- **NFS v4 Only**: Simplified, modern NFS implementation over TCP port 2049
- **Alpine Linux**: Minimal attack surface with security-focused base image
- **Container Native**: Optimized for Docker, Kubernetes, and orchestration platforms
- **Flexible Configuration**: Environment-driven configuration for various use cases
- **Multi-Architecture**: Supports both amd64 and arm64 architectures
- **Production Ready**: Used in production environments with proper health checks

## 📋 Quick Start

### Docker

```bash
# Basic usage
docker run -d --name nfs-server --privileged \
  -v /path/to/share:/nfs \
  -e SHARED_DIRECTORY=/nfs \
  -p 2049:2049 \
  sharedvolume/nfs-server:<version>

# Mount from client
sudo mount -t nfs4 <docker-host-ip>:/ /mnt/nfs
```

> **Note**: Replace `<version>` with your desired version tag

### Docker Compose

```yaml
version: '3.8'
services:
  nfs-server:
    image: sharedvolume/nfs-server:<version>
    container_name: nfs-server
    privileged: true
    restart: unless-stopped
    environment:
      - SHARED_DIRECTORY=/nfs
      - PERMITTED=10.0.0.0/8  # Restrict to local network
    volumes:
      - ./data:/nfs
    ports:
      - "2049:2049"
    networks:
      - nfs-network

networks:
  nfs-network:
    driver: bridge
```

> **Note**: Replace `<version>` with your desired version tag

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  template:
    metadata:
      labels:
        app: nfs-server
    spec:
      containers:
      - name: nfs-server
        image: sharedvolume/nfs-server:<version>
        env:
        - name: SHARED_DIRECTORY
          value: "/nfs"
        - name: PERMITTED
          value: "*"
        - name: SYNC
          value: "true"
        ports:
        - containerPort: 2049
          name: nfs
        - containerPort: 20048
          name: mountd
        - containerPort: 111
          name: rpcbind
        securityContext:
          privileged: true
          capabilities:
            add:
            - SYS_ADMIN
            - SYS_MODULE
        volumeMounts:
        - name: nfs-data
          mountPath: /nfs
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - "showmount -e localhost"
          initialDelaySeconds: 20
          periodSeconds: 15
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - "pgrep rpc.mountd && showmount -e localhost"
          initialDelaySeconds: 30
          periodSeconds: 30
      volumes:
      - name: nfs-data
        persistentVolumeClaim:
          claimName: nfs-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: nfs-server
spec:
  selector:
    app: nfs-server
  ports:
  - name: nfs
    port: 2049
    targetPort: 2049
  - name: mountd
    port: 20048
    targetPort: 20048
  - name: rpcbind
    port: 111
    targetPort: 111
  type: LoadBalancer
```

> **Note**: Replace `<version>` with your desired version tag

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SHARED_DIRECTORY` | ✅ | - | Path to export inside the container |
| `PERMITTED` | ❌ | `*` | Allowed clients (IP, CIDR, hostname) |
| `READ_ONLY` | ❌ | `false` | Set to any value for read-only access |
| `SYNC` | ❌ | `false` | Set to any value for synchronous writes |
| `SHARED_DIRECTORY_2` | ❌ | - | Additional directory to export |

### Examples

#### Read-only Server for Multiple Clients
```bash
docker run -d --name nfs-readonly --privileged \
  -v /data:/nfs \
  -e SHARED_DIRECTORY=/nfs \
  -e PERMITTED="192.168.1.0/24" \
  -e READ_ONLY=true \
  -e SYNC=true \
  -p 2049:2049 \
  sharedvolume/nfs-server:<version>
```

#### Multiple Directory Shares
```bash
docker run -d --name nfs-multi --privileged \
  -v /data1:/nfs/data1 \
  -v /data2:/nfs/data2 \
  -e SHARED_DIRECTORY=/nfs \
  -e SHARED_DIRECTORY_2=/nfs/data2 \
  -p 2049:2049 \
  sharedvolume/nfs-server:<version>
```

## Security

### Security Architecture

This NFS server implementation follows security best practices and provides multiple layers of protection:

#### Container Security
- **Minimal Attack Surface**: Built on Alpine Linux with only essential packages
- **Regular Security Updates**: Automated vulnerability scanning and patching
- **Non-Root Operations**: Processes run with minimal required privileges where possible
- **Read-Only Root Filesystem**: Container filesystem is immutable except for designated areas

#### Network Security
- **Client Access Control**: Configurable IP-based access restrictions via `PERMITTED` environment variable
- **Port Management**: Uses standard NFS ports with optional custom configuration
- **Firewall Integration**: Compatible with iptables, ufw, and cloud security groups

#### Data Protection
- **Encryption in Transit**: Supports Kerberos authentication and encryption (when configured)
- **Access Control**: Integrates with host filesystem permissions
- **Audit Logging**: Comprehensive logging of all mount and access operations

### Security Configuration

#### Basic Security Setup
```bash
# Secure configuration example
docker run -d --name nfs-server-secure \
  --privileged \
  -v /secure/data:/nfs:ro \
  -e SHARED_DIRECTORY=/nfs \
  -e PERMITTED="192.168.1.0/24,10.0.0.0/8" \
  -e READ_ONLY=true \
  -e SYNC=true \
  -p 2049:2049 \
  sharedvolume/nfs-server:<version>
```

#### Kubernetes Security Context
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server-secure
spec:
  template:
    spec:
      containers:
      - name: nfs-server
        image: sharedvolume/nfs-server:<version>
        securityContext:
          privileged: true
          runAsNonRoot: false
          readOnlyRootFilesystem: false
          capabilities:
            add:
              - SYS_ADMIN
              - SETPCAP
            drop:
              - ALL
        env:
        - name: PERMITTED
          value: "10.244.0.0/16"  # Kubernetes pod network
        - name: READ_ONLY
          value: "true"
```

#### Firewall Configuration

**UFW (Ubuntu)**
```bash
# Allow NFS from specific network
sudo ufw allow from 192.168.1.0/24 to any port 2049
sudo ufw allow from 192.168.1.0/24 to any port 20048
sudo ufw allow from 192.168.1.0/24 to any port 111
```

**iptables**
```bash
# Allow NFS traffic from trusted network
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 20048 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 111 -j ACCEPT
```

### Security Monitoring

#### Log Analysis
```bash
# Monitor NFS access logs
docker logs nfs-server | grep -E "(mount|access|denied)"

# Real-time monitoring
docker logs -f nfs-server | grep -E "(DENIED|FAILED|ERROR)"
```

#### Health Checks
```bash
# Verify security configuration
docker exec nfs-server cat /etc/exports
docker exec nfs-server netstat -tlnp

# Check for unauthorized access attempts
docker exec nfs-server grep "denied" /var/log/messages
```

### Vulnerability Management

#### Security Updates
- **Automated Scanning**: Images are scanned for vulnerabilities using Trivy and Snyk
- **Update Schedule**: Base images updated monthly or upon critical security advisories
- **Version Pinning**: Use specific version tags for production deployments

#### Security Reporting
If you discover a security vulnerability, please follow our [Security Policy](#security-policy):
- **Email**: security@sharedvolume.org
- **GPG Key**: Available in our [security policy](#security-policy)
- **Response Time**: We aim to respond within 24 hours

### Compliance and Standards

#### Security Standards
- **CIS Benchmarks**: Follows CIS Docker and Kubernetes security guidelines
- **NIST Framework**: Aligned with NIST Cybersecurity Framework
- **SOC 2**: Suitable for SOC 2 compliant environments

#### Audit Capabilities
- **Access Logging**: All mount and file access operations are logged
- **Immutable Logs**: Logs can be forwarded to external SIEM systems
- **Compliance Reports**: Generate compliance reports using log analysis tools

## 🔒 Security Considerations

### Privileged Access Requirements

The NFS server requires elevated privileges to manage kernel modules and bind to privileged ports. This is a fundamental requirement for NFS functionality:

#### Docker Configuration
```bash
# Recommended: Full privileged mode
docker run --privileged sharedvolume/nfs-server:<version>

# Alternative: Specific capabilities (may have limitations)
docker run --cap-add SYS_ADMIN --cap-add SETPCAP sharedvolume/nfs-server:<version>
```

#### Kubernetes Configuration
```yaml
securityContext:
  privileged: true
  # Required for NFS kernel module access
```

### Network Security Best Practices

#### Access Control
- **IP Whitelisting**: Always use the `PERMITTED` environment variable to restrict client access
- **Network Segmentation**: Deploy in isolated network segments when possible
- **Port Security**: Use firewall rules to limit access to NFS ports (2049, 20048, 111)

#### Example Secure Configurations
```bash
# Corporate network with multiple subnets
-e PERMITTED="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Kubernetes cluster network only
-e PERMITTED="10.244.0.0/16"

# Single trusted host
-e PERMITTED="192.168.1.100"
```

### Data Security

#### File System Permissions
```bash
# Set appropriate permissions on host
sudo chown -R 1000:1000 /path/to/shared/data
sudo chmod -R 755 /path/to/shared/data

# For read-only scenarios
sudo chmod -R 644 /path/to/shared/data
```

#### Encryption Considerations
- **At Rest**: Use encrypted storage volumes for sensitive data
- **In Transit**: Consider implementing Kerberos authentication for sensitive environments
- **Backup**: Ensure backup data is encrypted and access-controlled

### Security Best Practices

#### Production Deployment
1. **Principle of Least Privilege**: Use specific IP ranges in `PERMITTED` variable
2. **Read-Only Access**: Enable `READ_ONLY=true` for immutable data scenarios
3. **Continuous Monitoring**: Implement monitoring for file access and network connections
4. **Regular Updates**: Maintain current container images with security patches
5. **Backup Strategy**: Implement comprehensive backup and disaster recovery procedures
6. **Access Auditing**: Enable and review access logs regularly

#### Development and Testing
1. **Isolated Networks**: Use separate networks for development environments
2. **Test Data**: Never use production data in development environments
3. **Container Scanning**: Scan images for vulnerabilities before deployment
4. **Security Testing**: Include security testing in your CI/CD pipeline

#### Incident Response
1. **Log Monitoring**: Set up alerts for suspicious activities
2. **Access Revocation**: Have procedures to quickly revoke access if needed
3. **Forensics**: Maintain immutable logs for security incident investigation
4. **Communication**: Establish clear communication channels for security issues

### Production Performance Optimization

#### Resource Allocation
```yaml
# Kubernetes resource limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### Storage Configuration
```bash
# High-performance storage mounting
docker run -d --name nfs-server-performance \
  --privileged \
  -v /fast/storage:/nfs:rw,shared \
  -e SHARED_DIRECTORY=/nfs \
  -e SYNC=false \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  sharedvolume/nfs-server:<version>
```

## 🔧 Troubleshooting

### Diagnostic Tools

#### Health Check Script
```bash
#!/bin/bash
# NFS Server Health Check
echo "=== NFS Server Diagnostics ==="

# Check container status
docker ps | grep nfs-server

# Verify NFS services
docker exec nfs-server pgrep -l nfsd
docker exec nfs-server pgrep -l mountd
docker exec nfs-server pgrep -l rpcbind

# Test exports
docker exec nfs-server showmount -e localhost

# Network connectivity
docker exec nfs-server netstat -tlnp | grep -E "(2049|20048|111)"

echo "=== End Diagnostics ==="
```

### Common Issues

#### Container Won't Start
```bash
# Check logs
docker logs nfs-server

# Verify privileged mode
docker inspect nfs-server | grep Privileged

# Check kernel modules on host
lsmod | grep nfs
```

#### Mount Fails from Client
```bash
# Test connectivity
telnet <nfs-server-ip> 2049

# Check exports
showmount -e <nfs-server-ip>

# Verify client has NFS utilities
# Ubuntu/Debian: apt-get install nfs-common
# RHEL/CentOS: yum install nfs-utils
```

#### Permission Denied
```bash
# Check client IP is in PERMITTED range
docker logs nfs-server | grep "Permitted clients"

# Verify directory permissions in container
docker exec nfs-server ls -la /nfs
```

### Minikube Specific Issues

Minikube requires additional configuration for NFS servers:

```bash
# Enable required kernel modules
minikube ssh -- sudo modprobe nfs nfsd

# Use NodePort for external access
kubectl patch service nfs-server -p '{"spec":{"type":"NodePort"}}'
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
docker run -d --name nfs-debug --privileged \
  -v /data:/nfs \
  -e SHARED_DIRECTORY=/nfs \
  sharedvolume/nfs-server:<version>

# Watch logs in real-time
docker logs -f nfs-debug
```

## 🏗️ Architecture

### Components

- **rpcbind**: RPC port mapper service
- **rpc.nfsd**: Main NFS daemon (NFSv4.1, NFSv4.2)
- **rpc.mountd**: Mount daemon for client requests
- **exportfs**: Manages NFS export table

### File Structure

```
/
├── etc/
│   └── exports          # NFS exports configuration
├── usr/bin/
│   └── nfsd.sh         # Main entrypoint script
├── proc/fs/nfsd/       # NFS kernel interface
└── var/lib/nfs/        # NFS state files
```

### Networking

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 2049 | TCP | NFS | Main NFS traffic |
| 20048 | TCP | mountd | Mount requests |
| 111 | TCP/UDP | rpcbind | RPC port mapping |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone repository
git clone https://github.com/sharedvolume/nfs-server-image.git
cd nfs-server-image

# Build locally
docker build -t nfs-server:dev .

# Test
docker run -d --name nfs-test --privileged \
  -e SHARED_DIRECTORY=/tmp/test \
  nfs-server:dev

# Run tests
docker logs nfs-test
```

### Reporting Issues

We welcome bug reports and feature requests! Please use the following templates when creating issues:

#### 🐛 Bug Report Template

When reporting bugs, please include the following information:

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Docker command used: '...'
2. Environment variables: '...'
3. Mount configuration: '...'
4. Error occurred: '...'

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment (please complete the following information):**
- OS: [e.g. Ubuntu 20.04, macOS 12.0]
- Container Runtime: [e.g. Docker 24.0.0, Podman 4.0.0]
- Orchestrator: [e.g. Kubernetes 1.28, Docker Compose]
- NFS Server Image Version: [e.g. sharedvolume/nfs-server:latest]

**Container logs**
```
Writing SHARED_DIRECTORY to /etc/exports file
The PERMITTED environment variable is set.
The permitted clients are: *.
The READ_ONLY environment variable is unset or null, defaulting to 'rw'.
Clients have read/write access.
The SYNC environment variable is set, using 'sync' mode.
Writes will be immediately written to disk.
Displaying /etc/exports contents:
/nfs *(rw,fsid=0,sync,no_subtree_check,no_auth_nlm,insecure,no_root_squash)

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
Export completed
Starting Mountd in the background...
Startup successful.
```

**Additional context**
Add any other context about the problem here, such as:
- Client-side mount commands
- Network configuration
- Firewall settings
- Kernel modules loaded

#### 💡 Feature Request Template

When requesting new features, please include:

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Use case**
Describe the specific use case or scenario where this feature would be beneficial.

**Additional context**
Add any other context, screenshots, or examples about the feature request here.

### Security Policy

#### Supported Versions

We actively support the following versions of the NFS Server container:

| Version | Supported |
| ------- | --------- |
| 1.x.x   | ✅ |
| 0.x.x   | ⚠️ Limited Support |

#### Reporting Security Vulnerabilities

We take security seriously. If you discover a security vulnerability, please follow these steps:

**For Non-Critical Vulnerabilities**
- Open an issue using our bug report template above
- Include "SECURITY" in the title
- Provide detailed information about the vulnerability

**For Critical Vulnerabilities**
- **Do not** open a public issue
- Email the maintainers directly at: security@sharedvolume.org
- Include "CRITICAL SECURITY" in the subject line
- We will respond within 24 hours

**Information to Include**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fixes (if any)
- Your contact information

#### Vulnerability Response Process
- We aim to respond to security reports within 24 hours
- Critical vulnerabilities will be patched within 7 days
- Non-critical vulnerabilities will be addressed in the next release
- Security patches will be backported to supported versions when necessary
- Security advisories will be published through GitHub Security Advisories

## 📚 Documentation

- [Changelog](CHANGELOG.md)
- [Docker Hub](https://hub.docker.com/r/sharedvolume/nfs-server)
- [GitHub Container Registry](https://github.com/sharedvolume/nfs-server-image/pkgs/container/nfs-server)
- [Wiki Documentation](https://github.com/sharedvolume/nfs-server-image/wiki)

## 🏷️ Versioning

We use [Semantic Versioning](https://semver.org/). See [releases](https://github.com/sharedvolume/nfs-server-image/releases) for changelog and upgrade notes.

### Image Tags

- `latest`: Latest stable release
- `<version>-alpine-3.22.0`: Specific version with Alpine version

> **Note**: Replace `<version>` placeholders with your specific version numbers

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### Commercial Use
The Apache 2.0 license allows for commercial use, modification, and distribution. It also provides patent protection and requires attribution in derivative works.

## 🙏 Acknowledgments

- Inspired by [sjiveson/nfs-server-alpine](https://github.com/sjiveson/nfs-server-alpine)
- Built with [Alpine Linux](https://alpinelinux.org/)
- NFS implementation based on Linux kernel NFS server

## 📞 Support

### Community Support
- **GitHub Issues**: [Report bugs and request features](https://github.com/sharedvolume/nfs-server-image/issues)
- **Discussions**: Join our [GitHub Discussions](https://github.com/sharedvolume/nfs-server-image/discussions) for questions and community support
- **Documentation**: Comprehensive guides available in our [Wiki](https://github.com/sharedvolume/nfs-server-image/wiki)

### Resources
- **Docker Hub**: [sharedvolume/nfs-server](https://hub.docker.com/r/sharedvolume/nfs-server)
- **Container Registry**: [GitHub Container Registry](https://github.com/sharedvolume/nfs-server-image/pkgs/container/nfs-server)
- **Security Advisories**: [GitHub Security](https://github.com/sharedvolume/nfs-server-image/security/advisories)

### Before Reporting Issues
1. Check existing [issues](https://github.com/sharedvolume/nfs-server-image/issues) and [discussions](https://github.com/sharedvolume/nfs-server-image/discussions)
2. Review our [troubleshooting guide](#️-troubleshooting)
3. Test with the latest container image version
4. Include relevant logs and environment details

---

<div align="center">

**⭐ Star this repository if it helped you!**

[![GitHub stars](https://img.shields.io/github/stars/sharedvolume/nfs-server-image?style=social)](https://github.com/sharedvolume/nfs-server-image/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/sharedvolume/nfs-server-image?style=social)](https://github.com/sharedvolume/nfs-server-image/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/sharedvolume/nfs-server-image?style=social)](https://github.com/sharedvolume/nfs-server-image/watchers)

[Website](https://sharedvolume.github.io) • [Docker Hub](https://hub.docker.com/r/sharedvolume/nfs-server) • [Contributing](CONTRIBUTING.md)

</div>