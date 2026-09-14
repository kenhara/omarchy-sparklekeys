# Sparklekeys — security review fix map (marketplace #4406)

Resolution map for the four filesystem-boundary findings raised in the
maintainer security review on
[omacom/omarchy-plugin-marketplace#4406](https://github.com/omacom/omarchy-plugin-marketplace/issues/4406).

All findings were addressed in the `progress.py` hardening (shipped in the
`1.0.2` resubmission release). Trust model unchanged: progress I/O is a local
Python helper only — no network, no clipboard, no `xdg-open`, no sudo. Data
lives at `~/.local/share/sparklekeys/progress.json` (earned progress, never in
`~/.cache`).

| ID | Sev | Finding (at reviewed commit `be1b892`) | Fix | Proof |
|----|-----|----------------------------------------|-----|-------|
| **SK-01** | HIGH | Path creation used `os.makedirs` / `os.chmod` on full pathnames → a symlinked ancestor could redirect the write outside the trust root. | `open_progress_dir()` walks `$HOME → data-home → sparklekeys` holding a retained `O_DIRECTORY\|O_NOFOLLOW` dirfd at each step (`_open_dirat`). Directories are created with `os.mkdir(name, 0o700, dir_fd=parent)` and tightened with `os.fchmod(fd, 0o700)` — a pathname is never passed to `makedirs`/`chmod`. Every walked component is `fstat`-checked for owner and no group/other-write. | `--self-check` symlink-parent case; `prove-progress.sh` "planted sparklekeys dir symlink → exit 1". |
| **SK-02** | HIGH | `read_cache()` validated only the final pathname, leaving mutable ancestors unchecked (TOCTOU / ancestor swap). | `read_cache()` opens the leaf **relative to the dirfd** returned by the full NOFOLLOW walk (`open_progress_dir(create=False)`), with `O_RDONLY\|O_NOFOLLOW\|O_NONBLOCK\|O_CLOEXEC`, then `fstat`-validates it is a regular, user-owned, non-group/other-write file before reading up to `cap+1`. | `prove-progress.sh` "planted symlink → exit 1, secret untouched"; "missing file → exit 1"; "oversize → exit 1". |
| **SK-03** | MED | Atomic write `fsync`'d the temp file but not the directory after `rename` → the rename could be lost on a crash. | `write_exclusive()` does `os.rename(tmp, leaf, src_dir_fd=leaf_fd, dst_dir_fd=leaf_fd)` then `os.fsync(leaf_fd)`, **fail-closed**: if the directory fsync raises, the write is treated as failed (exit 1) rather than silently "succeeding". | `prove-progress.sh` write round-trip ("small regular file → exact bytes"); dest-symlink and FIFO-dest write cases confirm the temp+rename path. |
| **SK-04** | MED | `progressReadProc` had no deadline / cleanup → a blocking read (e.g. a FIFO at the path) could hang the widget. | The helper opens with `O_NONBLOCK`, so a FIFO with no writer returns immediately (exit 1, no body). Defense in depth: `SparkleStore.qml` runs the read under `/usr/bin/timeout --kill-after=2s 8s …`, and the QML side enforces a 10s read deadline that falls back to defaults and tears the process down. | `prove-progress.sh` "FIFO no writer → prompt exit 1 (not 124)"; "FIFO dest write → prompt, dest is regular file". |

## Verify

Run from the repo root (target platform is Omarchy / Linux, which provides
`/usr/bin/timeout` and `/usr/bin/python3`):

```
python3 -B scripts/progress.py --self-check      # → "self-check ok", exit 0
bash    scripts/prove-progress.sh                # → every case PASS, exit 0
python3 -m py_compile scripts/progress.py        # syntax gate
bash    -n scripts/prove-progress.sh             # syntax gate
```

Note: `scripts/prove-progress.sh` invokes `timeout` for its two FIFO no-hang
cases. On a host without coreutils `timeout` (e.g. stock macOS) those two
cases report a tooling `rc=127`; the underlying helper still exits promptly
(read `rc=1`, write `rc=0`, both sub-second) because the open path is
`O_NONBLOCK`. On the target platform all cases pass under the `timeout` guard.
