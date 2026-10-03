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
KERNEL_FRAGMENT="$SDK_ROOT/buildroot/board/rockchip/rk3506/robotops-kernel.fragment"

if [ ! -x "$SDK_ROOT/build.sh" ] || [ ! -d "$SDK_ROOT/buildroot/board/rockchip/rk3506" ]; then
    echo "Not a Luckfox Lyra SDK tree: $SDK_ROOT" >&2
    exit 1
fi
if [ ! -f "$ROBOTOPS_ROOT/gateway/main.py" ]; then
    echo "Not a robotops-client source tree: $ROBOTOPS_ROOT" >&2
    exit 1
fi

rsync -a --delete "$SCRIPT_DIR/overlay/" "$OVERLAY/"
cp "$SCRIPT_DIR/kernel.fragment" "$KERNEL_FRAGMENT"
mkdir -p "$OVERLAY/opt/robotops/robotops-client" "$OVERLAY/opt/robotops/state"
rsync -a --delete --delete-excluded \
    --include '*/' \
    --include '*.py' \
    --exclude '*' \
    "$ROBOTOPS_ROOT/gateway/" "$OVERLAY/opt/robotops/robotops-client/gateway/"

python3 -m pip install \
    --disable-pip-version-check \
    --no-compile \
    --only-binary=:all: \
    --target "$OVERLAY/opt/robotops/robotops-client/vendor" \
    -r "$SCRIPT_DIR/requirements.txt"

chmod 0755 \
    "$OVERLAY/etc/init.d/S70robotops-cellular" \
    "$OVERLAY/etc/init.d/S99robotops" \
    "$OVERLAY/usr/libexec/robotops-ppp-ip-down" \
    "$OVERLAY/usr/libexec/robotops-ppp-ip-up" \
    "$OVERLAY/usr/sbin/robotops-cellular-manager" \
    "$OVERLAY/usr/sbin/robotops-supervisor"
chmod 0700 "$OVERLAY/etc/robotops"

echo "RobotOps overlay staged at: $OVERLAY"
echo "Add this path to BR2_ROOTFS_OVERLAY: board/rockchip/rk3506/robotops-overlay"
echo "Add this kernel fragment: board/rockchip/rk3506/robotops-kernel.fragment"
echo "Merge buildroot.fragment through ./build.sh buildroot-config, then rebuild rootfs and firmware."
