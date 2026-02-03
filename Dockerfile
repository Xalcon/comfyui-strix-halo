# Start from ROCm PyTorch base image
FROM rocm/pytorch:latest

# Set working directories
ENV COMFY_DIR=/app/comfyui
WORKDIR /app

# Install required software
RUN apt-get update && apt-get install -y python3 python3-pip

# comfy install needs to run as root in this container because the rocm base image did install all packages as root and changing the ownership here would grow the size of the layer massively
RUN pip install comfy-cli \
    && mkdir -p /app \
    && printf "\ny\n" | comfy --workspace=/app/comfyui install --amd

COPY launch.sh /app/launch.sh
# Copy existing folders as template directories
# They original folders will be mounted onto the host system and would lose their content
# So we back them up. The launch.sh will copy them back conditionally before launching comfy
RUN mv $COMFY_DIR/blueprints $COMFY_DIR/.default.blueprints && mkdir $COMFY_DIR/blueprints \
    && mv $COMFY_DIR/user $COMFY_DIR/.default.user && mkdir $COMFY_DIR/user \
    && mv $COMFY_DIR/custom_nodes $COMFY_DIR/.default.custom_nodes && mkdir $COMFY_DIR/custom_nodes  \
    && mv $COMFY_DIR/models $COMFY_DIR/.default.models && mkdir $COMFY_DIR/models  \
    && mv $COMFY_DIR/input $COMFY_DIR/.default.input && mkdir $COMFY_DIR/input  \
    && mv $COMFY_DIR/output $COMFY_DIR/.default.output && mkdir $COMFY_DIR/output  \
    && chown -R 1000:1000 /app \
    && chmod -R 755 /app \
    && chmod +x /app/launch.sh

USER 1000:1000

# Explicitly disable tracking (Unfortunately its still interactive even though it shouldnt be)
RUN printf "n\n" | comfy tracking disable 
    
# Set default working directory for ComfyUI
WORKDIR $COMFY_DIR

# Set environment variable needed for launch
ENV HSA_OVERRIDE_GFX_VERSION=11.0.0

# Default command
CMD ["bash", "-c", "/app/launch.sh"]

