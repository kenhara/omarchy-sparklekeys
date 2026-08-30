#!/usr/bin/env python3
"""Bounded progress.json read/write for Sparklekeys (HC-05 + exclusive write).

Read: O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC, regular file only, cap+1.
Missing / symlink / FIFO / oversize → exit 1, no body.

Write (--write): mkdir dest dir 0700; exclusive tmp
  os.open(O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW, 0o600) → write → fsync → os.replace
Never opens dest for write (symlink dest is replaced, not followed).

--check-path: unit-test path sanitizer (absolute local path only).
"""
from __future__ import annotations

import argparse
import os
import secrets
import stat
import sys


def require_flags(*names: str) -> int:
    """Fail closed if a required open(2) flag is missing."""
    missing = [n for n in names if not hasattr(os, n)]
    if missing:
        sys.exit(1)
    flags = 0
    for n in names:
        flags |= int(getattr(os, n))
    return flags


def with_cloexec(flags: int) -> int:
    if hasattr(os, "O_CLOEXEC"):
        flags |= int(os.O_CLOEXEC)
    return flags


def is_safe_config_path(path: str) -> bool:
    """Absolute local path only: starts with /, no ://, no \\ , no leading -."""
    p = str(path or "")
    if not p:
        return False
    if not p.startswith("/"):
        return False
    if "://" in p:
        return False
    if "\\" in p:
        return False
    if p.startswith("-"):
        return False
    return True


def _close_fd(fd: int) -> None:
    if fd >= 0:
        try:
            os.close(fd)
        except Exception:
            pass


def read_cache(path: str, cap: int) -> None:
    if not path or cap < 0:
        sys.exit(1)
    flags = with_cloexec(require_flags("O_RDONLY", "O_NOFOLLOW", "O_NONBLOCK"))
    fd = -1
    data = b""
    try:
        fd = os.open(path, flags)
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            sys.exit(1)
        remaining = cap + 1
        while remaining > 0:
            chunk = os.read(fd, min(65536, remaining))
            if not chunk:
                break
            data += chunk
            remaining -= len(chunk)
    except Exception:
        sys.exit(1)
    finally:
        _close_fd(fd)

    if len(data) > cap:
        sys.exit(1)
    try:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
    except Exception:
        sys.exit(1)
    sys.exit(0)


def write_exclusive(path: str, data: bytes, cap: int) -> None:
    if not path or not path.startswith("/") or cap < 0:
        sys.exit(1)
    if "://" in path or "\\" in path:
        sys.exit(1)
    if not data or len(data) > cap:
        sys.exit(1)

    parent = os.path.dirname(path)
    if not parent or not parent.startswith("/"):
        sys.exit(1)
    try:
        os.makedirs(parent, mode=0o700, exist_ok=True)
        os.chmod(parent, 0o700)
    except Exception:
        sys.exit(1)

    flags = with_cloexec(require_flags("O_WRONLY", "O_CREAT", "O_EXCL", "O_NOFOLLOW"))
    if hasattr(os, "O_NONBLOCK"):
        flags |= int(os.O_NONBLOCK)

    dest_name = os.path.basename(path)
    tmp_path = ""
    fd = -1
    last_err: Exception | None = None
    for _ in range(16):
        candidate = os.path.join(parent, f".{dest_name}.{secrets.token_hex(8)}.tmp")
        try:
            fd = os.open(candidate, flags, 0o600)
            tmp_path = candidate
            break
        except FileExistsError as e:
            last_err = e
            continue
        except OSError as e:
            last_err = e
            continue
    if fd < 0 or not tmp_path:
        sys.exit(1)

    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            raise OSError("not regular")
        view = memoryview(data)
        while len(view):
            n = os.write(fd, view)
            if n <= 0:
                raise OSError("short write")
            view = view[n:]
        os.fsync(fd)
        os.close(fd)
        fd = -1
        os.replace(tmp_path, path)
        tmp_path = ""
    except Exception:
        _close_fd(fd)
        fd = -1
        if tmp_path:
            try:
                os.unlink(tmp_path)
            except Exception:
                pass
        sys.exit(1)
    sys.exit(0)


def main() -> None:
    p = argparse.ArgumentParser(description="Bounded trust-path progress read/write")
    p.add_argument("--file", help="progress file path")
    p.add_argument("--cap", type=int, default=65536, help="max bytes")
    p.add_argument("--write", action="store_true", help="exclusive write mode")
    p.add_argument("--data", help="write payload (else stdin)")
    p.add_argument("--check-path", dest="check_path", help="validate absolute local path and exit")
    args = p.parse_args()

    if args.check_path is not None:
        sys.exit(0 if is_safe_config_path(str(args.check_path)) else 1)

    path = str(args.file or "")
    cap = int(args.cap)
    if args.write:
        if args.data is not None:
            payload = str(args.data).encode("utf-8")
        else:
            try:
                payload = sys.stdin.buffer.read(cap + 1)
            except Exception:
                sys.exit(1)
        write_exclusive(path, payload, cap)
        return
    read_cache(path, cap)


if __name__ == "__main__":
    main()
