cd /app

echo "Installing comfy-cli via pip"
pip install comfy-cli

# Add autocomplete for cli
echo "Registering comfy cli auto complete"
comfy --install-completion

printf "n\n" | comfy tracking disable

# install comfyui and accept installing from github to the target workspace
echo "Installing comfyui in workspace"
# We will be prompted if we really want to install comfyui in the workspace location, so we pass in "y"
printf "y\n" | comfy --workspace=/app/comfyui install --amd

# Usually you would install PyTorch now, but its already installed in this docker container
echo "installation complete"
