#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
import urllib.request
from pathlib import Path


def parse_version(def_file: Path) -> str:
    text = def_file.read_text(encoding="utf-8")

    version_match = re.search(r'^\s*WARP_VERSION="([^"]+)"\s*$', text, flags=re.MULTILINE)
    if not version_match:
        raise ValueError(
            "Could not find WARP_VERSION in "
            f"{def_file}. Expected line like: WARP_VERSION=\"2.0.0dev36\""
        )

    return version_match.group(1)


def load_warp_versions(repodata_url: str) -> dict[str, tuple[str, dict]]:
    with urllib.request.urlopen(repodata_url, timeout=60) as resp:
        data = json.load(resp)

    all_pkgs: dict[str, dict] = {}
    all_pkgs.update(data.get("packages", {}))
    all_pkgs.update(data.get("packages.conda", {}))

    out: dict[str, tuple[str, dict]] = {}
    for filename, meta in all_pkgs.items():
        if meta.get("name") == "warp":
            version = meta.get("version")
            if version:
                out[version] = (filename, meta)
    return out


def describe(version: str, filename: str, meta: dict) -> None:
    size_mb = (meta.get("size", 0) or 0) / 1024 / 1024
    print(f"{version}: {filename} ({size_mb:.1f} MB)")
    if meta.get("sha256"):
        print(f"  sha256: {meta['sha256']}")


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    def_file = repo_root / "apptainer" / "warptools_cuda118.def"

    version = parse_version(def_file)

    repodata_url = "https://conda.anaconda.org/warpem/linux-64/repodata.json"
    versions = load_warp_versions(repodata_url)

    if version not in versions:
        print(f"ERROR: warp={version} is not available in {repodata_url}", file=sys.stderr)
        available = sorted(versions.keys())
        print("Available versions:", ", ".join(available), file=sys.stderr)
        return 2

    filename, meta = versions[version]
    print("OK: pinned version exists upstream")
    describe(version, filename, meta)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
