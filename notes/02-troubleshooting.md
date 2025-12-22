# Troubleshooting

## Build permission issues (`--fakeroot`)

Symptoms:
- `apptainer build --fakeroot ...` fails with messages about user namespaces / subuid/subgid.

Fix options:
- Ask admins to configure `/etc/subuid` + `/etc/subgid` for your user and enable user namespaces.
- Use remote build: `apptainer build --remote warptools_cuda118.sif apptainer/warptools_cuda118.def`
- Build on a workstation (root) and copy the `.sif` to the cluster.

## TLS/OCI pull errors (`tls: bad record MAC`)

Symptoms:
- `conveyor failed to get: error writing layer: local error: tls: bad record MAC`
- Other transient TLS/connection reset errors when fetching the base image.

Fixes:
- Retry the build (the script retries transient pull errors; tune with `APPTAINER_BUILD_RETRIES` and `APPTAINER_BUILD_RETRY_DELAY`).
- If you are behind a proxy, ensure `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` are set correctly.
- Try a more reliable network or a registry mirror.

## `WarpTools` not found

Symptoms:
- `WarpTools: command not found` inside the container.

Notes:
- Some Warp versions expose `warp` as the primary CLI entry point.

Fix:
- Try `warp --help` (the smoke test does this fallback automatically).
- Inspect `/opt/conda/envs/warp/bin` inside the container:
  - `apptainer exec warptools_cuda118.sif bash -lc 'ls -la /opt/conda/envs/warp/bin | head'`

## Conda solve issues / slow builds

Symptoms:
- Mamba/conda solve takes a long time, or fails to resolve.

Fixes:
- Ensure channel order matches upstream:
  - `-c warpem -c nvidia/label/cuda-11.8.0 -c pytorch -c conda-forge`
- Use flexible channel priority (strict can conflict with the pinned pytorch build).
- If a specific version disappears upstream, update the fallback pin and re-run:
  - `./scripts/verify_warp_pin.py`

## GPU usage (`--nv`)

Symptoms:
- Torch reports `cuda available: False` even on a GPU node.

Fixes:
- Ensure you run with `--nv`:
  - `apptainer exec --nv warptools_cuda118.sif ...`
- Confirm the host sees the GPU:
  - `nvidia-smi`
- Ensure the host driver is compatible with the CUDA runtime.

## PATH / activation issues

Symptoms:
- `conda` works but WarpTools doesn’t, or vice-versa.

Fix:
- The definition sets `PATH` to include `/opt/conda/envs/warp/bin` in `%environment`.
- If you override PATH externally, run through a login shell:
  - `apptainer exec warptools_cuda118.sif bash -lc 'WarpTools --help'`
