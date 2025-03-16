# NixOS Remote Pull Backup Server Guide

## This repository contains a guide on how to set up a NixOS backup server to remotely pull directories and files from another machine using Rsync.

## Download NixOS 24.05 Minimal

https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso

Flash the image to an USB drive using [Rufus](https://rufus.ie/en/) or use [Ventoy](https://ventoy.net).
Please note that using these tools will erase all data on the USB drive, so make sure to back up any important files before proceeding.

You can install it in a VM using [ProxmoxVE](https://www.proxmox.com/en/) or [VMWare Workstation Pro](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) as well.

## Install NixOS 24.05 Minimal

### Live CD configuration

- Change your keyboard layout with `sudo loadkeys de` if you don't have an ANSI keyboard.
- Type `sudo passwd` to enter a password and activate the root account.

### SSH Connection (optional)

- Type in `ip a` to see your IP-address and connect via SSH from another machine with `ssh root@<IPFromTheNixOS-BackupServer>`.

### Create a partition table and format the disks

- Use `ls /sys/firmware/efi` to check if you are in `UEFI` or `BIOS` mode. If you receive `ls: cannot access '/sys/firmware/efi': No such file or directory` you are in `BIOS` mode.
- Plugin the backup disks now, if not already connected. Partition and format them as needed.
- Display your disks with `lsblk -f` and adjust the device paths `/dev/sdX` in the following commands with your desired drive(s) to install NixOS on.

### UEFI

```
parted --script /dev/sda mklabel gpt && \
parted --script /dev/sda mkpart primary fat32 1MB 512MB --align optimal && \
parted --script /dev/sda set 1 esp on && \
parted --script /dev/sda mkpart primary ext4 512MB 768MB --align optimal && \
parted --script /dev/sda mkpart primary f2fs 768MB 4.980GB --align optimal && \
mkfs.fat -F 32 -n NIXBOOT /dev/sda1 && \
mkfs.ext4 -L NIXROOT /dev/sda2 && \
mkfs.f2fs -l NIXSTORE /dev/sda3 && \
mount /dev/disk/by-label/NIXROOT /mnt && \
mkdir -p /mnt/nix/ && \
mount /dev/disk/by-label/NIXSTORE /mnt/nix && \
mkdir -p /mnt/boot && \
mount -o umask=077 /dev/disk/by-label/NIXBOOT /mnt/boot && \
mkdir -p /mnt/etc/nixos/
```

### BIOS

``` 
parted --script /dev/sdX mklabel msdos && \
parted --script /dev/sdX mkpart primary ext4 1MB 256MB --align optimal && \
parted --script /dev/sdX mkpart primary f2fs 256MB 4.980GB --align optimal && \
mkfs.ext4 -L NIXROOT /dev/sdX1 && \
mkfs.f2fs -l NIXSTORE /dev/sdX3 && \
mount /dev/disk/by-label/NIXROOT /mnt && \
mkdir -p /mnt/nix/ && \
mount /dev/disk/by-label/NIXSTORE /mnt/nix && \
mkdir -p /mnt/etc/nixos/
```

### Adjust the NixOS configuration

- Open a `gitMinimal` shell with `nix-shell -p gitMinimal`, clone this repo with `git clone https://github.com/DieSchoeneWolke/NixOS-BackupServer && exit`.

- Copy all files to `/mnt/etc/nixos/` with `cp -R ./NixOS-BackupServer/* /mnt/etc/nixos/ && cd /mnt/etc/nixos/`. 

- Edit the network configuration file with `nano network.nix` and replace it with the values for your network card.

- Create a user on the machine with read/write/execute permissions on the directories you want to back up. 

- Generate two ssh-keyfiles. One on the machine you are configuring this server from with a keyphrase and insert the content of the public keyfile in the `users.nix` file and change the `initialPassword` in the file. The other ssh-keyfile should be created on this server with `ssh-keygen -o -a 100 -t ed25519` and saved to `/root/.ssh/rsync.prvk` without a passphrase. Insert the content of the public keyfile in the machine you want to backup at `/home/<UserYouCreated>/.ssh/known_hosts`. `chmod 600 <YourPrivateKeyfile>` to set appropriate permissions for the current user on the private keyfile.

- Edit the `backup.nix` file and adjust the backup jobs to your needs. 

- If you are in `BIOS` mode, edit `system.nix`, remove the `UEFI` bootloader section,uncomment the `BIOS` section and replace the `device` name with your root drive.

- Edit the `hardware-configuration.nix` file accordingly to your hardware.

- Install NixOS with `nixos-install --no-root-passwd`.

- `reboot` the system.

- Reconnect with `ssh -i <PrivateKeyfileFromTheConfiguringMachine> backupper@<IPFromTheNixOS-BackupServer>` and the keyphrase you provided while creating the keyfile.

- Change the password with `passwd`.

- Connect to the machine you want to back up from the NixOS-BackupServer with `sudo ssh -i /root/.ssh/rsync.prvk <UsernameFromTheBackupMachine>@<IPFromTheBackupMachine>` once to add it to the known_hosts file.

- `systemctl list-timers --all` to see if the timers for your backup jobs are running.

## Features planned:

- Email notification upon backup completion. As of now this only works for manual jobs since `systemd-timers` use an empty environment and don't support `MAILTO` like `cron`. Use the `mail.nix` from my [NixOS-SMTP repository](https://github.com/DieSchoeneWolke/NixOS-SMTPRelay) to use `msmtp` as `SMTP client`.