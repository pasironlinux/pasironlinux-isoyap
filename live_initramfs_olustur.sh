#!/bin/bash
dracut -N --force --xz --add 'dmsquash-live pollcdrom' --omit systemd /boot/initrd_live `ls /usr/lib/modules`
