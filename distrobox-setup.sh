#!/bin/bash
set -e

DISTROBOX_NAME="comfyui"
BASE_IMAGE_NAME="comfyui-strix-halo"
DISTRBOX_HOME="$HOME/.distrobox/$DISTROBOX_NAME/home"
BOX_UID=$(id -u)
BOX_GID=$(id -g)

# Check if distrobox is installed
if ! command -v distrobox &> /dev/null; then
    echo "Distrobox is not installed. Please install it first."
    exit 1
fi

# Check if rocm is installed on the system
if ! command -v rocminfo &> /dev/null; then
    echo "ROCm is not installed. Please install it first."
    exit 1
fi

# check if we can build docker images
if ! docker info > /dev/null 2>&1; then
    echo "Docker does not seem to be running or you do not have permissions to run docker commands."
    echo "Please ensure docker or a docker compatible runtime is installed and running."
    exit 1
fi

docker build -t comfyui-strix-halo .

# Check if the distrbox already exists
if distrobox list | grep -q "$DISTROBOX_NAME"; then
    echo "Distrobox '$DISTROBOX_NAME' already exists. Skipping creation."
else
    # Create a new distrobox
    echo "Creating distrobox '$DISTROBOX_NAME'..."
    # The box needs access to the GPU devices, so we add the necessary flags to allow that.
    distrobox create \
        --name "$DISTROBOX_NAME" \
        --image "$BASE_IMAGE_NAME" \
        --home "$DISTRBOX_HOME" \
        --volume "./data/models:/app/comfyui/models:rw" \
        --volume "./data/user:/app/comfyui/user:rw" \
        --volume "./data/inputs:/app/comfyui/inputs:rw" \
        --volume "./data/outputs:/app/comfyui/outputs:rw" \
        --additional-flags " \
            --device /dev/kfd \
            --device /dev/dri \
            --group-add video \
            --group-add render \
            --security-opt seccomp=unconfined"
fi

echo "Fixing permissions for venv inside the distrobox $DISTROBOX_NAME..."
distrobox enter "$DISTROBOX_NAME" -- bash -c "sudo chown -R ${BOX_UID}:${BOX_GID} /opt/venv /app/comfyui"

echo "Distrobox '$DISTROBOX_NAME' is set up and ready to use."
echo "To enter the distrobox, run: distrobox enter $DISTROBOX_NAME"