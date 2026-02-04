# Setting up ComfyUI on Strix Halo

This document describes how to run ComfyUI in a Distrobox container on a Strix Halo–based Mini PC (Bosgame M5 with Ryzen AI Max+ 395). The setup uses **ROCm 7.2** and **Linux kernel ≥ 6.18.4**, which includes critical bug fixes and significantly improves system stability on this platform.

For background on the issues addressed by these specific versions, see:
[https://www.youtube.com/watch?v=Hdg7zL3pcIs](https://www.youtube.com/watch?v=Hdg7zL3pcIs)

## Environment and prerequisites

At the time of writing, several required components are very recent and not yet available (or fully functional) in most stable distributions. For this reason, the setup below is based on **Arch Linux 2026.02** with a minimal server installation.

### Base system

1. Install Arch Linux (for example, using `archinstall`).
2. Ensure the system is running **kernel 6.18.4 or newer**.
3. Verify that the AMD GPU driver stack is working correctly.
   (In my case, `archinstall` handled this automatically.)

Some required packages are only available via the AUR, so installing an AUR helper is recommended. The examples below assume [`yay`](https://github.com/Jguer/yay).

### Required packages

Install the following packages (you may use `yay` for all of them to simplify AUR handling):

* `docker` (can be installed during `archinstall`)
* `git`
* `distrobox`
* `rocm-nightly-gfx1151-bin`

> **Note:**
> Make sure to select the ROCm package matching your GPU.
> `gfx1151` corresponds to the Ryzen AI Max+ 395 APU with Radeon 8060S.

## Running ComfyUI (use via Distrobox)

This project is intended to be run via `distrobox` rather than directly with `docker run`/`docker compose`.

- Alternatives: You can install ComfyUI directly on a host system (for example via `pip` or the project installer), but that approach installs packages and dependencies system-wide and can pollute or conflict with the host environment. To avoid altering your base system with unrelated packages, this repository prefers running ComfyUI in an isolated container environment.

- Docker note: in many projects `docker run` or `docker compose` would be the standard way to isolate installation and dependencies. However, for this setup Docker is not the recommended primary option: ComfyUI mutates its workspace and runtime state frequently, and typical Docker workflows treat containers as immutable images. While Docker can be used with explicit bind mounts and published ports, using plain Docker images for an actively mutating workspace often leads to awkward permission, rebuild, and lifecycle friction. For this reason the distrobox workflow (which provides an interactive, writable container-like environment with convenient mounts and device passthrough) is recommended here.

By default ComfyUI listens on `127.0.0.1:8188` inside the container. That means the service is only reachable from the host (localhost) unless you explicitly add a network-facing proxy or publish ports. For security, this repository intentionally keeps ComfyUI bound to localhost.

If you need access from a different machine on your LAN, you must add a reverse proxy on the host (for example `nginx`) to forward requests to `127.0.0.1:8188`. Do not expose ComfyUI directly to the internet without proper authentication and TLS.

Create the distrobox container using the included `distrobox-setup.sh` script rather than copying inline commands here. This keeps the README concise and ensures the creation flags and mounts are kept in a single, maintainable script.

```bash
# make the setup script executable and run it (adjust as needed)
chmod +x distrobox-setup.sh
./distrobox-setup.sh
```

After the script completes, enter the container and launch ComfyUI:

```bash
distrobox enter comfyui
# inside the box:
comfy launch
```

Notes:
- `comfy launch` is the recommended start command once inside the distrobox/container.
- The setup script contains the device passthrough and mount flags used for GPU/ROCm workloads; edit the script if you need to change mounts or devices.
- This README intentionally omits an `nginx` reverse-proxy example; add a proxy on the host if you want LAN access and secure it with authentication/TLS.
- The included `distrobox-setup.sh` creates the box with a custom home directory (the script uses `--home /home/user/comfyui` by default). This keeps the container environment isolated and prevents files or virtualenvs from polluting your main home directory.

### distrobox container setup explained

What `distrobox-setup.sh` does (summary):

- Device & groups: adds `--device /dev/kfd` and `--device /dev/dri`, and `--group-add video --group-add render` so the container user can access AMD GPU devices via ROCm.
- Custom home: remaps the container home directory (the script uses `--home /home/user/comfyui` by default) to prevent virtualenvs or other container files from polluting your main home directory.
- In-container chown: after creating the box the script performs a `chown` inside the container to grant your user ownership of the virtualenv (`/opt/venv`). The base ROCm image leaves that directory owned by `root`; changing ownership during image build would significantly increase image layer size, so the script fixes permissions at runtime instead.
- Persistent mounts: binds host folders (for example `./data/models`, `./data/user`, `./data/inputs`, `./data/outputs`) into `/app/comfyui/...` so ComfyUI has persistent storage for models and outputs.

If you prefer to manage directories yourself, you can still create and mount them manually before running the setup script, but it's not required.

## Installing custom nodes

ComfyUI includes a built-in Manager UI that can search for and install many popular custom nodes. Use the Manager when possible for the simplest experience.

### Manual installation (when needed):

1. Enter the distrobox:

```bash
distrobox enter comfyui
```

2. Inside the container, place the custom node repository inside the ComfyUI workspace `custom_nodes/` directory. For example:

```bash
cd /app/comfyui/custom_nodes
git clone <repo-url>
```

3. If the custom node provides a `requirements.txt`, install Python dependencies inside the container so they don't affect the host system:

```bash
python -m pip install -r <node-name>/requirements.txt
```

4. Restart ComfyUI so it discovers and loads the new node(s):

```bash
# stop the running process (if any) and relaunch
comfy launch
```

Important: read the README for the custom node you plan to install — some nodes require additional system libraries, model files, or configuration steps beyond Python packages. Installing requirements inside the container preserves host cleanliness and follows the distrobox workflow described above.

## Storage & VRAM recommendations

ComfyUI and the ROCm toolchain require substantial disk space and shared memory. Plan for at least **45 GB** for the base image plus additional room for models, caches, and generated outputs; if you work with large models, consider provisioning 200 GB or more depending on your needs.

If your workload needs more GPU-accessible shared memory (used as VRAM by the ROCm stack), you can increase the system GTT/VRAM limits via kernel boot parameters. On systems using `systemd-boot` (common with `archinstall`) the changes are made in `/boot/loader/entries/<your-entry>.conf` — for example, append the following to the `options` line to make a large GTT allocation on a 128 GB machine:

```
amd_iommu=off amdgpu.gttsize=126976 ttm.pages_limit=32505856
```

Notes and safety:
- The example values above allocate roughly 124 GB of system RAM for use as GTT/VRAM on a 128 GB machine; do not expose the entire host RAM — leave headroom for the OS and other processes.
- Exact values depend on your system RAM and stability needs; only change boot parameters if you understand the implications and have a recovery path.
- After editing your boot entry, reboot and verify the change with `rocm-smi`. Look for the graphics agent (for example `gfx1151`) and confirm the pool size. ComfyUI's logs will also reflect the available memory.

If you're unsure, the default system settings are safe and will work for most experiments — only tune the GTT/VRAM if you need to run extremely large models or workloads that exhaust the default shared memory allocation.
