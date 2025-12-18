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

- `apptainer` (or `singularity`) installed on the build machine
- For non-root builds: user namespaces + fakeroot configured (or use remote build)

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