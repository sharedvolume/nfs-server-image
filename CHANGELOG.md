# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD pipeline
- Issue templates for bug reports and feature requests
- Contributing guidelines
- Security scanning with Trivy
- Multi-architecture builds (amd64, arm64)

### Changed
- Updated documentation structure
- Improved error handling in startup script
- Enhanced container startup reliability

### Fixed
- Fixed hanging exportfs command with timeout
- Improved NFS service startup sequence

## [0.1.0] - 2025-08-02

### Added
- Initial release
- Alpine Linux 3.22.0 base image
- NFS v4 server support
- Docker and Kubernetes deployment examples
- Environment variable configuration
- Multiple directory sharing support

### Features
- NFSv4 only (TCP port 2049)
- Configurable read/write permissions
- Configurable sync/async mode
- Client access control
- Privileged container support
- Kubernetes security context examples
