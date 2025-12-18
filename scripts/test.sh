#!/usr/bin/env bash
set -euo pipefail

sif="${1:-warptools_cuda118.sif}"

if [[ ! -f "${sif}" ]]; then
  echo "Image not found: ${sif}" >&2
  echo "Build it first: ./scripts/build.sh" >&2
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

echo "== WarpTools help (first 30 lines) =="
"${runner}" exec "${sif}" bash -lc 'WarpTools --help 2>/dev/null | head -n 30 || warp --help | head -n 30'

echo
echo "== conda list warp (first 80 lines) =="
"${runner}" exec "${sif}" bash -lc 'conda list warp | head -n 80'

echo
echo "== Optional GPU check (non-fatal) =="
if [[ "${APPTAINER_NV_TEST:-0}" == "1" ]]; then
  set +e
  "${runner}" exec --nv "${sif}" bash -lc 'python - <<PY\nimport torch\nprint(\"torch:\", torch.__version__)\nprint(\"cuda available:\", torch.cuda.is_available())\nif torch.cuda.is_available():\n    print(\"device:\", torch.cuda.get_device_name(0))\nPY' || true
  set -e
else
  echo "Skipping GPU test. Set APPTAINER_NV_TEST=1 to run a torch.cuda.is_available() check with --nv."
fi
