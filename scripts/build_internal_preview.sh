#!/bin/bash
#
# Build, verify and package the FSD2 Internal Preview app.
#
# Produces an unsigned, arm64 "Preview"-configuration build of the FSD app that
# carries the FSD_INTERNAL_PREVIEW compile-time flag, then packages it as a
# local ZIP artifact for the operator. Persistent generated outputs stay inside
# the repository .ai-scratch area except for the final artifact on the Desktop.
# The spoofed-XCTest smoke also creates and removes one process-specific alias
# symlink under macOS's temporary root.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/internal_preview_manifest.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 1
fi

manifest_value() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$MANIFEST" "$1"
}

FLAVOR="$(manifest_value flavor)"
TASK_ID="$(manifest_value task)"
SCHEME="$(manifest_value scheme)"
CONFIGURATION="$(manifest_value configuration)"
PRODUCT_NAME="$(manifest_value product_name)"
APP_DISPLAY_NAME="$(manifest_value app_display_name)"
BUNDLE_ID="$(manifest_value bundle_identifier)"
MARKETING_VERSION="$(manifest_value marketing_version)"
CATALOG_DIRECTORY="$(manifest_value catalog_directory)"
FLAVOR_MARKER="$(manifest_value flavor_marker)"
PRODUCTION_FLAVOR_MARKER="$(manifest_value production_flavor_marker)"
ARTIFACT_NAME="$(manifest_value artifact_name)"

WORK_DIR="$REPO_ROOT/.ai-scratch/task065s/package"
BUILD_DIR="$WORK_DIR/derived"
STAGE_DIR="$WORK_DIR/stage"
ZIP_PATH="$WORK_DIR/$ARTIFACT_NAME"
APP_NAME="$PRODUCT_NAME.app"
APP_PATH="$STAGE_DIR/$APP_NAME"
DESKTOP_ARTIFACT="$HOME/Desktop/$ARTIFACT_NAME"

echo "==> $FLAVOR ($TASK_ID)"
echo "    repo:          $REPO_ROOT"
echo "    configuration: $CONFIGURATION"
echo "    product:       $PRODUCT_NAME"

BUILD_VERSION="$(git -C "$REPO_ROOT" rev-parse HEAD)"
DIRTY=""
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  DIRTY="dirty"
fi

echo "==> Cleaning previous packaging output"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

echo "==> Building $CONFIGURATION ($SCHEME)"
xcodebuild \
  -project "$REPO_ROOT/FSD.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  clean build

BUILT_APP="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "error: built app not found at $BUILT_APP" >&2
  exit 1
fi

echo "==> Staging app bundle"
ditto "$BUILT_APP" "$APP_PATH"

echo "==> Verifying bundle identity and required payload"
python3 - "$APP_PATH" "$MANIFEST" <<'PY'
import json, os, plistlib, sys

app = sys.argv[1]
manifest = json.load(open(sys.argv[2]))
info_path = os.path.join(app, "Contents", "Info.plist")
if not os.path.isfile(info_path):
    sys.exit(f"error: missing Info.plist at {info_path}")
with open(info_path, "rb") as handle:
    info = plistlib.load(handle)

expected = {
    "CFBundleIdentifier": manifest["bundle_identifier"],
    "CFBundleName": manifest["product_name"],
    "CFBundleDisplayName": manifest["app_display_name"],
    "CFBundleShortVersionString": manifest["marketing_version"],
    "LSMinimumSystemVersion": manifest["deployment_target"],
}
problems = []
for key, want in expected.items():
    got = info.get(key)
    if str(got) != want:
        problems.append(f"{key}: expected {want!r}, found {got!r}")

for rel in manifest["required_resources"] + manifest["required_helpers"]:
    if not os.path.exists(os.path.join(app, rel)):
        problems.append(f"missing payload: {rel}")

if info.get("NSHumanReadableCopyright") is None:
    pass

if problems:
    for problem in problems:
        print(f"  FAIL {problem}")
    sys.exit("error: bundle verification failed")

print(f"  bundle id:     {info['CFBundleIdentifier']}")
print(f"  bundle name:   {info['CFBundleName']}")
print(f"  display name:  {info['CFBundleDisplayName']}")
print(f"  resources+helpers verified")
PY

echo "==> Verifying compiled preview flavor marker"
APP_BINARY="$APP_PATH/Contents/MacOS/$PRODUCT_NAME"
if ! grep -a -q "$FLAVOR_MARKER" "$APP_BINARY"; then
  echo "error: staged binary lacks the preview flavor marker '$FLAVOR_MARKER'." >&2
  echo "       FSD_INTERNAL_PREVIEW is not compiled in; refusing to package a" >&2
  echo "       bundle that could open the production catalog." >&2
  exit 1
fi
if grep -a -q "$PRODUCTION_FLAVOR_MARKER" "$APP_BINARY"; then
  echo "error: staged binary contains the production flavor marker '$PRODUCTION_FLAVOR_MARKER'." >&2
  exit 1
fi
echo "    marker present: $FLAVOR_MARKER"

for TEST_HOST_ESCAPE in \
  "XCTestConfigurationFilePath" \
  "XCTestBundlePath" \
  "XCTestSessionIdentifier" \
  "FSD-TestHost-"; do
  if grep -a -F -q "$TEST_HOST_ESCAPE" "$APP_BINARY"; then
    echo "error: Preview binary contains Debug XCTest-host escape '$TEST_HOST_ESCAPE'." >&2
    exit 1
  fi
done
echo "    Debug XCTest-host keys and path helper are absent from Preview binary"

echo "==> Bounded isolated launch smoke"
# The smoke runs entirely on a generated synthetic home. CFFIXED_USER_HOME
# makes Foundation resolve Application Support under this throwaway directory,
# so the script never reads, hashes or opens the Owner's real FSD or
# FSD-Internal-Preview catalog. A synthetic production sentinel and a decoy are
# generated to prove mutation invariance and override rejection.
SMOKE_HOME="$WORK_DIR/launch-smoke-home"
rm -rf "$SMOKE_HOME"
SMOKE_APPSUP="$SMOKE_HOME/Library/Application Support"
SMOKE_PROD_DIR="$SMOKE_APPSUP/FSD"
SMOKE_PROD_CATALOG="$SMOKE_PROD_DIR/catalog.sqlite3"
mkdir -p "$SMOKE_PROD_DIR"
printf 'synthetic-production-sentinel-task065r\n' > "$SMOKE_PROD_CATALOG"
EXPECTED_PREVIEW_CATALOG="$SMOKE_APPSUP/FSD-Internal-Preview/catalog.sqlite3"

# A decoy catalog supplied through every runtime override channel that a
# compiled preview must ignore: the removed test-root variable, the documented
# environment variable and a launch argument.
DECOY_ROOT="$WORK_DIR/launch-smoke-decoy"
rm -rf "$DECOY_ROOT"
mkdir -p "$DECOY_ROOT"
DECOY_CATALOG="$DECOY_ROOT/catalog.sqlite3"

SMOKE_LOG="$WORK_DIR/launch-smoke.log"
PROD_BEFORE="$(shasum -a 256 "$SMOKE_PROD_CATALOG" | awk '{print $1}')"
# LLVM_PROFILE_FILE keeps the instrumented app's coverage output inside the
# scratch directory instead of the repository working directory.
CFFIXED_USER_HOME="$SMOKE_HOME" \
LLVM_PROFILE_FILE="$WORK_DIR/launch-smoke-%p.profraw" \
FSD_INTERNAL_PREVIEW_TEST_ROOT="$DECOY_ROOT" \
FSD_CATALOG_PATH="$DECOY_CATALOG" \
  "$APP_BINARY" -FSDCatalogPath "$DECOY_CATALOG" >"$SMOKE_LOG" 2>&1 &
SMOKE_PID=$!
for _ in $(seq 1 20); do
  if grep -a -q "source: internalPreview" "$SMOKE_LOG"; then break; fi
  sleep 0.5
done
kill "$SMOKE_PID" 2>/dev/null || true
wait "$SMOKE_PID" 2>/dev/null || true

if ! grep -a -q "source: internalPreview" "$SMOKE_LOG"; then
  echo "error: launch smoke did not confirm the Internal Preview catalog." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
RESOLVED_CATALOG="$(grep -a '^FSD Internal Preview catalog: ' "$SMOKE_LOG" | head -1 \
  | sed -E 's/^FSD Internal Preview catalog: (.*) \(source: internalPreview\).*/\1/')"
if [[ "$RESOLVED_CATALOG" != "$EXPECTED_PREVIEW_CATALOG" ]]; then
  echo "error: launch smoke resolved the wrong catalog:" >&2
  echo "       expected: $EXPECTED_PREVIEW_CATALOG" >&2
  echo "       resolved: $RESOLVED_CATALOG" >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
# The decoy override channels must have been seen and explicitly ignored, not
# honoured. The diagnostic reports the rejected request.
if ! grep -a -F -q "override request \"$DECOY_CATALOG\" ignored" "$SMOKE_LOG"; then
  echo "error: launch smoke did not report the decoy override as ignored." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
if ! grep -a -q "FSD flavor: $FLAVOR_MARKER" "$SMOKE_LOG"; then
  echo "error: launch smoke did not report the preview flavor marker." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
if grep -a -F -q "$SMOKE_PROD_CATALOG" "$SMOKE_LOG"; then
  echo "error: launch smoke resolved the synthetic production catalog." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
if grep -a -F -q "$HOME/Library/Application Support/FSD" "$SMOKE_LOG"; then
  echo "error: launch smoke resolved the Owner production catalog path." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
SMOKE_LINE="$(grep -a "FSD Internal Preview catalog" "$SMOKE_LOG" | head -1)"
PROD_AFTER="$(shasum -a 256 "$SMOKE_PROD_CATALOG" | awk '{print $1}')"
if [[ "$PROD_BEFORE" != "$PROD_AFTER" ]]; then
  echo "error: synthetic production sentinel changed during launch smoke." >&2
  exit 1
fi
echo "    $SMOKE_LINE"
echo "    synthetic production sentinel unchanged ($PROD_BEFORE)"
rm -rf "$SMOKE_HOME" "$DECOY_ROOT"

echo "==> Spoofed XCTest-host environment and synthetic alias smoke"
# The process-specific test-host location is pre-created as a symlink to a
# generated sentinel. If Preview accepts any spoofed XCTest key, the startup
# diagnostic exposes that alias and opening it can change the sentinel. The
# synthetic home and sentinel live under task scratch; cleanup removes only the
# one process-specific symlink created at macOS's temporary root.
XCTEST_HOME="$WORK_DIR/launch-xctest-home"
XCTEST_APPSUP="$XCTEST_HOME/Library/Application Support"
XCTEST_PROD_DIR="$XCTEST_APPSUP/FSD"
XCTEST_EXPECTED_PREVIEW="$XCTEST_APPSUP/FSD-Internal-Preview/catalog.sqlite3"
DARWIN_TEMP_DIR="$(getconf DARWIN_USER_TEMP_DIR)"
XCTEST_TMP="${DARWIN_TEMP_DIR%/}"
XCTEST_SENTINEL_DIR="$WORK_DIR/launch-xctest-sentinel"
XCTEST_INPUTS="$WORK_DIR/launch-xctest-inputs"
XCTEST_ALIAS_RECORD="$WORK_DIR/launch-xctest-alias-path.txt"
XCTEST_LOG="$WORK_DIR/launch-xctest.log"
XCTEST_DECOY="$WORK_DIR/launch-xctest-decoy/catalog.sqlite3"
rm -rf "$XCTEST_HOME" "$XCTEST_SENTINEL_DIR" "$XCTEST_INPUTS" "$WORK_DIR/launch-xctest-decoy"
rm -f "$XCTEST_ALIAS_RECORD"
mkdir -p "$XCTEST_PROD_DIR" "$XCTEST_SENTINEL_DIR" "$XCTEST_INPUTS" "$(dirname "$XCTEST_DECOY")"
printf 'synthetic-production-sentinel-task065s-xctest\n' > "$XCTEST_PROD_DIR/catalog.sqlite3"
printf 'synthetic-test-host-alias-sentinel-task065s\n' > "$XCTEST_SENTINEL_DIR/catalog.sqlite3"
: > "$XCTEST_INPUTS/FSD.xctestconfiguration"
mkdir -p "$XCTEST_INPUTS/FSDTests.xctest"
printf 'synthetic-xctest-decoy-task065s\n' > "$XCTEST_DECOY"
XCTEST_SENTINEL_BEFORE="$(shasum -a 256 "$XCTEST_SENTINEL_DIR/catalog.sqlite3" | awk '{print $1}')"
XCTEST_PROD_BEFORE="$(shasum -a 256 "$XCTEST_PROD_DIR/catalog.sqlite3" | awk '{print $1}')"

cleanup_xctest_alias() {
  if [[ -s "$XCTEST_ALIAS_RECORD" ]]; then
    local recorded_alias recorded_directory
    recorded_alias="$(cat "$XCTEST_ALIAS_RECORD")"
    recorded_directory="$(dirname "$recorded_alias")"
    if [[ -L "$recorded_directory" ]] && [[ "$(readlink "$recorded_directory")" == "$XCTEST_SENTINEL_DIR" ]]; then
      rm "$recorded_directory"
    fi
  fi
}
trap cleanup_xctest_alias EXIT

CFFIXED_USER_HOME="$XCTEST_HOME" \
TMPDIR="$XCTEST_TMP" \
LLVM_PROFILE_FILE="$WORK_DIR/launch-xctest-%p.profraw" \
XCTestConfigurationFilePath="$XCTEST_INPUTS/FSD.xctestconfiguration" \
XCTestBundlePath="$XCTEST_INPUTS/FSDTests.xctest" \
XCTestSessionIdentifier="synthetic-task065s-session-001" \
FSD_INTERNAL_PREVIEW_TEST_ROOT="$XCTEST_SENTINEL_DIR" \
FSD_CATALOG_PATH="$XCTEST_DECOY" \
FSD_INTERNAL_PREVIEW_SENTINEL_DIR="$XCTEST_SENTINEL_DIR" \
FSD_PREVIEW_TEST_HOST_ALIAS_RECORD="$XCTEST_ALIAS_RECORD" \
FSD_PREVIEW_BINARY="$APP_BINARY" \
  /bin/bash -c '
    test_host_dir="${TMPDIR%/}/FSD-TestHost-$$"
    if [[ -e "$test_host_dir" || -L "$test_host_dir" ]]; then
      echo "error: process-specific test-host path already exists; leaving it untouched." >&2
      exit 78
    fi
    ln -s "$FSD_INTERNAL_PREVIEW_SENTINEL_DIR" "$test_host_dir" || exit 79
    printf "%s\n" "$test_host_dir/catalog.sqlite3" > "$FSD_PREVIEW_TEST_HOST_ALIAS_RECORD"
    exec "$FSD_PREVIEW_BINARY" -FSDCatalogPath "$FSD_CATALOG_PATH"
  ' >"$XCTEST_LOG" 2>&1 &
XCTEST_PID=$!
for _ in $(seq 1 20); do
  if grep -a -Eq "source: (internalPreview|testHost)|FSD startup failed" "$XCTEST_LOG"; then break; fi
  sleep 0.5
done
if ! grep -a -q "source: internalPreview" "$XCTEST_LOG"; then
  kill "$XCTEST_PID" 2>/dev/null || true
  wait "$XCTEST_PID" 2>/dev/null || true
  echo "error: spoofed XCTest environment did not resolve the dedicated Preview catalog." >&2
  cat "$XCTEST_LOG" >&2
  exit 1
fi
sleep 2
kill "$XCTEST_PID" 2>/dev/null || true
wait "$XCTEST_PID" 2>/dev/null || true

XCTEST_HOST_ALIAS="$(cat "$XCTEST_ALIAS_RECORD")"
if [[ "$XCTEST_HOST_ALIAS" != "$XCTEST_TMP"/FSD-TestHost-*/catalog.sqlite3 ]]; then
  echo "error: synthetic test-host alias path was not created where expected: $XCTEST_HOST_ALIAS" >&2
  exit 1
fi
if [[ ! -L "$(dirname "$XCTEST_HOST_ALIAS")" ]] || [[ "$(readlink "$(dirname "$XCTEST_HOST_ALIAS")")" != "$XCTEST_SENTINEL_DIR" ]]; then
  echo "error: generated test-host path is not aliased to the synthetic sentinel." >&2
  exit 1
fi
XCTEST_SMOKE_LINE="$(grep -a '^FSD Internal Preview catalog: ' "$XCTEST_LOG" | head -1)"
if [[ "$XCTEST_SMOKE_LINE" != *"$XCTEST_EXPECTED_PREVIEW"* ]]; then
  echo "error: spoofed XCTest environment resolved the wrong catalog:" >&2
  echo "       expected: $XCTEST_EXPECTED_PREVIEW" >&2
  echo "       resolved: $XCTEST_SMOKE_LINE" >&2
  cat "$XCTEST_LOG" >&2
  exit 1
fi
if grep -a -F -q "$XCTEST_HOST_ALIAS" "$XCTEST_LOG" || grep -a -q "source: testHost" "$XCTEST_LOG"; then
  echo "error: Preview followed the synthetic test-host alias." >&2
  cat "$XCTEST_LOG" >&2
  exit 1
fi
if [[ ! -f "$XCTEST_EXPECTED_PREVIEW" ]]; then
  echo "error: the synthetic dedicated Preview catalog was not opened." >&2
  cat "$XCTEST_LOG" >&2
  exit 1
fi
XCTEST_SENTINEL_AFTER="$(shasum -a 256 "$XCTEST_SENTINEL_DIR/catalog.sqlite3" | awk '{print $1}')"
XCTEST_PROD_AFTER="$(shasum -a 256 "$XCTEST_PROD_DIR/catalog.sqlite3" | awk '{print $1}')"
if [[ "$XCTEST_SENTINEL_BEFORE" != "$XCTEST_SENTINEL_AFTER" ]]; then
  echo "error: synthetic test-host alias sentinel changed during launch smoke." >&2
  exit 1
fi
if [[ "$XCTEST_PROD_BEFORE" != "$XCTEST_PROD_AFTER" ]]; then
  echo "error: synthetic production sentinel changed during launch smoke." >&2
  exit 1
fi
echo "    $XCTEST_SMOKE_LINE"
echo "    synthetic test-host alias: $XCTEST_HOST_ALIAS"
echo "    spoofed XCTest keys ignored; synthetic test-host alias/sentinel unchanged ($XCTEST_SENTINEL_BEFORE)"
rm -rf "$XCTEST_HOME" "$XCTEST_SENTINEL_DIR" "$XCTEST_INPUTS" "$WORK_DIR/launch-xctest-decoy"

echo "==> Bounded symlink fail-closed smoke"
# A filesystem symlink that aliases the preview directory onto the production
# directory must make the shipped preview refuse to start rather than open
# production data. This runs on a generated synthetic home only.
SYMLINK_HOME="$WORK_DIR/launch-symlink-home"
rm -rf "$SYMLINK_HOME"
SYMLINK_APPSUP="$SYMLINK_HOME/Library/Application Support"
SYMLINK_PROD="$SYMLINK_APPSUP/FSD"
mkdir -p "$SYMLINK_PROD"
printf 'synthetic-production-sentinel-task065r\n' > "$SYMLINK_PROD/catalog.sqlite3"
SYMLINK_SENTINEL_BEFORE="$(shasum -a 256 "$SYMLINK_PROD/catalog.sqlite3" | awk '{print $1}')"
ln -s "$SYMLINK_PROD" "$SYMLINK_APPSUP/FSD-Internal-Preview"
SYMLINK_LOG="$WORK_DIR/launch-symlink.log"
CFFIXED_USER_HOME="$SYMLINK_HOME" \
LLVM_PROFILE_FILE="$WORK_DIR/launch-symlink-%p.profraw" \
  "$APP_BINARY" >"$SYMLINK_LOG" 2>&1 &
SYMLINK_PID=$!
for _ in $(seq 1 20); do
  if grep -a -q "FSD startup failed" "$SYMLINK_LOG"; then break; fi
  sleep 0.5
done
kill "$SYMLINK_PID" 2>/dev/null || true
wait "$SYMLINK_PID" 2>/dev/null || true
if grep -a -q "source: internalPreview" "$SYMLINK_LOG"; then
  echo "error: symlinked preview still resolved a catalog instead of failing closed." >&2
  cat "$SYMLINK_LOG" >&2
  exit 1
fi
if ! grep -a -q "resolves onto the production FSD catalog" "$SYMLINK_LOG"; then
  echo "error: symlinked preview did not fail closed with the production-conflict error." >&2
  cat "$SYMLINK_LOG" >&2
  exit 1
fi
SYMLINK_SENTINEL_AFTER="$(shasum -a 256 "$SYMLINK_PROD/catalog.sqlite3" | awk '{print $1}')"
if [[ "$SYMLINK_SENTINEL_BEFORE" != "$SYMLINK_SENTINEL_AFTER" ]]; then
  echo "error: synthetic production sentinel changed during symlink fail-closed smoke." >&2
  exit 1
fi
echo "    symlinked preview refused to start (fail closed)"
echo "    synthetic symlink target sentinel unchanged ($SYMLINK_SENTINEL_BEFORE)"
rm -rf "$SYMLINK_HOME"

echo "==> Computing bundle tree digest"
BUNDLE_TREE_SHA="$(
  cd "$STAGE_DIR" && \
  find "$APP_NAME" -type f -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 shasum -a 256 \
    | shasum -a 256 \
    | awk '{print $1}'
)"
echo "    bundle tree sha256: $BUNDLE_TREE_SHA"

echo "==> Creating ZIP artifact"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

ZIP_SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
ZIP_SIZE="$(stat -f '%z' "$ZIP_PATH")"

echo "==> Writing build receipt"
python3 - "$WORK_DIR" "$MANIFEST" "$BUILD_VERSION" "$DIRTY" "$BUNDLE_TREE_SHA" "$ZIP_SHA" "$ZIP_SIZE" "$ZIP_PATH" "$SMOKE_LINE" "$PROD_BEFORE" "$XCTEST_SMOKE_LINE" "$XCTEST_SENTINEL_BEFORE" "$XCTEST_HOST_ALIAS" "$SYMLINK_SENTINEL_BEFORE" <<'PY'
import datetime, json, os, sys

(work_dir, manifest_path, version, dirty, tree_sha, zip_sha, zip_size,
 zip_path, smoke_line, sentinel_sha, xctest_smoke_line, xctest_alias_sentinel_sha,
 xctest_alias_path, symlink_target_sentinel_sha) = sys.argv[1:]
manifest = json.load(open(manifest_path))
receipt = {
    "flavor": manifest["flavor"],
    "task": manifest["task"],
    "repair_task": manifest["repair_task"],
    "source_commit": version,
    "worktree_state": dirty or "clean",
    "configuration": manifest["configuration"],
    "scheme": manifest["scheme"],
    "product_name": manifest["product_name"],
    "bundle_identifier": manifest["bundle_identifier"],
    "architectures": manifest["architectures"],
    "swift_flag": manifest["swift_flag"],
    "flavor_marker": manifest["flavor_marker"],
    "catalog_directory": manifest["catalog_directory"],
    "catalog_file": manifest["catalog_file"],
    "artifact": os.path.basename(zip_path),
    "artifact_sha256": zip_sha,
    "artifact_bytes": int(zip_size),
    "bundle_tree_sha256": tree_sha,
    "launch_smoke_line": smoke_line,
    "launch_smoke_home": "CFFIXED_USER_HOME;generated_synthetic_only",
    "synthetic_production_sentinel_sha256": sentinel_sha,
    "xctest_spoof_smoke_line": xctest_smoke_line,
    "xctest_spoof_keys": ["XCTestConfigurationFilePath", "XCTestBundlePath", "XCTestSessionIdentifier"],
    "synthetic_test_host_alias_path": xctest_alias_path,
    "synthetic_test_host_alias_sentinel_sha256": xctest_alias_sentinel_sha,
    "synthetic_symlink_target_sentinel_sha256": symlink_target_sentinel_sha,
    "owner_catalog_accessed": False,
    "built_at_utc": datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0).isoformat(),
}
receipt_path = os.path.join(work_dir, "build-receipt.json")
with open(receipt_path, "w") as handle:
    json.dump(receipt, handle, indent=2)
    handle.write("\n")
print(f"  receipt: {receipt_path}")
PY

if [[ "${FSD_PREVIEW_STAGE_DESKTOP:-1}" == "0" ]]; then
  echo "==> Skipping Desktop staging (FSD_PREVIEW_STAGE_DESKTOP=0)"
  DESKTOP_ARTIFACT="$ZIP_PATH"
else
  echo "==> Staging artifact on Desktop"
  mkdir -p "$(dirname "$DESKTOP_ARTIFACT")"
  cp "$ZIP_PATH" "$DESKTOP_ARTIFACT"
  DESKTOP_SHA="$(shasum -a 256 "$DESKTOP_ARTIFACT" | awk '{print $1}')"
  if [[ "$DESKTOP_SHA" != "$ZIP_SHA" ]]; then
    echo "error: desktop copy hash mismatch" >&2
    exit 1
  fi
fi

cat <<EOF

================================================================
FSD2 Internal Preview packaged successfully.
================================================================
  artifact:  $DESKTOP_ARTIFACT
  sha256:    $ZIP_SHA
  bytes:     $ZIP_SIZE
  bundle:    $BUNDLE_TREE_SHA
  commit:    $BUILD_VERSION ($DIRTY)
  receipt:   $WORK_DIR/build-receipt.json

Launch:
  unzip -o "$DESKTOP_ARTIFACT" -d "\$HOME/Desktop/FSD2-Internal-Preview"
  open "\$HOME/Desktop/FSD2-Internal-Preview/$APP_NAME"

The Preview app uses an isolated catalog at:
  ~/Library/Application Support/$CATALOG_DIRECTORY/catalog.sqlite3
It never reads or writes the production FSD catalog.
EOF
