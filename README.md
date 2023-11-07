# homelab

## Deploying

## Cross-Platform Deploy

Deploying an `aarch64` machine from `x86_64` requires adding binfmts emulation support:

    sudo update-binfmts --package qemu-user-static --remove qemu-aarch64 /usr/bin/qemu-aarch64-static
    sudo update-binfmts \
        --package qemu-user-static \
        --install qemu-aarch64 /usr/bin/qemu-aarch64-static \
        --magic '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00' \
        --mask '\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff' \
        --offset 0 \
        --credential yes \
        --fix-binary yes

## OSX setup

Set hostname (System Preferences > Sharing).

Install homebrew:

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Install nix:

    sh <(curl -L https://nixos.org/nix/install)

Until this is addressed: https://github.com/LnL7/nix-darwin/issues/149

    sudo mv /etc/nix/nix.conf /etc/nix/.nix-darwin.bkp.nix.conf

Clone repository, then (replace hostname):

    nix build .#darwinConfigurations.{hostname}.system

Set up synthetic.conf:

    echo "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf
    /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t

Run:

    ./result/sw/bin/darwin-rebuild switch --flake .

## Bootstrapping Nix on OVH

To install an ephemeral NixOS on OVH, use the following steps:

1.  Reboot the VPS into Rescue Mode and SSH into the node with the provided
    credentials.

2.  Format the root filesystem (in this example, `/dev/sdb` is the drive,
    `/dev/sdb1` is the OS partition, and `/dev/sdb15` is the EFI partition):

        apt install btrfs-progs
        mkfs.btrfs -f /dev/sdb1

3.  Mount the new partitions into `/mnt` so that a NixOS install can be
    performed:

        mount /dev/sdb1 /mnt
        btrfs subvolume create /mnt/nix
        btrfs subvolume create /mnt/persist
        umount /mnt
        mount -t tmpfs -o mode=755 tmpfs /mnt
        mkdir /nix /mnt/{boot,nix,persist}
        mount /dev/sdb1 -o subvol=nix /mnt/nix
        mount /dev/sdb1 -o subvol=persist /mnt/persist
        mount /dev/sdb15 /mnt/boot
        mount /dev/sdb1 -o subvol=nix /nix

4.  Install Nix and the installation tools into the recovery OS.

        groupadd -g 30000 nixbld
        useradd -u 30000 -g nixbld -G nixbld nixbld
        curl -L https://nixos.org/nix/install | sh
        . $HOME/.nix-profile/etc/profile.d/nix.sh
        nix-channel --add https://nixos.org/channels/nixos-23.05 nixpkgs
        nix-channel --update
        nix-env -f '<nixpkgs>' -iA nixos-install-tools
        nixos-generate-config --root /mnt

5.  Edit `/etc/nixos/configuration.nix` to ensure that the OpenSSH server is
    enabled (`services.openssh.enable = true`) and set credentials to allow
    remote access once the system reboots (for example, by setting
    `users.users.root.initialHashedPassword`). Ensure that the root tmpfs
    filesystem has `mode=0755` set as an option (otherwise SSH will complain
    about permissions). If there is an error building the logrotate config,
    add `services.logrotate.checkConfig = false` [(see here)][1]

    [1]: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501/2

6.  Install Nix onto the target drive:

        nixos-install --root /mnt
