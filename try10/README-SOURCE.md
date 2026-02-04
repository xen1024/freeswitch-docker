# FreeSWITCH Docker - Build from Source

Complete Docker setup for building FreeSWITCH from source on Debian Bookworm.

## Why Build from Source?

- **Latest features**: Access to newest code and bug fixes
- **Custom modules**: Choose exactly which modules to include
- **Optimization**: Build with specific compiler flags for your hardware
- **Patches**: Apply custom patches before building
- **No repository dependency**: No need for SignalWire repository credentials

## Quick Start

### Method 1: Automated Build Script (Recommended)

```bash
# Build with defaults (FreeSWITCH v1.10.12)
./build-from-source.sh

# Build specific version
./build-from-source.sh -v v1.10.11

# Build with 8 parallel jobs (faster on multi-core systems)
./build-from-source.sh -j 8

# Build without sound files (smaller image)
./build-from-source.sh --no-sounds

# Build latest development version
./build-from-source.sh --dev
```

### Method 2: Docker Compose

```bash
# Edit build args in docker-compose.source.yml if needed
docker-compose -f docker-compose.source.yml build

# Start the container
docker-compose -f docker-compose.source.yml up -d
```

### Method 3: Manual Docker Build

```bash
# Build the image
docker build -f Dockerfile.source \
  --build-arg FREESWITCH_VERSION=v1.10.12 \
  --build-arg MAKE_JOBS=4 \
  -t freeswitch-source:latest .

# Run the container
docker run -d \
  --name freeswitch \
  --net host \
  -v $(pwd)/freeswitch/conf:/usr/local/freeswitch/conf \
  -v $(pwd)/freeswitch/db:/usr/local/freeswitch/db \
  -v $(pwd)/freeswitch/recordings:/usr/local/freeswitch/recordings \
  -v $(pwd)/freeswitch/logs:/var/log/freeswitch \
  freeswitch-source:latest
```

## Build Options

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| FREESWITCH_VERSION | v1.10.12 | Git tag/branch to build |
| MAKE_JOBS | 4 | Parallel make jobs |

### Available Versions

- `v1.10.12` - Latest stable (recommended)
- `v1.10.11` - Previous stable
- `v1.10.10` - Older stable
- `master` - Development branch (bleeding edge)

## Build Time and Size

| System | Build Time | Final Size |
|--------|------------|------------|
| 2 cores, 4GB RAM | ~30 minutes | ~800 MB |
| 4 cores, 8GB RAM | ~15 minutes | ~800 MB |
| 8 cores, 16GB RAM | ~8 minutes | ~800 MB |

**Note**: First build will be slower (downloading packages). Subsequent builds use Docker cache.

## Customizing Modules

See [MODULES.md](MODULES.md) for detailed module customization guide.

### Quick Module Customization

Edit `Dockerfile.source` and modify this section:

```dockerfile
# Enable additional modules
RUN sed -i 's|#applications/mod_callcenter|applications/mod_callcenter|' modules.conf && \
    sed -i 's|#codecs/mod_opus|codecs/mod_opus|' modules.conf
```

Or create a custom `modules.conf` file:

```dockerfile
COPY modules.conf.custom /usr/src/freeswitch/modules.conf
```

## Directory Structure

After first run:

```
.
├── Dockerfile.source          # Multi-stage source build
├── docker-compose.source.yml  # Docker Compose config
├── build-from-source.sh       # Automated build script
├── MODULES.md                 # Module customization guide
├── README-SOURCE.md           # This file
└── freeswitch/
    ├── conf/                  # Configuration files
    ├── db/                    # SQLite databases
    ├── recordings/            # Call recordings
    ├── storage/               # Voicemail storage
    ├── scripts/               # Custom scripts
    └── logs/                  # Log files
```

## Configuration

### Initial Setup

On first run, copy the vanilla configuration:

```bash
# Start container
docker-compose -f docker-compose.source.yml up -d

# Wait for startup
sleep 10

# Create directories
mkdir -p freeswitch/{conf,db,recordings,storage,logs,scripts}

# Copy default config
docker exec freeswitch cp -r /usr/local/freeswitch/conf/vanilla/* /usr/local/freeswitch/conf/
```

### Important Configuration Files

Located in `./freeswitch/conf/`:

- `freeswitch.xml` - Main configuration
- `vars.xml` - Global variables (CHANGE DEFAULT PASSWORDS!)
- `autoload_configs/switch.conf.xml` - Core settings
- `sip_profiles/` - SIP profiles (internal, external)
- `dialplan/` - Call routing
- `directory/` - Users and domains

## Accessing FreeSWITCH

### CLI Access

```bash
# Using docker exec
docker exec -it freeswitch fs_cli

# Common commands
fs_cli -x "status"
fs_cli -x "sofia status"
fs_cli -x "show channels"
fs_cli -x "reloadxml"
```

### Event Socket

Default port: 8021
Default password: ClueCon (CHANGE THIS!)

Edit: `freeswitch/conf/autoload_configs/event_socket.conf.xml`

## Advanced Build Options

### Build with Specific Compiler Flags

Edit `Dockerfile.source` and add to configure step:

```dockerfile
RUN ./configure \
    --prefix=/usr/local/freeswitch \
    CFLAGS="-O3 -march=native" \
    CXXFLAGS="-O3 -march=native" \
    --enable-core-pgsql-support
```

### Skip Sound Files Installation

Comment out this line in `Dockerfile.source`:

```dockerfile
# RUN make cd-sounds-install cd-moh-install
```

Saves ~100MB but no default sounds/music.

### Enable Additional Database Support

Add to configure step:

```dockerfile
RUN ./configure \
    --prefix=/usr/local/freeswitch \
    --enable-core-pgsql-support \
    --enable-core-odbc-support
```

### Add Custom Patches

Before bootstrap, add:

```dockerfile
# Apply custom patches
COPY patches/*.patch /usr/src/freeswitch/
RUN for patch in *.patch; do git apply $patch; done
```

## Multi-Architecture Builds

Build for different architectures using Docker buildx:

```bash
# Create builder
docker buildx create --name freeswitch-builder --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.source \
  -t yourusername/freeswitch:latest \
  --push .
```

## Troubleshooting

### Build Fails

**Out of memory:**
```bash
# Reduce parallel jobs
docker build --build-arg MAKE_JOBS=1 ...
```

**Missing dependencies:**
```bash
# Check builder stage logs
docker build --progress=plain -f Dockerfile.source .
```

**Git clone fails:**
```bash
# Use specific commit instead of tag
--build-arg FREESWITCH_VERSION=abc123def
```

### Runtime Issues

**Module not loading:**
```bash
# Check if module was built
docker exec freeswitch ls /usr/local/freeswitch/mod/

# Check dependencies
docker exec freeswitch ldd /usr/local/freeswitch/mod/mod_opus.so
```

**Permission errors:**
```bash
# Fix ownership
docker exec -u root freeswitch chown -R freeswitch:freeswitch /usr/local/freeswitch
```

**Can't find fs_cli:**
```bash
# It's linked to /usr/bin/fs_cli
docker exec freeswitch which fs_cli
```

## Performance Tuning

### Resource Limits

In `docker-compose.source.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '2'
      memory: 2G
```

### System Settings

For production, tune host system:

```bash
# Increase file descriptors
ulimit -n 65536

# Disable SELinux (if applicable)
setenforce 0

# Configure kernel parameters
sysctl -w net.ipv4.ip_local_port_range="16384 65535"
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
```

## Security

### Change Default Passwords

1. Edit `freeswitch/conf/vars.xml`:
```xml
<X-PRE-PROCESS cmd="set" data="default_password=YOUR_SECURE_PASSWORD"/>
```

2. Edit `freeswitch/conf/autoload_configs/event_socket.conf.xml`:
```xml
<param name="password" value="YOUR_SECURE_ESL_PASSWORD"/>
```

3. Restart:
```bash
docker-compose -f docker-compose.source.yml restart
```

### Firewall Rules

```bash
# Allow only necessary ports
ufw allow 5060/tcp
ufw allow 5060/udp
ufw allow 64535:65535/udp

# Restrict Event Socket to localhost
ufw deny 8021/tcp
```

### TLS/SRTP

Built with `--enable-zrtp` and `--enable-srtp`

Configure in SIP profiles for encrypted media.

## Comparison: Source vs Package

| Aspect | Build from Source | Package Install |
|--------|------------------|-----------------|
| Build time | 15-30 minutes | 2-3 minutes |
| Customization | Full control | Limited |
| Image size | 600-800 MB | 400-600 MB |
| Updates | Manual rebuild | apt upgrade |
| Bleeding edge | Yes (master) | No |
| Stability | Varies | Tested releases |
| Repository access | Not needed | Needs credentials |

## Updating FreeSWITCH

```bash
# Rebuild with new version
./build-from-source.sh -v v1.10.13

# Or edit docker-compose.source.yml and rebuild
docker-compose -f docker-compose.source.yml build --no-cache

# Backup config first!
cp -r freeswitch/conf freeswitch/conf.backup

# Restart with new image
docker-compose -f docker-compose.source.yml up -d
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build FreeSWITCH

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build image
        run: |
          docker build -f Dockerfile.source \
            --build-arg FREESWITCH_VERSION=v1.10.12 \
            -t myregistry/freeswitch:latest .
      
      - name: Push to registry
        run: |
          docker push myregistry/freeswitch:latest
```

## Development

### Building for Development

```bash
# Build with debug symbols
docker build -f Dockerfile.source \
  --build-arg CFLAGS="-g -O0" \
  -t freeswitch-debug .

# Mount source for live development
docker run -it \
  -v $(pwd)/src:/usr/src/freeswitch \
  freeswitch-debug bash
```

## Support

- [FreeSWITCH Documentation](https://freeswitch.org/confluence/)
- [GitHub Issues](https://github.com/signalwire/freeswitch/issues)
- [Mailing List](https://freeswitch.org/confluence/display/FREESWITCH/Community)
- [Discord](https://discord.gg/freeswitch)

## License

FreeSWITCH is licensed under MPL 1.1 (Mozilla Public License)
