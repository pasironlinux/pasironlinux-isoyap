#!/bin/bash

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

# iso dizini içine updates dizini oluşturularak ilgili kök dizin altı dizin ve dosyalar konuşlandırılacak.
echo "Sıkıştırma yapılmadan Iso dosyası hazırlanıyor..."
#cp $ROOTFS/usr/lib/syslinux/isohdpfx.bin iso/boot/isolinux/isohdpfx.bin
month="$(date -d "$D" '+%m')"
day="$(date -d "$D" '+%d')"

# updates dizini ile özel ayarların eklenmesi/üstüne yazılması
rm -rf ./iso/updates
cp -rf updates ./iso/

# minimal imajda görsel kurucunun silinmesi
if [ ! -f $ROOTFS/usr/bin/X ];then
	rm -rf iso/updates/opt/pasironlinux-Yukleyici
	rm -rf iso/updates/root/Masaüstü
fi

echo "Pasironlinux-2021-${month}.${day}" > ./iso/updates/etc/pasironlinux-surum

xorriso -as mkisofs \
-iso-level 3 -rock -joliet \
-max-iso9660-filenames -omit-period \
-omit-version-number -relaxed-filenames -allow-lowercase \
-volid "PasironLINUX" \
-eltorito-boot boot/isolinux/isolinux.bin \
-eltorito-catalog boot/isolinux/isolinux.cat \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-eltorito-alt-boot -e efiboot.img -isohybrid-gpt-basdat -no-emul-boot \
-isohybrid-mbr iso/boot/isolinux/isohdpfx.bin \
-output "Pasironlinux-2021-${month}.${day}.iso" iso || echo "ISO imaj olusturalamadı";
