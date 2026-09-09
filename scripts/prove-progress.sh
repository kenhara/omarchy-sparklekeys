#!/bin/sh
# Isolated prove for scripts/progress.py (HC-05 + HANCORE dirfd walk).
# Never touches the real ~/.local/share/sparklekeys — uses a temp HOME.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PY="$ROOT/scripts/progress.py"
INTERP=/usr/bin/python3
export PYTHONDONTWRITEBYTECODE=1
export PATH=/usr/bin:/bin

BASE=$(mktemp -d /tmp/sparklekeys-prove.XXXXXX)
trap 'rm -rf "$BASE"' EXIT INT TERM

# Trusted data-home under temp HOME (matches production layout).
export HOME="$BASE"
unset XDG_DATA_HOME || true
mkdir -p -m 0755 "$HOME/.local/share"
PROGRESS_DIR="$HOME/.local/share/sparklekeys"
PROGRESS="$PROGRESS_DIR/progress.json"

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

empty_file() {
  [ ! -s "$1" ] || fail "$2 (stdout not empty)"
}

# 1. py_compile (then drop the .pyc so the plugin tree stays clean)
"$INTERP" -B -m py_compile "$PY" || fail "py_compile"
rm -rf "$ROOT/scripts/__pycache__"
pass "py_compile"

# 1b. --self-check (dirfd round-trip + symlink parent refuse)
"$INTERP" -B "$PY" --self-check || fail "self-check"
pass "self-check"

# 2. missing file → exit 1, no body
set +e
"$INTERP" -B "$PY" --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "missing rc=$rc (want 1)"
empty_file "$BASE/out" "missing emitted body"
empty_file "$BASE/err" "missing dumped stderr"
pass "missing file → exit 1, no body"

# 3. small regular file → exact bytes (create via helper write)
printf 'hello-bytes' | "$INTERP" -B "$PY" --write --file "$PROGRESS" --cap 65536
set +e
"$INTERP" -B "$PY" --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 0 ] || fail "small rc=$rc"
cmp -s "$PROGRESS" "$BASE/out" || fail "small bytes mismatch"
printf 'hello-bytes' | cmp -s - "$BASE/out" || fail "small content mismatch"
empty_file "$BASE/err" "small dumped stderr"
pass "small regular file → exact bytes"

# 4. oversize → exit 1, no body
dd if=/dev/zero of="$PROGRESS" bs=1024 count=65 status=none
chmod 0600 "$PROGRESS"
set +e
"$INTERP" -B "$PY" --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "oversize rc=$rc (want 1)"
empty_file "$BASE/out" "oversize emitted body"
empty_file "$BASE/err" "oversize dumped stderr"
pass "oversize → exit 1, no body"

# 5. planted symlink at leaf → exit 1, not followed (secret target untouched)
printf 'SECRET-UNTOUCHED' >"$BASE/secret.txt"
rm -f "$PROGRESS"
ln -s "$BASE/secret.txt" "$PROGRESS"
set +e
"$INTERP" -B "$PY" --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "symlink rc=$rc (want 1)"
empty_file "$BASE/out" "symlink emitted body (followed?)"
empty_file "$BASE/err" "symlink dumped stderr"
got=$(cat "$BASE/secret.txt")
[ "$got" = "SECRET-UNTOUCHED" ] || fail "symlink follow mutated secret"
pass "planted symlink → exit 1, secret untouched"

# 5b. planted symlink as sparklekeys dir → walk refuses
rm -f "$PROGRESS"
rm -rf "$PROGRESS_DIR"
mkdir -m 0700 "$BASE/evil-dir"
ln -s "$BASE/evil-dir" "$PROGRESS_DIR"
set +e
printf '{"ok":true}\n' | "$INTERP" -B "$PY" --write --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "dir-symlink write rc=$rc (want 1)"
empty_file "$BASE/out" "dir-symlink write emitted stdout"
empty_file "$BASE/err" "dir-symlink write dumped stderr"
[ ! -e "$BASE/evil-dir/progress.json" ] || fail "dir-symlink redirected write"
rm -f "$PROGRESS_DIR"
pass "planted sparklekeys dir symlink → exit 1"

# 6. FIFO with no writer under timeout 5 → prompt, not hang (not 124)
rm -rf "$PROGRESS_DIR"
mkdir -m 0700 "$PROGRESS_DIR"
mkfifo "$PROGRESS"
set +e
timeout 5 "$INTERP" -B "$PY" --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -ne 124 ] || fail "FIFO hang (timeout 124)"
[ "$rc" -eq 1 ] || fail "FIFO rc=$rc (want 1, not hang)"
empty_file "$BASE/out" "FIFO emitted body"
empty_file "$BASE/err" "FIFO dumped stderr"
pass "FIFO no writer → prompt exit 1 (not 124)"

# 7. dest-symlink write: does not follow (secret untouched; dest becomes regular)
printf 'WRITE-SECRET' >"$BASE/wsecret.txt"
rm -f "$PROGRESS"
ln -s "$BASE/wsecret.txt" "$PROGRESS"
set +e
printf '{"ok":true}\n' | "$INTERP" -B "$PY" --write --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 0 ] || fail "dest-symlink write rc=$rc"
empty_file "$BASE/out" "dest-symlink write emitted stdout"
empty_file "$BASE/err" "dest-symlink write dumped stderr"
got=$(cat "$BASE/wsecret.txt")
[ "$got" = "WRITE-SECRET" ] || fail "dest-symlink followed (secret mutated)"
[ ! -L "$PROGRESS" ] || fail "dest still a symlink"
[ -f "$PROGRESS" ] || fail "dest not a regular file after replace"
pass "dest-symlink write → secret untouched, dest is regular file"

# 8. FIFO dest write returns promptly
rm -f "$PROGRESS"
mkfifo "$PROGRESS"
set +e
printf '{"ok":true}\n' | timeout 5 "$INTERP" -B "$PY" --write --file "$PROGRESS" --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -ne 124 ] || fail "FIFO dest write hang (timeout 124)"
[ "$rc" -eq 0 ] || fail "FIFO dest write rc=$rc"
empty_file "$BASE/out" "FIFO dest write emitted stdout"
empty_file "$BASE/err" "FIFO dest write dumped stderr"
[ ! -p "$PROGRESS" ] || fail "dest still a FIFO"
[ -f "$PROGRESS" ] || fail "FIFO dest not replaced with regular file"
pass "FIFO dest write → prompt, dest is regular file"

# 9. --check-path rejects https, relative, ://, backslash, leading -
check_bad() {
  set +e
  "$INTERP" -B "$PY" --check-path "$1" >"$BASE/out" 2>"$BASE/err"
  rc=$?
  set -e
  [ "$rc" -eq 1 ] || fail "--check-path $1 rc=$rc (want 1)"
  empty_file "$BASE/out" "--check-path $1 emitted body"
}

check_bad "https://example.com/x"
check_bad "progress.json"
check_bad "file://etc/passwd"
check_bad '/tmp/foo\bar'
set +e
"$INTERP" -B "$PY" --check-path=-evil >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "--check-path=-evil rc=$rc (want 1)"
empty_file "$BASE/out" "--check-path=-evil emitted body"
set +e
"$INTERP" -B "$PY" --check-path /tmp/foo.json >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 0 ] || fail "--check-path /tmp/foo.json rc=$rc (want 0)"
pass "--check-path rejects https, relative, ://, backslash, leading -"

# 10. path outside trusted data-home → exit 1
set +e
"$INTERP" -B "$PY" --file /tmp/not-sparklekeys.json --cap 65536 >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "outside path rc=$rc (want 1)"
empty_file "$BASE/out" "outside path emitted body"
pass "path outside data-home → exit 1"

# stdin-only: --data must not be an accepted argv payload
set +e
"$INTERP" -B "$PY" --write --file "$PROGRESS" --cap 65536 --data '{"no":true}' >"$BASE/out" 2>"$BASE/err"
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "--data still accepted on argv"
pass "--data rejected (payload is stdin only)"

# 11. supervised timeout wrapper is present on PATH for QML Process contract
[ -x /usr/bin/timeout ] || fail "/usr/bin/timeout missing"
pass "/usr/bin/timeout available for progressReadProc supervisor"

echo "all proves passed under $BASE (cleaned on exit)"
