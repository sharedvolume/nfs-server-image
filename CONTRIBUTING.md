# Contributing to NFS Server

We welcome and appreciate contributions to this project! This guide will help you understand how to contribute effectively to the NFS Server container project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Process](#development-process)
- [Getting Started](#getting-started)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Community Guidelines](#community-guidelines)
- [License](#license)

## Code of Conduct

This project and everyone participating in it is governed by our commitment to creating a welcoming and inclusive environment. By participating, you are expected to uphold high standards of professionalism and respect.

## Development Process

We use GitHub to host code, track issues and feature requests, and accept pull requests. All development happens openly on GitHub.

### Ways to Contribute

- 🐛 **Report bugs** - Help us identify and fix issues
- 💡 **Suggest features** - Share ideas for improvements
- 📝 **Improve documentation** - Help make our docs better
- 🔧 **Submit code changes** - Fix bugs or implement features
- 🧪 **Add tests** - Improve test coverage
- 🚀 **Become a maintainer** - Help maintain the project

## Getting Started

## Getting Started

### Prerequisites

- **Docker** or **Podman** - For building and testing containers
- **Git** - For version control
- **NFS utilities** - For testing NFS functionality
  - Ubuntu/Debian: `sudo apt-get install nfs-common`
  - RHEL/CentOS: `sudo yum install nfs-utils`
  - macOS: `brew install nfs-utils` (or use built-in NFS client)

### Development Environment Setup

1. **Fork and Clone**
   ```bash
   # Fork the repository on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/nfs-server-image.git
   cd nfs-server-image
   
   # Add upstream remote
   git remote add upstream https://github.com/sharedvolume/nfs-server-image.git
   ```

2. **Build the Development Image**
   ```bash
   docker build -t nfs-server:dev .
   ```

3. **Run Basic Tests**
   ```bash
   # Create test directory
   mkdir -p /tmp/nfs-test
   
   # Start container
   docker run -d --name nfs-dev --privileged \
     -v /tmp/nfs-test:/nfs \
     -e SHARED_DIRECTORY=/nfs \
     -p 2049:2049 \
     nfs-server:dev
   
   # Check container status
   docker logs nfs-dev
   docker exec nfs-dev showmount -e localhost
   
   # Cleanup
   docker stop nfs-dev && docker rm nfs-dev
   ```

## Making Changes

### Pull Request Process

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make Your Changes**
   - Write clear, documented code
   - Follow existing code style and conventions
   - Add tests for new functionality
   - Update documentation if needed

3. **Test Your Changes**
   - Ensure all existing tests pass
   - Add new tests for your changes
   - Test manually with different configurations

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   # or
   git commit -m "fix: resolve issue description"
   ```

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a pull request on GitHub.

### Commit Message Guidelines

We follow conventional commit format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

Examples:
- `feat: add support for multiple export directories`
- `fix: resolve permission issues in read-only mode`
- `docs: update installation instructions`

## Testing

## Testing

### Automated Testing

Run the test suite to ensure your changes don't break existing functionality:

```bash
# Basic functionality test
docker build -t nfs-server:test .
docker run -d --name nfs-test --privileged \
  -e SHARED_DIRECTORY=/tmp/test \
  nfs-server:test

# Wait for services to start
sleep 10

# Check logs for errors
docker logs nfs-test

# Verify NFS services are running
docker exec nfs-test pgrep -l rpc.mountd
docker exec nfs-test showmount -e localhost

# Cleanup
docker stop nfs-test && docker rm nfs-test
```

### Manual Testing

Test your changes with different configurations:

```bash
# Test read-only mode
docker run -d --name nfs-readonly --privileged \
  -v /tmp/test-data:/nfs \
  -e SHARED_DIRECTORY=/nfs \
  -e READ_ONLY=true \
  -p 2049:2049 \
  nfs-server:dev

# Test with client restrictions
docker run -d --name nfs-restricted --privileged \
  -v /tmp/test-data:/nfs \
  -e SHARED_DIRECTORY=/nfs \
  -e PERMITTED="192.168.1.0/24" \
  -p 2049:2049 \
  nfs-server:dev
```

### Testing Checklist

- [ ] Container starts successfully
- [ ] NFS services (rpcbind, mountd, nfsd) are running
- [ ] Exports are properly configured
- [ ] Client connections work as expected
- [ ] Environment variables are handled correctly
- [ ] Error conditions are handled gracefully

## Submitting Changes

### Pull Request Guidelines

- **Clear Title**: Use a descriptive title that explains what your PR does
- **Detailed Description**: Explain what changes you made and why
- **Link Issues**: Reference any related issues using `#issue-number`
- **Test Results**: Include test results or screenshots if applicable
- **Breaking Changes**: Clearly document any breaking changes

### Review Process

1. **Automated Checks**: GitHub Actions will run automated tests
2. **Code Review**: Maintainers will review your code
3. **Feedback**: Address any feedback or requested changes
4. **Approval**: Once approved, your PR will be merged

## Community Guidelines

### Reporting Issues

Use GitHub's [issue tracker](https://github.com/sharedvolume/nfs-server-image/issues) to report bugs or request features.

**Great Bug Reports** include:

- **Clear Summary**: Brief description of the issue
- **Environment Details**: OS, Docker version, container image version
- **Reproduction Steps**: Step-by-step instructions to reproduce
- **Expected vs Actual**: What you expected vs what happened
- **Logs**: Relevant container logs or error messages
- **Additional Context**: Any other helpful information

### Feature Requests

When suggesting new features:

- **Use Case**: Explain why this feature would be useful
- **Alternatives**: Describe any workarounds you've tried
- **Implementation Ideas**: Suggest how it might be implemented
- **Breaking Changes**: Note if it would break existing functionality

### Security Issues

For security vulnerabilities:
- **Do not** open a public issue
- Email: security@sharedvolume.org
- Include "SECURITY" in the subject line
- Provide detailed information about the vulnerability

## Development Guidelines

### Code Style

- **Shell Scripts**: Follow POSIX standards where possible
- **Docker**: Follow Docker best practices
- **Documentation**: Use clear, concise language
- **Comments**: Add comments for complex logic

### Docker Image Guidelines

- **Base Image**: Use Alpine Linux for minimal size
- **Security**: Follow security best practices
- **Multi-arch**: Test on multiple architectures when possible
- **Size**: Keep image size minimal
- **Layers**: Optimize Docker layers for better caching

### Release Process

1. **Version Update**: Update version numbers in relevant files
2. **Changelog**: Update CHANGELOG.md with changes
3. **Pull Request**: Create PR with version changes
4. **Review**: Get PR reviewed and approved
5. **Merge**: Merge to main branch
6. **Tag**: Create release tag
7. **Release**: GitHub Actions automatically builds and publishes

## Getting Help

- **GitHub Discussions**: Ask questions and discuss ideas
- **Issues**: Report bugs or request features
- **Email**: Contact maintainers for sensitive topics

## Recognition

Contributors are recognized in our:
- CHANGELOG.md for each release
- README.md acknowledgments
- GitHub contributors page

Thank you for contributing to making NFS Server better! 🚀

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.
