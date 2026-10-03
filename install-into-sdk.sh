#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 /path/to/luckfox-lyra-sdk /path/to/robotops-client" >&2
    exit 2
fi

SDK_ROOT=$(cd "$1" && pwd)
ROBOTOPS_ROOT=$(cd "$2" && pwd)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OVERLAY="$SDK_ROOT/buildroot/board/rockchip/rk3506/robotops-overlay"

if [ ! -x "$SDK_ROOT/build.sh" ] || [ ! -d "$SDK_ROOT/buildroot/board/rockchip/rk3506" ]; then
    echo "Not a Luckfox Lyra SDK tree: $SDK_ROOT" >&2
    exit 1
fi
if [ ! -f "$ROBOTOPS_ROOT/gateway/main.py" ]; then
    echo "Not a robotops-client source tree: $ROBOTOPS_ROOT" >&2
    exit 1
fi

mkdir -p "$OVERLAY/opt/robotops/robotops-client" "$OVERLAY/opt/robotops/state"
rsync -a --delete "$SCRIPT_DIR/overlay/" "$OVERLAY/"
rsync -a --delete \
    --exclude '__pycache__/' \
    --exclude '*.pyc' \
    --exclude '*.pem' \
    --exclude '*.key' \
    --exclude '*.zip' \
    "$ROBOTOPS_ROOT/gateway/" "$OVERLAY/opt/robotops/robotops-client/gateway/"

python3 -m pip install \
    --disable-pip-version-check \
    --no-compile \
    --only-binary=:all: \
    --target "$OVERLAY/opt/robotops/robotops-client/vendor" \
    -r "$SCRIPT_DIR/requirements.txt"

chmod 0755 "$OVERLAY/etc/init.d/S99robotops" "$OVERLAY/usr/sbin/robotops-supervisor"
chmod 0700 "$OVERLAY/etc/robotops"

echo "RobotOps overlay staged at: $OVERLAY"
echo "Add this path to BR2_ROOTFS_OVERLAY: board/rockchip/rk3506/robotops-overlay"
echo "Merge buildroot.fragment through ./build.sh buildroot-config, then rebuild rootfs and firmware."
