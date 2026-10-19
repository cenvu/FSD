#!/bin/bash
#
# Build, verify and package the FSD2 Internal Preview app.
#
# Produces an unsigned, arm64 "Preview"-configuration build of the FSD app that
# carries the FSD_INTERNAL_PREVIEW compile-time flag, then packages it as a
# local ZIP artifact for the operator. All writes stay inside the repository
# .ai-scratch area except for the final artifact staged on the Desktop.
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

WORK_DIR="$REPO_ROOT/.ai-scratch/task065/package"
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

echo "==> Bounded isolated launch smoke"
SMOKE_ROOT="$WORK_DIR/launch-smoke-root"
rm -rf "$SMOKE_ROOT"
mkdir -p "$SMOKE_ROOT"
SMOKE_LOG="$WORK_DIR/launch-smoke.log"
PROD_CATALOG="$HOME/Library/Application Support/FSD/catalog.sqlite3"
PROD_BEFORE="$( [[ -f "$PROD_CATALOG" ]] && shasum -a 256 "$PROD_CATALOG" | awk '{print $1}' || echo "absent" )"
FSD_INTERNAL_PREVIEW_TEST_ROOT="$SMOKE_ROOT" "$APP_BINARY" >"$SMOKE_LOG" 2>&1 &
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
if ! grep -a -F -q "$SMOKE_ROOT" "$SMOKE_LOG"; then
  echo "error: launch smoke did not honour the isolated test root." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
if grep -a -q "/Application Support/FSD/" "$SMOKE_LOG"; then
  echo "error: launch smoke resolved a production catalog path." >&2
  cat "$SMOKE_LOG" >&2
  exit 1
fi
SMOKE_LINE="$(grep -a "FSD Internal Preview catalog" "$SMOKE_LOG" | head -1)"
PROD_AFTER="$( [[ -f "$PROD_CATALOG" ]] && shasum -a 256 "$PROD_CATALOG" | awk '{print $1}' || echo "absent" )"
if [[ "$PROD_BEFORE" != "$PROD_AFTER" ]]; then
  echo "error: production catalog changed during launch smoke." >&2
  exit 1
fi
echo "    $SMOKE_LINE"
echo "    production catalog unchanged ($PROD_BEFORE)"
rm -rf "$SMOKE_ROOT"

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
python3 - "$WORK_DIR" "$MANIFEST" "$BUILD_VERSION" "$DIRTY" "$BUNDLE_TREE_SHA" "$ZIP_SHA" "$ZIP_SIZE" "$ZIP_PATH" "$SMOKE_LINE" "$PROD_BEFORE" <<'PY'
import datetime, json, os, sys

(work_dir, manifest_path, version, dirty, tree_sha, zip_sha, zip_size,
 zip_path, smoke_line, prod_hash) = sys.argv[1:]
manifest = json.load(open(manifest_path))
receipt = {
    "flavor": manifest["flavor"],
    "task": manifest["task"],
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
    "production_catalog_sha256_after_smoke": prod_hash,
    "built_at_utc": datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0).isoformat(),
}
receipt_path = os.path.join(work_dir, "build-receipt.json")
with open(receipt_path, "w") as handle:
    json.dump(receipt, handle, indent=2)
    handle.write("\n")
print(f"  receipt: {receipt_path}")
PY

echo "==> Staging artifact on Desktop"
mkdir -p "$(dirname "$DESKTOP_ARTIFACT")"
cp "$ZIP_PATH" "$DESKTOP_ARTIFACT"
DESKTOP_SHA="$(shasum -a 256 "$DESKTOP_ARTIFACT" | awk '{print $1}')"
if [[ "$DESKTOP_SHA" != "$ZIP_SHA" ]]; then
  echo "error: desktop copy hash mismatch" >&2
  exit 1
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
