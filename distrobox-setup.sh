#!/bin/bash
set -euo pipefail

# Basic configuration
DISTROBOX_NAME="comfyui"
BASE_IMAGE_NAME="comfyui-strix-halo"
DISTRBOX_HOME="$HOME/.distrobox/$DISTROBOX_NAME/home"
BOX_UID=$(id -u)
BOX_GID=$(id -g)

# --- Pretty logging helpers ---
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

log_info()  { printf "%b %s %b\n" "${BLUE}[INFO]${RESET}" "$(timestamp) -" "$*"; }
log_warn()  { printf "%b %s %b\n" "${YELLOW}[WARN]${RESET}" "$(timestamp) -" "$*"; }
log_error() { printf "%b %s %b\n" "${RED}[ERROR]${RESET}" "$(timestamp) -" "$*"; }
log_ok()    { printf "%b %s %b\n" "${GREEN}[OK]${RESET}" "$(timestamp) -" "$*"; }

# Run a command, log its start and result. Usage: run_cmd cmd arg1 arg2 ...
run_cmd() {
    printf "%b %s %b%s\n" "${CYAN}[CMD]${RESET}" "$(timestamp) -" "→" "$*"
    if "$@"; then
        log_ok "Command succeeded: $*"
        return 0
    else
        log_error "Command failed: $*"
        return 1
    fi
}

# Check prerequisites with clear logging
if ! command -v distrobox &> /dev/null; then
    log_error "Distrobox is not installed. Please install it first."
    exit 1
fi

if ! command -v rocminfo &> /dev/null; then
    log_error "ROCm is not installed. Please install it first."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    log_error "Docker does not seem to be running or you do not have permissions to run docker commands."
    log_info "Please ensure docker or a docker compatible runtime is installed and running."
    exit 1
fi

# Build the image
log_info "Building Docker image ${BASE_IMAGE_NAME}..."
run_cmd docker build -t "${BASE_IMAGE_NAME}" .

# Check if the distrobox already exists
if distrobox list | grep -q "${DISTROBOX_NAME}"; then
    log_warn "Distrobox '${DISTROBOX_NAME}' already exists. Skipping creation."
else
    log_info "Creating distrobox '${DISTROBOX_NAME}'..."
    run_cmd distrobox create \
        --name "${DISTROBOX_NAME}" \
        --image "${BASE_IMAGE_NAME}" \
        --home "${DISTRBOX_HOME}" \
        --volume "./data/models:/app/comfyui/models:rw" \
        --volume "./data/user:/app/comfyui/user:rw" \
        --volume "./data/input:/app/comfyui/input:rw" \
        --volume "./data/output:/app/comfyui/output:rw" \
        --additional-flags " \
            --device /dev/kfd \
            --device /dev/dri \
            --group-add video \
            --group-add render \
            --security-opt seccomp=unconfined"
fi

log_info "Fixing permissions for venv inside the distrobox ${DISTROBOX_NAME}..."
run_cmd distrobox enter "${DISTROBOX_NAME}" -- bash -c "sudo chown -R ${BOX_UID}:${BOX_GID} /opt/venv /app/comfyui"

log_ok "Distrobox '${DISTROBOX_NAME}' is set up and ready to use."
log_info "To enter the distrobox, run: distrobox enter ${DISTROBOX_NAME}"