#!/bin/bash
# temel sistemin olduğu dizin

if [ -z $ROOTFS ];then
	ROOTFS="/home/mlfs/onsistem"
fi

if [ ! -z $1 ];then
	ROOTFS="$1"
fi

if [ ! -d $ROOTFS ];then
	echo "$ROOTFS dizini mevcut değil!"
	exit 1
fi

hata_olustu(){
	echo "$1"
	exit 1
}

#[ ! -f $ROOTFS/boot/kernel ] && hata_olustu "$ROOTFS/boot/kernel bulunamadı"
[ ! -f $ROOTFS/boot/initrd_live ] && hata_olustu "$ROOTFS/boot/initrd_live bulunamadı"

# temizlik
if [ -d iso ];then
	rm -fv iso/boot/cekirdek*
	rm -fv iso/boot/initrd*
	rm -fv iso/efiboot.img
	rm -rfv iso/LiveOS
	rm -rvf $ROOTFS/var/cache/mps/depo/*.kur
fi

echo "Güncel kernel ve initramfs kopyalanıyor..."
kversion=`ls $ROOTFS/boot/kernel-* | xargs -I {} basename {} | head -n1 |cut -d'-' -f2`
cp -rvf $ROOTFS/boot/kernel-${kversion} iso/boot/cekirdek
#cp -rvf $ROOTFS/boot/initrd_live iso/boot/initrd-${kversion}
cp -rvf $ROOTFS/boot/initrd_live iso/boot/initrd

# LiveOS ayarları
echo "LiveOS ayarları yapılıyor..."
# varsa temp-root/ ve tmp/ umount edil silelim
if [ -d temp-root ]; then
	mountpoint -q temp-root && umount -l temp-root
	rm -rf temp-root
fi
[[ -d tmp ]] && rm -rf tmp

#
mkdir -p tmp/LiveOS
fallocate -l 8G tmp/LiveOS/rootfs.img
mke2fs -t ext4 -L PASIRONLINUX_CALISAN -F tmp/LiveOS/rootfs.img
mkdir -p temp-root
mount -o loop tmp/LiveOS/rootfs.img temp-root
echo "Chroot içerik dosya sistemi imajına kopyalanıyor..."
cp -dpR $ROOTFS/* temp-root/
umount -l temp-root && rm -rf temp-root 
mkdir -p iso/LiveOS
echo "Dosya sistemi imajı sıkıştırılıyor..."
mksquashfs tmp iso/LiveOS/squashfs.img -comp xz -b 256K -Xbcj x86
chmod 444 iso/LiveOS/squashfs.img
rm -rf tmp

echo "Efi ayarları yapılıyor..."
mkdir -p iso/efi_tmp
dd if=/dev/zero bs=2M count=64 of=./iso/efiboot.img
mkfs.vfat -n PASIRONINUX_EFI ./iso/efiboot.img 

mount -o loop ./iso/efiboot.img ./iso/efi_tmp
cp -rf ./iso/boot/cekirdek ./iso/efi_tmp/
cp -rf ./iso/boot/initrd ./iso/efi_tmp/
cp -rf ./efi/* ./iso/efi_tmp/

umount ./iso/efi_tmp 
rm -rf ./iso/efi_tmp

month="$(date -d "$D" '+%m')"
day="$(date -d "$D" '+%d')"

# updates dizini ile özel ayarların eklenmesi/üstüne yazılması
rm -rf ./iso/updates
cp -rf updates ./iso/

# minimal imajda görsel kurucunun silinmesi
if [ ! -f $ROOTFS/usr/bin/X ];then
	rm -rf iso/updates/opt/Pasironlinux-Yukleyici
	rm -rf iso/updates/root/Masaüstü
fi
chmod +x iso/updates/root/Masaüstü/kurulum.desktop
chmod +x iso/updates/root/kurulum.desktop
#echo "pasironlinux-2021-${month}.${day}" > ./iso/updates/etc/pasironlinux-surum
echo "Iso dosyası hazırlanıyor..."
#cp $ROOTFS/usr/lib/syslinux/isohdpfx.bin iso/boot/isolinux/isohdpfx.bin
xorriso -as mkisofs \
-iso-level 3 -rock -joliet \
-max-iso9660-filenames -omit-period \
-omit-version-number -relaxed-filenames -allow-lowercase \
-volid "Pasiron_LINUX" \
-eltorito-boot boot/isolinux/isolinux.bin \
-eltorito-catalog boot/isolinux/isolinux.cat \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-eltorito-alt-boot -e efiboot.img -isohybrid-gpt-basdat -no-emul-boot \
-isohybrid-mbr iso/boot/isolinux/isohdpfx.bin \
-output "Pasironlinux-2021-${month}.${day}.iso" iso || echo "ISO imaj olusturalamadı";
