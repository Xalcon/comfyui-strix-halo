echo "Update apt cache"
sudo apt update
echo "Installing python3"
sudo apt install python3 python3-pip python3-venv

echo "Preparing workspace"
sudo mkdir /app
sudo chown -R 1000:1000 /app
cd /app

#python3 -m venv comfy-env
#source comfy-env/bin/activate

echo "Installing comfy-cli via pip"
pip install comfy-cli

# Add autocomplete for cli
echo "Registering comfy cli auto complete"
comfy --install-completion

# install comfyui and accept installing from github to the target workspace
echo "Installing comfyui in workspace"
# Note: In some cases the installer asks if we want to send tracking data, which default is NO.
#       Sending nothing should use the default and if the prompt doesnt show up and it prompts for the 
#       install location instead, we will be asked again
printf "\ny\n" | comfy --workspace=/app/comfyui install --amd

printf "n\n" | comfy tracking disable

sudo chown -R 1000:1000 /app

# Usually you would install PyTorch now, but its already installed in this docker container
echo "installation complete"
