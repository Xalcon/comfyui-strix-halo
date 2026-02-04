# Start from ROCm PyTorch base image
FROM rocm/pytorch:latest

ARG BOX_UID=1000
ARG BOX_GID=1000

# Set working directories
ENV COMFY_DIR=/app/comfyui
WORKDIR /app

RUN apt-get update && apt-get install -y \
        python3 python3-pip \
        git nano neovim wget curl \
    && pip install comfy-cli \
    && mkdir -p /app \
    && printf "\ny\n" | comfy --workspace=/app/comfyui install --amd

# We delete the default ubuntu user/group to avoid conflicts when the image is used with distrobox
RUN userdel -r ubuntu || true \
    && groupdel ubuntu || true
    
# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

USER ${BOX_UID}:${BOX_GID}

# Default command
# CMD ["comfy", "launch"]

