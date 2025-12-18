#!/usr/bin/env bash
set -euo pipefail

def_file="${1:-apptainer/warptools_cuda118.def}"
out_sif="${2:-warptools_cuda118.sif}"

if [[ ! -f "${def_file}" ]]; then
  echo "Definition file not found: ${def_file}" >&2
  exit 2
fi

runner="${APPTAINER_BIN:-apptainer}"
if ! command -v "${runner}" >/dev/null 2>&1; then
  if command -v apptainer >/dev/null 2>&1; then
    runner="apptainer"
  elif command -v singularity >/dev/null 2>&1; then
    runner="singularity"
  else
    echo "Neither 'apptainer' nor 'singularity' found in PATH." >&2
    exit 127
  fi
fi

echo "Building ${out_sif} from ${def_file}"
echo "Command: ${runner} build --fakeroot ${out_sif} ${def_file}"

set +e
"${runner}" build --fakeroot "${out_sif}" "${def_file}"
rc=$?
set -e

if [[ "${rc}" -ne 0 ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Fakeroot build failed, but running as root; retrying without --fakeroot" >&2
    "${runner}" build "${out_sif}" "${def_file}"
    exit 0
  fi
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    echo "Fakeroot build failed; retrying with sudo without --fakeroot" >&2
    sudo "${runner}" build "${out_sif}" "${def_file}"
    exit 0
  fi

  cat >&2 <<'EOF'
Build failed.

Common reasons on HPC systems:
  - Fakeroot not configured (missing /etc/subuid & /etc/subgid entries)
  - User namespaces disabled by the kernel / cluster policy

Options:
  - If you have admin access: configure subuid/subgid and enable user namespaces.
  - If your site supports it: use remote builds:
      apptainer build --remote warptools_cuda118.sif apptainer/warptools_cuda118.def
  - If you can build as root on a workstation: build there and copy the .sif to the cluster.
EOF
  exit "${rc}"
fi
