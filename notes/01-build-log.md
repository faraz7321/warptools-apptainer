# Build log 


## Environment

- Host OS:
- Apptainer version (`apptainer --version`):
- Kernel (`uname -a`):
- GPU present? (`nvidia-smi` on host):

## Build (fakeroot)

Command:

```bash
./scripts/build.sh
```

Output (paste):

```text
<paste build output here>
```

## Smoke test

Command:

```bash
./scripts/test.sh
```

Output (paste):

```text
<paste test output here>
```

## Optional GPU test (`--nv`)

Command:

```bash
APPTAINER_NV_TEST=1 ./scripts/test.sh
```

Output:

```text
<paste output here>
```

## Common failure snippets (examples)

### Fakeroot not available

```text
ERROR  : while extracting layer: user namespaces are not enabled in your kernel
```

Suggested action:
- Use `apptainer build --remote ...` or build on a machine where fakeroot/user namespaces are configured.

### Conda solver failure

```text
Encountered problems while solving:
  - package X requires Y but none of the providers can be installed
```

Suggested action:
- Ensure channels match upstream order and use flexible channel priority.
- Try the pinned fallback version, or update the pin after checking upstream repodata.
