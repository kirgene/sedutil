#!/bin/sh

INITRAMFS_DIR=$(mktemp -d)
mkdir $INITRAMFS_DIR/bin
cp $(which busybox) $INITRAMFS_DIR/bin
busybox --install -s $INITRAMFS_DIR/bin
cat > $INITRAMFS_DIR/init <<EOF
#!/bin/sh

mkdir -p /proc /sys /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs none /dev

# Load kernel modules
for m in \$(cat /lib/modules.list); do insmod /lib/modules/\$m; done

/bin/linuxpba
EOF
chmod +x $INITRAMFS_DIR/init

# Get deps
cp linuxpba $INITRAMFS_DIR/bin/
strip -s $INITRAMFS_DIR/bin/linuxpba
# Copy dependencies
for library in $(ldd "linuxpba" | cut -d '>' -f 2 | awk '{print $1}'| grep "^/.*\.so")
do
	if [ -f "${library}" ]; then
		cp -n --parents "${library}" $INITRAMFS_DIR
	fi
done

# Copy necessary kernel modules
MODULES="\
drivers/ata/libahci.ko \
drivers/ata/ahci.ko \
"
KERNEL_VERSION=$(ls /lib/modules | sort -r | head -1)
mkdir -p $INITRAMFS_DIR/lib/modules
for m in $MODULES; do
	dst=$INITRAMFS_DIR/lib/modules/$(dirname $m)
	mkdir -p $dst
	cp /lib/modules/$KERNEL_VERSION/kernel/$m $dst
done
echo "$MODULES" > $INITRAMFS_DIR/lib/modules.list

# Create cpio archive
(cd $INITRAMFS_DIR && find | cpio -H newc --quiet -o) | gzip > initramfs.cpio.gz

rm -rf $INITRAMFS_DIR
