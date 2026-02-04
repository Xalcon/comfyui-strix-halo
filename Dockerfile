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

# Files in the container need to be owned by someone that is not root or we will run into issues later on
# We also delete the ubuntu user that exists in the base image since it has the UID 1000, which can clash with host users in our distrobox setup
# Note: We explicitly do not change the permissions of th /opt/venv here since that would bloat the image size significantly
#       Instead, the setup scripts will take care of fixing permissions on first run
RUN chown -R ${BOX_UID}:${BOX_GID} /app \
    && chmod -R 755 /app \
    && userdel -r ubuntu || true \
    && groupdel ubuntu || true
    
# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

# Default command
# CMD ["comfy", "launch"]

