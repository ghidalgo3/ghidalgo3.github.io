---
layout: post
title:  "Linux Disk Reference"
date:   2022-04-01 12:34:23 -0400
categories: tools
draft: true
---

Running out of disk space on a system can be much more disruptive than running out of memory or being under high load.
Recently at work we experienced a brief outage due to a machine (not a VM!) whose disk filled up with log files, which caused the application writing to disk to crash, which made the machine useless, which led to the outage.
The mitigation was to release disk space, start the application, and configure it to limit its disk usage and to clean up logs.
The investigation that led to discovering the issue was a pleasant trip through the different file system and disk utilization tools, and this may prove useful to me or someone else in the future.

# Contents
* TOC
{:toc}

# Disk vocabulary
From the kernel's point of view, disks are just another kind of I/O device just like your keyboard, network interface, monitor, or USB drive virus vector.
However since every system has a disk and has to interact with the disk to boot and to persist data, disks have evolved many different protocols, naming schemes, and tools unique to them.
It's important to know a few terms commonly seen around disks:
1. `block device` : As opposed to `character devices`, block devices support reading and writing "blocks" of data instead of single bits, bytes, or characters. Another key differentiator between block and character devices is the presence of kernel buffering of I/O operations. Block device reads and writes may be served by buffers for performance, while the underlying device may be writen to asynchronously by the kernel. Disks are commonly implemented as block devices.
1. `udev`: The userspace system that manages device lifecycles for a system. `udev` does a lot, but you should know that `udev` manages disk _naming_ among other things. 
1. `SCSI`: The [small computer systems interface](https://en.wikipedia.org/wiki/SCSI) is a protocol devices implement to allow kernel drivers to utilize the device. The SCSI protocol was designed for more use cases than disks, though its use in disks is quite common.
1. `SATA` : The [serial AT attachment](https://en.wikipedia.org/wiki/Serial_ATA) is a physical interface physical disks commonly implement to connect to motherboards.
1. `PATA (IDE)` The [parallel AT attachment](https://en.wikipedia.org/wiki/Parallel_ATA) or Integrated Drive Electronics is a physical interface physical disks commonly implement to connect to motherboards.
1. `virtual filesystem`: Unlike Windows, the Linux virtual filesystem does not include disk identifiers in fully qualified file paths. For example, `C:\Program\ Files\` is immediately identifiable to a human as a directory _on_ the `C:\` disk. A file path like `/home/gustavo/code` on Linux does not contain enough information to identify a disk. The mapping between file paths and disks is maintained by the virtual filesystem of the kernel.

# Tools
## `mount`
Used to list filesystems and their mount points.

## `lsblk`
Used to list block devices.
On a normal system, this essentially lists all of the disks or disk-like devices (physical and virtual) on a system.
You should use `lsblk` if you want to know how many "disks" are available on a machine.
You will probably want to know filesystem information, so go ahead and append `[--fs|-f]` to `lsblk`.
Example:
```
gustavo@ubuntu:/$ lsblk -f
NAME   FSTYPE   LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                       
├─sda1 vfat           F325-B43F                               511M     0% /boot/efi
├─sda2                                                                    
└─sda5 ext4           952d0477-324d-417e-b133-9e807cb7af8e    8.5G    50% /
sr0                                                                       
```
You can interpret this output to mean:
1. There are two block devices, `sda` and `sr0`.
1. `sr0` is [SCSI](https://en.wikipedia.org/wiki/SCSI) device 0. 
1. `sda` is the first 
1. 

## `du` 
Used to inspect disk usage of files.
You should use `du` when you want to know which file or directory is consuming disk space.
Example of running this from the root of the file system `/`.
```
gustavo@ubuntu:/$ cd /
gustavo@ubuntu:/$ sudo du -h -d 1
[sudo] password for gustavo: 
4.0K	./mnt
4.6G	./snap
8.0K	./media
12M	./etc
249M	./home
153M	./boot
0	./sys
68K	./root
du: cannot access './run/user/1000/gvfs': Permission denied
1.9M	./run
4.0K	./cdrom
2.2G	./var
0	./dev
186M	./opt
4.0K	./srv
16K	./lost+found
du: cannot access './proc/4238/task/4238/fd/4': No such file or directory
du: cannot access './proc/4238/task/4238/fdinfo/4': No such file or directory
du: cannot access './proc/4238/fd/3': No such file or directory
du: cannot access './proc/4238/fdinfo/3': No such file or directory
0	./proc
116K	./tmp
5.9G	./usr
15G	.
```

`du` can be used to find which file or directory is consuming more space than expected.
It's common that some applications do not rotate their log files in `/var/log` by default.
Using `du`, you can quickly find which directory is consuming your disk.

## `df`
Used to inspect disk usage of file systems.
You should use `df` when you want to know how full the entire disk is.
It does not matter what directory you run `df` in, the output does not depend on the current directory.
Example:
```
gustavo@ubuntu:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            1.9G     0  1.9G   0% /dev
tmpfs           389M  1.9M  388M   1% /run
/dev/sda5        20G  9.7G  8.5G  54% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
/dev/sda1       511M  4.0K  511M   1% /boot/efi
tmpfs           389M   40K  389M   1% /run/user/1000
```

# What happens when I plug in a disk?

# References
https://wiki.archlinux.org/title/Persistent_block_device_naming
https://www.kernel.org/doc/html/latest/filesystems/vfs.html