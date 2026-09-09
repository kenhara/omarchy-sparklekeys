#!/usr/bin/env python3
"""Bounded progress.json read/write for Sparklekeys (HC-05 + HANCORE dirfd).

Trust path: walk from $HOME with retained O_DIRECTORY|O_NOFOLLOW dirfds through
XDG data-home (XDG_DATA_HOME if under $HOME, else ~/.local/share), then
sparklekeys/. Read/write open the leaf relative to that retained directory
descriptor. Owner + no group/other-write on every walked component; sparklekeys
and the progress file are tightened toward 0700/0600.

Read: openat(leaf) O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC, regular
user-owned private file only, cap+1. Missing / symlink / FIFO / oversize /
failed walk → exit 1, no body.

Write (--write): payload on stdin only (never argv). mkdirat sparklekeys 0700
as needed; exclusive tmp openat(O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW, 0o600) →
write → fsync → renameat relative to leaf dirfd → fsync(leaf dirfd) fail-closed.

--file must equal the expected data-home/sparklekeys/progress.json path and
pass is_safe_config_path. Fail closed: exit 1, no body.

--check-path: unit-test path sanitizer (absolute local path only).
--self-check: small isolated dirfd contract checks under a temp HOME.
"""
from __future__ import annotations

import argparse
import os
import secrets
import stat
import sys
import tempfile


PROGRESS_DIR = "sparklekeys"
PROGRESS_NAME = "progress.json"
# No group/other write on walked trust-boundary dirs/files.
_NO_GROUP_OTHER_WRITE = 0o022
# Plugin leaf dir / file: no group/other access bits.
_PRIVATE_BITS = 0o077


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


def _die() -> None:
    sys.exit(1)


def _norm_abs(path: str) -> str:
    # Collapse // and . without resolving symlinks (no realpath).
    return os.path.normpath(str(path or ""))


def expected_progress_path() -> str:
    home = os.environ.get("HOME") or ""
    if not is_safe_config_path(home):
        _die()
    xdg = os.environ.get("XDG_DATA_HOME") or ""
    if xdg:
        if not is_safe_config_path(xdg):
            _die()
        home_n = _norm_abs(home)
        xdg_n = _norm_abs(xdg)
        if xdg_n != home_n and not xdg_n.startswith(home_n + "/"):
            _die()
        data_home = xdg_n
    else:
        data_home = _norm_abs(home + "/.local/share")
    return _norm_abs(data_home + "/" + PROGRESS_DIR + "/" + PROGRESS_NAME)


def _dir_flags() -> int:
    return with_cloexec(
        require_flags("O_RDONLY", "O_DIRECTORY", "O_NOFOLLOW", "O_NONBLOCK")
    )


def _validate_dir_st(st: os.stat_result, *, private: bool) -> None:
    if not stat.S_ISDIR(st.st_mode):
        _die()
    if st.st_uid != os.getuid():
        _die()
    mask = _PRIVATE_BITS if private else _NO_GROUP_OTHER_WRITE
    if (st.st_mode & mask) != 0:
        _die()


def _validate_file_st(st: os.stat_result) -> None:
    if not stat.S_ISREG(st.st_mode):
        _die()
    if st.st_uid != os.getuid():
        _die()
    # Allow 0644 historically; refuse group/other write.
    if (st.st_mode & _NO_GROUP_OTHER_WRITE) != 0:
        _die()


def _open_dirat(parent_fd: int, name: str, *, create: bool, private: bool) -> int:
    if not name or name in (".", "..") or "/" in name or "\\" in name:
        _die()
    flags = _dir_flags()
    fd = -1
    try:
        try:
            fd = os.open(name, flags, dir_fd=parent_fd)
        except FileNotFoundError:
            if not create:
                raise
            try:
                os.mkdir(name, 0o700, dir_fd=parent_fd)
            except FileExistsError:
                pass
            fd = os.open(name, flags, dir_fd=parent_fd)
        st = os.fstat(fd)
        if create and private:
            # Tighten via dirfd (never chmod a pathname).
            if (st.st_mode & 0o777) != 0o700:
                os.fchmod(fd, 0o700)
                st = os.fstat(fd)
        _validate_dir_st(st, private=private)
        return fd
    except Exception:
        _close_fd(fd)
        raise


def _data_home_rel_parts() -> list[str]:
    home = os.environ.get("HOME") or ""
    if not is_safe_config_path(home):
        _die()
    xdg = os.environ.get("XDG_DATA_HOME") or ""
    home_n = _norm_abs(home)
    if xdg:
        if not is_safe_config_path(xdg):
            _die()
        xdg_n = _norm_abs(xdg)
        if xdg_n != home_n and not xdg_n.startswith(home_n + "/"):
            _die()
        if xdg_n == home_n:
            rel: list[str] = []
        else:
            rel = xdg_n[len(home_n) + 1 :].split("/")
    else:
        rel = [".local", "share"]
    out = [p for p in rel if p and p != "."]
    if any(p == ".." or "/" in p or "\\" in p for p in out):
        _die()
    return out


def open_progress_dir(*, create: bool) -> int:
    """Walk HOME → data-home → sparklekeys with retained O_NOFOLLOW dirfds."""
    home = os.environ.get("HOME") or ""
    if not is_safe_config_path(home):
        _die()
    home_n = _norm_abs(home)
    flags = _dir_flags()
    cur = -1
    try:
        # Final-component O_NOFOLLOW on HOME; fstat binds owner/mode.
        cur = os.open(home_n, flags)
        _validate_dir_st(os.fstat(cur), private=False)
        for part in _data_home_rel_parts():
            nxt = _open_dirat(cur, part, create=create, private=False)
            os.close(cur)
            cur = nxt
        leaf = _open_dirat(cur, PROGRESS_DIR, create=create, private=True)
        os.close(cur)
        cur = -1
        return leaf
    except Exception:
        _close_fd(cur)
        _die()
        raise  # pragma: no cover


def _require_expected_file(path: str) -> None:
    if not is_safe_config_path(path):
        _die()
    if _norm_abs(path) != expected_progress_path():
        _die()


def read_cache(path: str, cap: int) -> None:
    if cap < 0:
        _die()
    _require_expected_file(path)

    leaf_fd = -1
    fd = -1
    data = b""
    try:
        leaf_fd = open_progress_dir(create=False)
        flags = with_cloexec(require_flags("O_RDONLY", "O_NOFOLLOW", "O_NONBLOCK"))
        fd = os.open(PROGRESS_NAME, flags, dir_fd=leaf_fd)
        st = os.fstat(fd)
        _validate_file_st(st)
        remaining = cap + 1
        while remaining > 0:
            chunk = os.read(fd, min(65536, remaining))
            if not chunk:
                break
            data += chunk
            remaining -= len(chunk)
    except Exception:
        _close_fd(fd)
        _close_fd(leaf_fd)
        _die()
    finally:
        _close_fd(fd)
        _close_fd(leaf_fd)

    if len(data) > cap:
        _die()
    try:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
    except Exception:
        _die()
    sys.exit(0)


def write_exclusive(path: str, data: bytes, cap: int) -> None:
    if cap < 0:
        _die()
    _require_expected_file(path)
    if not data or len(data) > cap:
        _die()

    flags = with_cloexec(require_flags("O_WRONLY", "O_CREAT", "O_EXCL", "O_NOFOLLOW"))
    if hasattr(os, "O_NONBLOCK"):
        flags |= int(os.O_NONBLOCK)

    leaf_fd = -1
    fd = -1
    tmp_name = ""
    try:
        leaf_fd = open_progress_dir(create=True)
        for _ in range(16):
            candidate = f".{PROGRESS_NAME}.{secrets.token_hex(8)}.tmp"
            try:
                fd = os.open(candidate, flags, 0o600, dir_fd=leaf_fd)
                tmp_name = candidate
                break
            except FileExistsError:
                continue
            except OSError:
                continue
        if fd < 0 or not tmp_name:
            _die()

        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            raise OSError("not regular")
        if st.st_uid != os.getuid():
            raise OSError("bad owner")
        view = memoryview(data)
        while len(view):
            n = os.write(fd, view)
            if n <= 0:
                raise OSError("short write")
            view = view[n:]
        os.fsync(fd)
        os.close(fd)
        fd = -1
        os.rename(tmp_name, PROGRESS_NAME, src_dir_fd=leaf_fd, dst_dir_fd=leaf_fd)
        tmp_name = ""
        # Fail closed if the directory cannot commit the rename.
        try:
            os.fsync(leaf_fd)
        except Exception:
            raise OSError("dir fsync failed")
    except Exception:
        _close_fd(fd)
        fd = -1
        if tmp_name and leaf_fd >= 0:
            try:
                os.unlink(tmp_name, dir_fd=leaf_fd)
            except Exception:
                pass
        _close_fd(leaf_fd)
        _die()
    _close_fd(leaf_fd)
    sys.exit(0)


def _self_check_main() -> None:
    import shutil
    import subprocess

    base = tempfile.mkdtemp(prefix="sparklekeys-selfcheck.")
    py = os.path.abspath(__file__)
    interp = "/usr/bin/python3"
    env = {
        "HOME": base,
        "PATH": "/usr/bin:/bin",
        "PYTHONDONTWRITEBYTECODE": "1",
    }
    try:
        os.mkdir(os.path.join(base, ".local"), 0o755)
        os.mkdir(os.path.join(base, ".local", "share"), 0o755)
        path = os.path.join(base, ".local", "share", PROGRESS_DIR, PROGRESS_NAME)
        payload = b'{"schemaVersion":4,"stars":1}\n'

        p = subprocess.run(
            [interp, "-B", py, "--write", "--file", path, "--cap", "65536"],
            input=payload,
            capture_output=True,
            env=env,
            timeout=10,
        )
        if p.returncode != 0 or p.stdout or p.stderr:
            sys.stderr.write("self-check: write failed\n")
            sys.exit(1)

        p = subprocess.run(
            [interp, "-B", py, "--file", path, "--cap", "65536"],
            capture_output=True,
            env=env,
            timeout=10,
        )
        if p.returncode != 0 or p.stdout != payload or p.stderr:
            sys.stderr.write("self-check: read mismatch\n")
            sys.exit(1)

        # Replace sparklekeys dir with a symlink → walk must fail closed.
        sk = os.path.join(base, ".local", "share", PROGRESS_DIR)
        evil = os.path.join(base, "evil-target")
        os.mkdir(evil, 0o700)
        os.rename(sk, os.path.join(evil, "moved"))
        os.symlink(evil, sk)
        p = subprocess.run(
            [interp, "-B", py, "--file", path, "--cap", "65536"],
            capture_output=True,
            env=env,
            timeout=10,
        )
        if p.returncode != 1 or p.stdout or p.stderr:
            sys.stderr.write("self-check: symlink parent not refused\n")
            sys.exit(1)

        p = subprocess.run(
            [interp, "-B", py, "--check-path", "/tmp/foo.json"],
            capture_output=True,
            env=env,
            timeout=10,
        )
        if p.returncode != 0:
            sys.stderr.write("self-check: --check-path absolute failed\n")
            sys.exit(1)
        p = subprocess.run(
            [interp, "-B", py, "--check-path", "https://example.com/x"],
            capture_output=True,
            env=env,
            timeout=10,
        )
        if p.returncode != 1:
            sys.stderr.write("self-check: --check-path https not refused\n")
            sys.exit(1)

        sys.stdout.write("self-check ok\n")
        sys.exit(0)
    finally:
        shutil.rmtree(base, ignore_errors=True)


def main() -> None:
    p = argparse.ArgumentParser(description="Bounded trust-path progress read/write")
    p.add_argument("--file", help="progress file path")
    p.add_argument("--cap", type=int, default=65536, help="max bytes")
    p.add_argument("--write", action="store_true", help="exclusive write mode (payload on stdin)")
    p.add_argument("--check-path", dest="check_path", help="validate absolute local path and exit")
    p.add_argument("--self-check", action="store_true", help="run isolated dirfd contract checks")
    args = p.parse_args()

    if args.self_check:
        _self_check_main()
        return

    if args.check_path is not None:
        sys.exit(0 if is_safe_config_path(str(args.check_path)) else 1)

    path = str(args.file or "")
    cap = int(args.cap)
    if not is_safe_config_path(path):
        sys.exit(1)
    if args.write:
        try:
            payload = sys.stdin.buffer.read(cap + 1)
        except Exception:
            sys.exit(1)
        write_exclusive(path, payload, cap)
        return
    read_cache(path, cap)


if __name__ == "__main__":
    main()
