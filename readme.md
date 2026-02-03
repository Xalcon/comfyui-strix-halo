# Setting up ComfyUI on Strix Halo

This document describes how to run ComfyUI in a Docker container on a Strix Halo–based Mini PC (Bosgame M5 with Ryzen AI Max+ 395). The setup uses **ROCm 7.2** and **Linux kernel ≥ 6.18.4**, which includes critical bug fixes and significantly improves system stability on this platform.

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
* `docker-compose`
* `rocm-nightly-gfx1151-bin`

> **Note:**
> Make sure to select the ROCm package matching your GPU.
> `gfx1151` corresponds to the Ryzen AI Max+ 395 APU with Radeon 8060S.

## Running ComfyUI

Clone the repository containing the Docker setup and review the provided `docker-compose.yml`.

The Docker configuration launches a ComfyUI container with a working ROCm installation. By default:

* ComfyUI listens on `127.0.0.1:8188`.
* Certain features are automatically disabled by ComfyUI when binding to a non-local address, for security reasons.

This means the container is only reachable on the same machine. For the purpose of being reachable on the whole network, I've added an nginx reverse proxy. This keeps comfyui listening on 127.0.0.1 but makes it available to the local network.
NOTE: There is no authentication, dont use this as is on internet reachable devices or untrusted networks!

### Models directory

When starting the container with Docker Compose, a `models/` directory from the working directory is mounted into the container.

Because Docker may create this directory as `root` if it does not already exist, it is recommended to create it manually before running `docker compose up` to avoid permission issues.

## Notes on storage requirements

ROCm and ComfyUI are both large. Even a minimal setup requires approximately **45 GB of disk space** for the Docker image alone.

### Configuring Higher Shared Memory Limits (VRAM)
By default, my arch system exposed 64GB of my total 128GB as available VRAM. (BIOS setting is configured to allocate the minimum 512MB as recommended by other sources)
To allow the full (or close to full) use of the 128GB as VRAM, additional kernel boot parameters need to be set. See https://github.com/kyuz0/amd-strix-halo-toolboxes?tab=readme-ov-file#62-kernel-parameters-tested-on-fedora-42

Arch comes with systemd-boot intead of grub (if installed via archinstall), so the configuration slightly differs. The file to change is in /boot/loader/entries/. There may be multiple conf files in there, pick the one that applies to your setup (most likely the most recent one).
Add `amd_iommu=off amdgpu.gttsize=126976 ttm.pages_limit=32505856` to the end of the "options" line, exmaple:
```
# Created by: archinstall
# Created on: 2026-02-03_01-08-02
title   Arch Linux (linux)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=<YOUR_PART_UUID> zswap.enabled=0 rw rootfstype=ext4 amd_iommu=off amdgpu.gttsize=126976 ttm.pages_limit=32505856
```

After changing the configuration, reboot your system.

> Note: The values are for systems with 128GB ram. For stability reasons, not the full 128GB should made available. The settings above limits it to 124GB. The GTT value is the amount of shared RAM as VRAM in MB (124 x 1024 = 126976) and the ttm.page_limit is the amount of 4kb pages (124 * 1024 * 1024 / 4 = 32505856). Adapt your values accordingly

To verify if the new limits have applied, run `rocm-smi`. The output should list 2 agents. We care about the graphics agent, not the cpu agent, so look for the agent with name "gfx1151" (or whatever your gpu is). The pool info should mention a size of ~130 million KB if everything applied correctly. ComfyUIs logs should also mention the higher VRAM limit.
