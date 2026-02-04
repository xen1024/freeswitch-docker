# FreeSWITCH Build Troubleshooting Guide

## Common Build Errors and Solutions

### 1. SpanDSP Error (Fax Support)

**Error:**
```
checking for spandsp >= 3.0... configure: error: no usable spandsp
```

**Solutions:**

#### Option A: Build SpanDSP from Source (Included in fixed Dockerfile.source)
The updated Dockerfile.source now builds SpanDSP from source automatically.

#### Option B: Build Without Fax Support (Fastest)
Use `Dockerfile.source-nofax` which disables fax modules:
```bash
docker build -f Dockerfile.source-nofax -t freeswitch:nofax .
```

#### Option C: Disable Fax Modules Manually
Edit modules.conf to comment out:
```bash
#applications/mod_spandsp
#applications/mod_fax
```

### 2. Out of Memory During Build

**Error:**
```
c++: internal compiler error: Killed
```

**Solutions:**

```bash
# Reduce parallel jobs
docker build --build-arg MAKE_JOBS=1 -f Dockerfile.source .

# Or increase Docker memory limit
# Docker Desktop: Settings → Resources → Memory (set to 4GB+)

# On Linux, add swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 3. Git Clone Fails

**Error:**
```
fatal: unable to access 'https://github.com/signalwire/freeswitch.git/'
```

**Solutions:**

```bash
# Check internet connection
ping github.com

# Use mirror or specific commit
--build-arg FREESWITCH_VERSION=abc123def

# Or clone locally first
git clone https://github.com/signalwire/freeswitch.git
# Then modify Dockerfile to use COPY instead of git clone
```

### 4. Bootstrap Fails

**Error:**
```
./bootstrap.sh: line X: command not found
```

**Solutions:**

```bash
# Usually missing autotools, verify all dependencies installed
# The Dockerfile should have these, but double-check:
apt-get install -y automake autoconf libtool
```

### 5. Missing Python Development Headers

**Error:**
```
checking for python3... configure: error: python3 required
```

**Solutions:**

```bash
# Remove Python support if not needed
./configure --prefix=/usr/local/freeswitch --without-python

# Or ensure python3-dev is installed (already in Dockerfile)
```

### 6. Sofia-SIP Issues

**Error:**
```
checking for sofia-sip... no
```

**Solutions:**

```bash
# Ensure sofia-sip-ua-dev is installed
apt-get install -y libsofia-sip-ua-dev libsofia-sip-ua-glib-dev
```

### 7. Opus Codec Build Fails

**Error:**
```
mod_opus.c: error: 'OPUS_AUTO' undeclared
```

**Solutions:**

```bash
# Disable Opus if not needed
sed -i 's|^codecs/mod_opus|#codecs/mod_opus|' modules.conf

# Or ensure libopus-dev is installed
apt-get install -y libopus-dev
```

### 8. PostgreSQL Support Issues

**Error:**
```
configure: error: Cannot find libpq
```

**Solutions:**

```bash
# Disable if not needed
./configure --disable-core-pgsql-support

# Or install
apt-get install -y libpq-dev
```

### 9. Video Codec Errors

**Error:**
```
ERROR: libx264 not found
```

**Solutions:**

```bash
# Disable video modules if not needed
sed -i 's|^codecs/mod_h264|#codecs/mod_h264|' modules.conf
sed -i 's|^codecs/mod_vpx|#codecs/mod_vpx|' modules.conf

# Or install dependencies
apt-get install -y libx264-dev libvpx-dev
```

### 10. Build Cache Issues

**Error:**
Build produces old version or cached errors

**Solutions:**

```bash
# Build without cache
docker build --no-cache -f Dockerfile.source .

# Or clean build cache
docker builder prune -af
```

## Quick Fixes Reference

### Use No-Fax Build (Recommended)
```bash
docker build -f Dockerfile.source-nofax -t freeswitch:latest .
```

### Minimal Build (Fastest)
```bash
docker build -f Dockerfile.source-minimal -t freeswitch:minimal .
```

### Reduce Memory Usage
```bash
docker build --build-arg MAKE_JOBS=1 \
             --memory=2g \
             -f Dockerfile.source .
```

### Build Specific Version
```bash
docker build --build-arg FREESWITCH_VERSION=v1.10.11 \
             -f Dockerfile.source .
```

### Skip Sound Files
Comment out this line in Dockerfile:
```dockerfile
# RUN make cd-sounds-install cd-moh-install
```

## Dockerfile Variants Comparison

| Dockerfile | SpanDSP | Modules | Build Time | Size |
|-----------|---------|---------|------------|------|
| Dockerfile.source | Builds from source | All | ~25 min | ~800 MB |
| Dockerfile.source-nofax | No (disabled) | Most | ~20 min | ~750 MB |
| Dockerfile.source-minimal | Optional | Essential | ~12 min | ~400 MB |

## Recommended Build Strategy

### For Production (Full Features)
```bash
# Use updated source build with SpanDSP
docker build -f Dockerfile.source -t freeswitch:prod .
```

### For Production (No Fax)
```bash
# Faster, more reliable build
docker build -f Dockerfile.source-nofax -t freeswitch:prod .
```

### For Development/Testing
```bash
# Minimal build
docker build -f Dockerfile.source-minimal -t freeswitch:dev .
```

## Verifying Build Success

After building, verify:

```bash
# Check image exists
docker images | grep freeswitch

# Test run
docker run --rm freeswitch:latest freeswitch -version

# Check modules
docker run --rm freeswitch:latest ls /usr/local/freeswitch/mod/

# Test startup
docker run -d --name test-fs freeswitch:latest
sleep 10
docker exec test-fs fs_cli -x "status"
docker rm -f test-fs
```

## Getting Help

If you encounter issues not covered here:

1. **Check build logs:**
   ```bash
   docker build --progress=plain -f Dockerfile.source . 2>&1 | tee build.log
   ```

2. **Check specific module errors:**
   Look for lines containing "ERROR:" or "failed" in build.log

3. **Community resources:**
   - FreeSWITCH Mailing List
   - FreeSWITCH Discord
   - Stack Overflow (tag: freeswitch)

4. **Provide information when asking for help:**
   - Docker version: `docker --version`
   - System: `uname -a`
   - Memory: `free -h`
   - Build command used
   - Relevant error messages

## Performance Optimization

### Speed Up Builds

```bash
# Use more parallel jobs (if you have RAM)
docker build --build-arg MAKE_JOBS=8 -f Dockerfile.source .

# Use BuildKit
export DOCKER_BUILDKIT=1
docker build -f Dockerfile.source .

# Use build cache
# First build will be slow, subsequent builds faster
```

### Reduce Image Size

```bash
# Use minimal build
docker build -f Dockerfile.source-minimal .

# Skip sounds
# Comment out: RUN make cd-sounds-install cd-moh-install

# Disable unused modules
# Edit modules.conf before configure step
```

## Advanced Debugging

### Interactive Build Debugging

```bash
# Build up to a certain step
docker build --target builder -f Dockerfile.source -t fs-builder .

# Run shell in builder
docker run -it fs-builder bash

# Manually run configure/make
cd /usr/src/freeswitch
./configure --help
```

### Module-Specific Issues

```bash
# Check specific module requirements
./configure --help | grep -A2 "module-name"

# Test build single module
make mod_opus
```

## Success Indicators

A successful build should show:

```
Successfully built abc123def
Successfully tagged freeswitch:latest
```

And when running:

```bash
docker run --rm freeswitch:latest freeswitch -version
# Should output: FreeSWITCH version 1.10.12 (64bit)
```
