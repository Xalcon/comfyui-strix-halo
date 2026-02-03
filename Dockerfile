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
# We Explicitly disable tracking (Unfortunately its still interactive even though it shouldnt be)
# and then we install comfyui, which also prompts interactively if the paths are correct 
RUN printf "n\n" | comfy tracking disable \
    && printf "y\n" | comfy --workspace=/app/comfyui install --amd
    
# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

# Default command
CMD ["comfy", "launch"]

