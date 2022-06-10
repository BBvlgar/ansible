# Install Hetzner Root server

This util is thought to support one to install a new server. The server has to be in rescue mode for that.

## The configuration file for the installation

This is the default config supported for Ubuntu 20.04 minimal – and will be created by this util as `/autosetup` file to support the non-interactive setup by `installimage` command. After this playbook is run, your server will reboot and you'll be able to login as `root` with the password, your Rescue system was started with.  
The official documentation can be found in the [Hetzner Docs](https://docs.hetzner.com/robot/dedicated-server/operating-systems/installimage/).

```
## ======================================================
##  Hetzner Online GmbH - installimage - standard config
## ======================================================


## ====================
##  HARD DISK DRIVE(S):
## ====================


# LSI RAID (LD ): no name
DRIVE1 /dev/sda



## ==========
##  HOSTNAME:
## ==========

## which hostname should be set?
##

HOSTNAME Ubuntu-2004-focal-64-minimal


## ==========================
##  PARTITIONS / FILESYSTEMS:
## ==========================

## define your partitions and filesystems like this:
##
## PART  <mountpoint/lvm>  <filesystem/VG>  <size in MB>
##
## * <mountpoint/lvm> mountpoint for this filesystem  *OR*  keyword 'lvm'
##                    to use this PART as volume group (VG) for LVM
## * <filesystem/VG>  can be ext2, ext3, reiserfs, xfs, swap  *OR*  name
##                    of the LVM volume group (VG), if this PART is a VG
## * <size>           you can use the keyword 'all' to assign all the
##                    remaining space of the drive to the *last* partition.
##                    you can use M/G/T for unit specification in MiB/GiB/TiB
##
## notes:
##   - extended partitions are created automatically
##   - '/boot' cannot be on a xfs filesystem
##   - '/boot' cannot be on LVM!
##   - when using software RAID 0, you need a '/boot' partition
##
## example without LVM (default):
## -> 4GB   swapspace
## -> 512MB /boot
## -> 10GB  /
## -> 5GB   /tmp
## -> all the rest to /home
#PART swap   swap        4G
#PART /boot  ext2      512M
#PART /      ext4       10G
#PART /tmp   xfs         5G
#PART /home  ext3       all
#
##
## to activate LVM, you have to define volume groups and logical volumes
##
## example with LVM:
#
## normal filesystems and volume group definitions:
## -> 512MB boot  (not on lvm)
## -> all the rest for LVM VG 'vg0'
#PART /boot  ext3     512M
#PART lvm    vg0       all
#
## logical volume definitions:
#LV <VG> <name> <mount> <filesystem> <size>
#
#LV vg0   root   /        ext4         10G
#LV vg0   swap   swap     swap          4G
#LV vg0   tmp    /tmp     reiserfs      5G
#LV vg0   home   /home    xfs          20G
#
#
## your system has the following devices:
#
# Disk /dev/sda: 3000 GB (=> 2794 GiB) 
#
## Based on your disks and which RAID level you will choose you have
## the following free space to allocate (in GiB):
# RAID  0: ~2794
# RAID  1: ~2794
#

PART swap swap 16G
PART /boot ext3 512M
PART / ext4 1024G
PART /home ext4 all


## ========================
##  OPERATING SYSTEM IMAGE:
## ========================

## full path to the operating system image
##   supported image sources:  local dir,  ftp,  http,  nfs
##   supported image types: tar, tar.gz, tar.bz, tar.bz2, tar.xz, tgz, tbz, txz
## examples:
#
# local: /path/to/image/filename.tar.gz
# nfs:   hostname:/path/to/image/filename.tgz
## FTP, HTTP, HTTPS can use regular user:password@ syntax
# ftp:   ftp://hostname/path/to/image/filename.tar.bz2
# http:  http://hostname/path/to/image/filename.tbz
# https: https://hostname/path/to/image/filename.tbz
#
# for validation of the image, place the detached gpg-signature
# and your public key in the same directory as your image file.
# naming examples:
#  signature:   filename.tar.bz2.sig
#  public key:  public-key.asc

IMAGE /root/.oldroot/nfs/install/../images/Ubuntu-2004-focal-64-minimal.tar.gz
```

## How to run the playbook

This playbook is based on two assumptions:

* your Hetzner root server is started with the Rescue mode
* you want to do a basic installation

For that, the server is currently not installed to know any SSH key or sth. else, but basic Python installation is available in Rescue mode.

### Preparation

Within your environment, you'll have to define some variables for preparing the `/autosetup` file. For the example, we'll stick to the full configuration example above. You should have a look in your folder `/root/.oldroot/nfs/install/../images/` within Rescue mode: which default images Hetzner does provide you – or search the URL / providing link for the image, you want to install on your server now!

```yml
hetzner_install:
  hostname: Ubuntu-2004-focal-64-minimal
  image: "{{ install_base }}/../images/Ubuntu-2004-focal-64-minimal.tar.gz"
  drives:
    - /dev/sda
  partitions:
    - destination: swap
      filesystem:  swap
      size:        16G
    - destination: /boot
      filesystem:  ext3
      size:        512M
    - destination: /
      filesystem:  ext4
      size:        1024G
    - destination: /home
      filesystem:  ext4
      size:        all
  additionals:
    - "# by this variable, you can define additional lines added to your `/autosetup` file."
    - "# All variables except `additionals` are mandatory for this playbook!"
```

`additionals` could be for example:

* `SWRAID <swraid>` and `SWRAIDLEVEL <level>`
* logical volumes by `LV <vg> <name> <mountpoint> <filesystem> <size>`
* `SSHKEYS_URL <url>`
* `BOOTLOADER <bootloader>`

### Running the playbook

Since the server is in rescue mode, the playbook ignores host key checks, etc.

Now, we want to run the task. From your Ansible root directory, please run some command like this:

```sh
ansible-playbook -i environments/production playbooks/utils/hetzner_install/main.yml --limit "server_alias" --user root --ask-pass
```

You'll have to define some things:

* `--limit` – please ensure to mention the correct destination hos. Refer to the [Documentation](https://ansible-tips-and-tricks.readthedocs.io/en/latest/ansible/commands/#limiting-playbooktask-runs).
* `--user` depends on your inventory file: if you defined `root` as the correct user there, you can ignore this.
* `--ask-pass` – you regularly do not provide SSH keys to your rescue system, so you'll need an authentication password – and Ansible will ask you for that =)
