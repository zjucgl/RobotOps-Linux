# RobotOps Linux for Luckfox Lyra Plus

This profile targets the RK3506G Luckfox Lyra Plus with 128 MB DDR3 and
256 MB SPI NAND. It keeps the vendor bootloader, kernel, device tree, and
partition table unchanged for the first bring-up.

## Build Host

Use Ubuntu 22.04 x86_64 and keep the SDK on a Linux filesystem. Select the
Lyra Plus SPI NAND target:

```sh
./build.sh lunch
# RK3506G_Luckfox_Lyra_Plus
# luckfox_lyra_plus_buildroot_spinand_defconfig
```

Build the unmodified vendor image once before applying this profile.

## Stage RobotOps

Keep the Lyra SDK, this repository, and `robotops-client` as separate source
trees. From this repository, run:

```sh
sh install-into-sdk.sh \
    /path/to/luckfox-lyra-sdk \
    /path/to/robotops-client
```

Then open the Buildroot configuration:

```sh
cd /path/to/luckfox-lyra-sdk
./build.sh buildroot-config
```

Enable the symbols listed in `buildroot.fragment`. Set the root filesystem
overlay to:

```text
board/rockchip/rk3506/robotops-overlay
```

Build and package:

```sh
./build.sh rootfs
./build.sh firmware
```

The resulting complete image is normally `rockdev/update.img`.

## Provisioning

The image intentionally contains no gateway identity or private key. After
the first boot, provision these files over SSH or ADB:

```text
/etc/robotops/gateway.json
/etc/robotops/certs/ca-chain.pem
/etc/robotops/certs/cert.pem
/etc/robotops/certs/key.pem
```

Start the service after provisioning:

```sh
/etc/init.d/S99robotops restart
tail -f /var/log/robotops-client.log
```

The supervisor waits for a post-2024 system clock before starting RobotOps,
uses an 8 MiB queue limit, and restarts the process after failures. The first
image should be tested from a recoverable Loader/MaskRom setup before any
kernel, device-tree, or partition-table trimming.

## Wired DHCP

The Lyra Plus vendor image starts `udhcpc -i eth0` from `S60netdevice`. The
RobotOps supervisor keeps that behavior and adds a fallback DHCP client only
when no existing `udhcpc` process owns `eth0`. RobotOps does not start until
`eth0` has an IPv4 address and a default route. The USB management interface
remains independent at `192.168.123.100/24`.

Verify the first boot with:

```sh
ip -4 addr show dev eth0
ip route show default
cat /etc/resolv.conf
ps w | grep '[u]dhcpc'
ping -c 1 192.168.3.1
```
