# Plan + assumptions

## Goal

Build an **Apptainer container image** for Linux that can run **WarpTools** (cryo-EM analysis tooling) in an HPC setting, including GPU usage via `apptainer exec --nv ...`.

## Assumptions

- Target environment is HPC.
- Users prefer **non-root builds**; therefore the default build command uses `--fakeroot` if the site supports user namespaces.
- GPU nodes provide NVIDIA drivers on the host. Apptainer binds those into the container with `--nv`.

## Key decisions

- **Follow upstream Warp Linux guide**: `https://github.com/warpem/warp#linux`
- **CUDA-friendly base image**: `nvidia/cuda:11.8.0-runtime-ubuntu20.04`
  - Keeps user-space CUDA libraries aligned with the expected runtime.
  - Still relies on host driver via `--nv`.
- **Conda installation** via Miniforge + mamba to `/opt/conda`
  - Matches upstream Warp Linux install instructions (conda channels).
  - Avoids compiling Warp inside the image build.
- **Smoke test** focuses on “does it run”:
  - `WarpTools --help` works inside the container.
  - `conda list warp` shows the installed package.

## Known constraint

The upstream `warpem` channel currently publishes `2.0.0dev*` builds for `linux-64`, so the definition pins a compatible `2.0.0dev*` version directly. CI verifies the pin with `scripts/verify_warp_pin.py`.
