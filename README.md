# homelab

## Deploying

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
        mkfs.btrfs /dev/sdb1

3.  Mount the new partitions into `/mnt` so that a NixOS install can be
    performed:

        mount /dev/sdb1 /mnt
        btrfs subvolume create /mnt/nix
        btrfs subvolume create /mnt/persist
        mount /dev/sdb1 -o subvol=nix /mnt/nix
        mount /dev/sdb1 -o subvol=persist /mnt/persist
        mount /dev/sdb15 /mnt/boot
        mount /dev/sdb1 -o subvol=nix /nix

4.  Install Nix and the installation tools into the recovery OS.

        curl -L https://nixos.org/nix/install | sh .
        $HOME/.nix-profile/etc/profile.d/nix.sh
        nix-env -f '<nixpkgs>' -iA nixos-install-tools
