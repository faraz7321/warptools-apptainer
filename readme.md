# WarpTools in Apptainer (CUDA 11.8, Ubuntu 20.04)

## Overview

This repository builds a **reproducible Apptainer (Singularity successor) container** for **HPC usage** that includes **WarpTools** (installed via the official **Warp conda channel**, pinned to a compatible `2.0.0dev*` build available for `linux-64`).

Upstream guide used as the source of truth:
- `https://github.com/warpem/warp#linux`

Upstream Linux install command (for reference):

```bash
conda create -n warp warp -c warpem -c nvidia/label/cuda-11.8.0 -c pytorch -c conda-forge
```

This repository contains **standardized, reproducible environments**, containerized workflows that run consistently on shared compute infrastructure, and documentation in git so others can reproduce the build and troubleshoot issues.

Key points:
- Base image: `nvidia/cuda:11.8.0-runtime-ubuntu20.04`
- Install method: conda (Miniforge + mamba) into `/opt/conda`
- Default run: `WarpTools --help` via `%runscript` so `apptainer run … --help` works
- GPU usage: `apptainer exec --nv …`

## Requirements

This repo is designed for **full automation via Ansible**. You only need:

- Ubuntu 20.04+ (examples below include Ubuntu 24.04)
- Python 3 + pip (to install Ansible)

The playbooks handle installing Apptainer and building the container.

## Quick start

```bash
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip ansible

ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -K ansible/playbooks/build_container.yml
```

Optional GPU check:

```bash
APPTAINER_NV_TEST=1 ./scripts/test.sh
```

## Build

Build without root (preferred on HPC if supported):

```bash
./scripts/build.sh
```

This runs:

```bash
apptainer build --fakeroot warptools_cuda118.sif apptainer/warptools_cuda118.def
```

If fakeroot is not available, `scripts/build.sh` prints pragmatic alternatives (remote build, build-as-root elsewhere, admin configuration hints).

## Run

Default run (uses `%runscript`):

```bash
apptainer run warptools_cuda118.sif --help
```

Explicit exec:

```bash
apptainer exec warptools_cuda118.sif WarpTools --help
```

If the binary name differs in your installed Warp version try:

```bash
apptainer exec warptools_cuda118.sif warp --help
```

## GPU notes (`--nv`)

To bind host NVIDIA libraries/drivers into the container:

```bash
apptainer exec --nv warptools_cuda118.sif WarpTools --help
```

## Smoke test

```bash
./scripts/test.sh
```

Optional GPU check (non-fatal):

```bash
APPTAINER_NV_TEST=1 ./scripts/test.sh
```

## What’s included / repo layout

- `apptainer/warptools_cuda118.def` — Apptainer definition (CUDA 11.8 runtime base, conda install, WarpTools runscript)
- `scripts/build.sh` — builds `warptools_cuda118.sif` with `--fakeroot` and prints helpful guidance if it fails
- `scripts/test.sh` — smoke tests: `WarpTools --help` + `conda list warp` (plus optional `--nv` check)
- `notes/00-plan.md` — short plan + assumptions
- `notes/01-build-log.md` — template to paste build output / logs
- `notes/02-troubleshooting.md` — common issues + fixes
- `ansible/` — optional playbooks to provision Apptainer and build the image on Debian/Ubuntu
- `.github/workflows/` — CI checks (lint + verify pinned Warp version exists upstream)

## Tools used (with official install guides)

- Apptainer (container runtime): https://github.com/apptainer/apptainer/blob/main/INSTALL.md
- Warp (Linux install via conda channels): https://github.com/warpem/warp#linux
- Miniforge (Conda distribution used in the container build): https://github.com/conda-forge/miniforge
- Mamba (faster conda solver): https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html
- Ansible (automation): https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
- NVIDIA Container Runtime / `--nv` usage (Apptainer GPU docs): https://apptainer.org/docs/user/main/gpu.html

## Next steps

- Add a CPU-only variant (smaller image) if Warp packaging supports it.
- Lock dependencies more tightly (e.g., conda lockfile) for fully deterministic solves.
- Add a deeper functional test (small dataset) if a public sample can be used.