# Start from ROCm PyTorch base image
FROM rocm/pytorch:latest

# Set working directories
ENV COMFY_DIR=/app/comfyui
WORKDIR /app

# Copy install script into the container
COPY install.sh /app/install.sh
RUN chmod +x /app/install.sh

# Install required software
RUN apt-get update && apt-get install python3 python3-pip
RUN mkdir -p /app && chown -R 1000:1000 /app
RUN pip install comfy-cli

USER 1000:1000
RUN <<EOR
  # Explicitly disable tracking
  # no-so-fun fact: comfy will ask you if you want to disable tracking before the command to disable tracking goes through.
  #                 why?!
  printf "n\n" | comfy tracking disable
  
  # We will be prompted if we really want to install comfyui in the workspace location, so we pass in "y"
  printf "y\n" | comfy --workspace=/app/comfyui install --amd
EOR

# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

# Default command
CMD ["comfy", "launch"]

