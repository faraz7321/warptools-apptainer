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

BUILD_LOG=""
build_retries="${APPTAINER_BUILD_RETRIES:-2}"
retry_delay="${APPTAINER_BUILD_RETRY_DELAY:-15}"
force_fakeroot="${APPTAINER_FORCE_FAKEROOT:-0}"

is_transient_error() {
  local log="$1"
  grep -Eqi 'tls: bad record mac|tls handshake timeout|connection reset by peer|i/o timeout|temporary failure in name resolution|unexpected EOF' "$log"
}

is_fakeroot_error() {
  local log="$1"
  grep -Eqi 'could not use fakeroot|no mapping entry found in /etc/subuid|newuidmap|newgidmap|user namespace' "$log"
}

run_build() {
  local -a cmd=("$@")
  local log
  log="$(mktemp)"
  set +e
  "${cmd[@]}" |& tee "$log"
  local rc=${PIPESTATUS[0]}
  set -e
  BUILD_LOG="$log"
  return "$rc"
}

build_with_retry() {
  local -a cmd=("$@")
  local attempt=0
  local rc

  while true; do
    attempt=$((attempt + 1))
    if run_build "${cmd[@]}"; then
      rm -f "$BUILD_LOG"
      BUILD_LOG=""
      return 0
    fi
    rc=$?
    if [[ -n "${BUILD_LOG}" ]] && is_transient_error "${BUILD_LOG}" && (( attempt <= build_retries )); then
      local next_attempt=$((attempt + 1))
      local max_attempt=$((build_retries + 1))
      echo "Transient OCI fetch error; retrying (${next_attempt}/${max_attempt}) in ${retry_delay}s..." >&2
      rm -f "$BUILD_LOG"
      BUILD_LOG=""
      sleep "$retry_delay"
      continue
    fi
    return "$rc"
  done
}

use_fakeroot=1
if [[ "$(id -u)" -eq 0 && "${force_fakeroot}" != "1" ]]; then
  use_fakeroot=0
fi

build_cmd=("${runner}" build)
if (( use_fakeroot )); then
  build_cmd+=(--fakeroot)
fi
build_cmd+=("${out_sif}" "${def_file}")

echo "Building ${out_sif} from ${def_file}"
echo "Command: ${build_cmd[*]}"

if build_with_retry "${build_cmd[@]}"; then
  exit 0
fi

rc=$?

if (( use_fakeroot )) && [[ -n "${BUILD_LOG}" ]] && is_fakeroot_error "${BUILD_LOG}"; then
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Fakeroot build failed, but running as root; retrying without --fakeroot" >&2
    rm -f "$BUILD_LOG"
    BUILD_LOG=""
    if build_with_retry "${runner}" build "${out_sif}" "${def_file}"; then
      exit 0
    fi
    rc=$?
  elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    echo "Fakeroot build failed; retrying with sudo without --fakeroot" >&2
    rm -f "$BUILD_LOG"
    BUILD_LOG=""
    if build_with_retry sudo "${runner}" build "${out_sif}" "${def_file}"; then
      exit 0
    fi
    rc=$?
  else
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
    rm -f "$BUILD_LOG"
    exit "${rc}"
  fi
fi

if [[ -n "${BUILD_LOG}" ]] && is_transient_error "${BUILD_LOG}"; then
  cat >&2 <<'EOF'
Build failed while fetching OCI layers over TLS.
Try re-running, or set APPTAINER_BUILD_RETRIES / APPTAINER_BUILD_RETRY_DELAY to tune retries.
EOF
fi

rm -f "$BUILD_LOG"
exit "${rc}"
