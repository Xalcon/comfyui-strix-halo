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
# comfy install needs to run as root in this container because the rocm base image did install all packages as root and changing the ownership here would grow the size of the layer massively
RUN pip install comfy-cli \
    && printf "\ny\n" | comfy --workspace=/app/comfyui install --amd \
    && chown -R 1000:1000 /app

USER 1000:1000
# Explicitly disable tracking (Unfortunately its still interactive even though it shouldnt be)
# Also make prepare user editable directories for mounting
RUN printf "n\n" | comfy tracking disable \
    && mv $COMFY_DIR/blueprints $COMFY_DIR/.default.blueprints \
    && mv $COMFY_DIR/user $COMFY_DIR/.default.user \
    && mv $COMFY_DIR/custom_nodes $COMFY_DIR/.default.custom_nodes \
    && mv $COMFY_DIR/models $COMFY_DIR/.default.models \
    && mv $COMFY_DIR/input $COMFY_DIR/.default.input \
    && mv $COMFY_DIR/output $COMFY_DIR/.default.output
    
# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

# Default command
CMD ["bash", "-c", "launch.sh"]

