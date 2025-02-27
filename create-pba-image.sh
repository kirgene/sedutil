#!/bin/bash

set -euo pipefail functrace

if [ "$(whoami)" != "root" ]; then
        echo "Sorry, you are not root."
        exit 1
fi

which kpartx > /dev/null

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

dd if=/dev/zero of=pba.disk bs=1M count=36 status=none
sfdisk pba.disk -q -X gpt <<< ",,U"

kpartx -a pba.disk
PBA=/dev/mapper/$(kpartx -l pba.disk | cut -f1 -d ' ')
mkfs.vfat ${PBA}
PBA_DIR=$(mktemp -d)
mount ${PBA} $PBA_DIR

KERNEL="/boot/$(readlink /boot/vmlinuz)"
cp initramfs.cpio.gz $PBA_DIR
cp $KERNEL $PBA_DIR

sudo grub-install --efi-directory=$PBA_DIR
cat > $(find $PBA_DIR -name grub.cfg) <<EOF
set timeout=0
set default=0
menuentry "TCG Opal pre-boot authentication" {
    linux /$(basename $KERNEL) loglevel=0 libata.allow_tpm=1
    initrd /initramfs.cpio.gz
}
EOF

umount $PBA_DIR
rm -rf $PBA_DIR

kpartx -d pba.disk
