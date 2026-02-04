#!/bin/bash
# FreeSWITCH Build from Source Script

set -e

# Default values
FREESWITCH_VERSION="v1.10.12"
MAKE_JOBS=$(nproc)
IMAGE_NAME="freeswitch-source"
IMAGE_TAG="latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

show_help() {
    cat << EOF
FreeSWITCH Build from Source Script

Usage: $0 [OPTIONS]

Options:
    -v, --version VERSION    FreeSWITCH version/tag to build (default: ${FREESWITCH_VERSION})
    -j, --jobs JOBS          Number of parallel make jobs (default: ${MAKE_JOBS})
    -n, --name NAME          Docker image name (default: ${IMAGE_NAME})
    -t, --tag TAG            Docker image tag (default: ${IMAGE_TAG})
    -f, --file DOCKERFILE    Dockerfile to use (default: Dockerfile.source)
    --no-sounds              Skip installing sound files (smaller image)
    --dev                    Build development version from master branch
    -h, --help               Show this help message

Examples:
    $0                                          # Build with defaults
    $0 -v v1.10.11 -j 8                        # Build specific version with 8 jobs
    $0 --dev                                    # Build latest development version
    $0 -n mycompany/freeswitch -t 1.10.12      # Custom image name and tag
    $0 --no-sounds                              # Build without sound files

Available versions:
    v1.10.12 (latest stable)
    v1.10.11
    v1.10.10
    master (development)

EOF
}

# Parse arguments
SKIP_SOUNDS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            FREESWITCH_VERSION="$2"
            shift 2
            ;;
        -j|--jobs)
            MAKE_JOBS="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        --no-sounds)
            SKIP_SOUNDS="1"
            shift
            ;;
        --dev)
            FREESWITCH_VERSION="master"
            IMAGE_TAG="dev"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

print_header "FreeSWITCH Build Configuration"
echo "Version:        ${FREESWITCH_VERSION}"
echo "Make jobs:      ${MAKE_JOBS}"
echo "Image name:     ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Skip sounds:    ${SKIP_SOUNDS:-No}"
echo ""

# Confirm build
read -p "Proceed with build? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Build cancelled"
    exit 0
fi

print_header "Building FreeSWITCH from Source"

# Prepare build arguments
BUILD_ARGS=(
    "--build-arg" "FREESWITCH_VERSION=${FREESWITCH_VERSION}"
    "--build-arg" "MAKE_JOBS=${MAKE_JOBS}"
    "-t" "${IMAGE_NAME}:${IMAGE_TAG}"
    "-f" "${DOCKERFILE:-Dockerfile.source}"
)

# Add skip sounds if requested
if [ -n "$SKIP_SOUNDS" ]; then
    print_info "Sound files will be skipped (smaller image)"
fi

# Build the image
print_info "Starting Docker build..."
print_info "This may take 15-30 minutes depending on your system..."

if docker build "${BUILD_ARGS[@]}" . ; then
    print_header "Build Completed Successfully!"
    echo ""
    print_info "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo "Next steps:"
    echo "  1. Run container: docker run -d --net host --name freeswitch ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "  2. Check status:  docker exec freeswitch fs_cli -x 'status'"
    echo "  3. View logs:     docker logs -f freeswitch"
    echo ""
else
    print_error "Build failed!"
    exit 1
fi

# Show image size
IMAGE_SIZE=$(docker images ${IMAGE_NAME}:${IMAGE_TAG} --format "{{.Size}}")
print_info "Image size: ${IMAGE_SIZE}"
