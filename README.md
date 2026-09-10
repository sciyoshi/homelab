# homelab

Personal Nix configuration for my machines and homelab. This repo is normally
checked out at `~/.homelab`; on newer machines I may use `~/.setup`.

The goal is centralized editing and automation with local escape hatches:

- most work happens from `fellow-sci` or `sci`
- hosts keep a local checkout so I can run quick local switches for testing
- remote hosts should eventually deploy automatically every day
- rollbacks should stay easy, either through Nix generations or deploy tooling

## Hosts

| Host | Platform | Role |
| --- | --- | --- |
| `fellow-sci` | `aarch64-darwin` | Mac laptop, main automation/editing host, nix-darwin + Home Manager + Homebrew |
| `sci` | `x86_64-linux` | Home Linux desktop, niri/hyprland, Nvidia GPU, local ML workloads |
| `scilo` | `x86_64-linux` | Home Linux server, persistent services, backups, home automation, media |
| `misaki` | `aarch64-linux` | Raspberry Pi in Montreal, borg backup target |
| `alpha` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `beta` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `gamma` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `scipi4` | `aarch64-linux` | Old Raspberry Pi config; likely unused/dead after Home Assistant moved off it |

There is also a standalone Home Manager output:

| Output | Platform | Role |
| --- | --- | --- |
| `homeConfigurations.sciyoshi` | `x86_64-linux` | Ubuntu/WSL2 VM profile |

## Repository Layout

```text
flake.nix                  # inputs and output dispatcher
darwin-configuration.nix   # fellow-sci nix-darwin config
nix/
  darwin.nix               # darwinConfigurations
  nixos.nix                # nixosConfigurations
  home-manager.nix         # standalone WSL2/Ubuntu Home Manager output
  deploy.nix               # deploy-rs nodes
  shell.nix                # devShell
  sd-utils/                # custom sd-image module for misaki
hosts/                     # thin NixOS host entrypoints
nixos/                     # shared NixOS modules and service configs
sci/                       # desktop NixOS config and hardware
scilo/                     # home server NixOS config and hardware
home/                      # Home Manager modules
overlays/                  # custom package overlays
k3s/                       # Kubernetes-side config artifacts
scripts/                   # one-off scripts
secrets.yaml               # sops-encrypted secrets
.sops.yaml                 # sops recipients
```

## Common Commands

### Pending sci Btrfs migration

The `sci` configuration now targets Btrfs labelled `sci-btrfs`. **Do not run
`nixos-rebuild switch` or `nixos-rebuild boot` on the existing ext4 installation.**
The pre-migration configuration is commit
`4640e3dadf19611cfc88b94845131c183fb911e0`; record this outside the machine.
The old ext4 UUID is `01bf5eef-5419-4b98-99c9-9cfb7f52b876`.

Build before recovery (this does not require the new filesystem to exist):

```sh
nix flake check --no-build
nix build .#nixosConfigurations.sci.config.system.build.toplevel --no-link
```

In recovery, after shrinking ext4 and creating the new Btrfs filesystem, create
top-level subvolumes `root`, `home`, `nix`, and `persist`. Snapshot the **empty**
`root` as read-only `blank` immediately, before mounting the installation target
or running `nixos-install`. Mount the old ext4 filesystem read-only at
`/run/migration-old`, outside `/mnt`. Mount the new root at `/mnt`, with its
`home`, `nix`, and `persist` subvolumes at the corresponding paths and the
existing ESP at `/mnt/boot`. Copy `/home`, `/nix`, and all paths listed in
`environment.persistence` from the old installation, preserving numeric owners,
permissions, ACLs, and xattrs. Check optional paths exist before copying.
In particular, copy `/etc/NetworkManager/system-connections`, including its
directory permissions, and all existing SSH host keys listed in the config.

Before installation, seed the password file from the old system's current
shadow entry. Run these commands as root in recovery; they never print the hash
and must not be run with shell tracing enabled:

```sh
set +x
awk -F: '$1 == "sciyoshi" && $2 ~ /^\$/ { found=1 } END { exit !found }' \
  /run/migration-old/etc/shadow || { echo 'Missing usable password hash'; exit 1; }
install -d -m 0700 -o root -g root /mnt/persist/passwords
install -m 0600 -o root -g root /dev/null /mnt/persist/passwords/sciyoshi
awk -F: '$1 == "sciyoshi" { print $2 }' /run/migration-old/etc/shadow \
  > /mnt/persist/passwords/sciyoshi
test -s /mnt/persist/passwords/sciyoshi
```

The password file is deliberately outside Git and the Nix store. It is the
source for the password after root resets; subsequent `passwd` changes alone
will not survive a reset. Update the protected hash file when changing passwords.
Rollback refuses to delete root if this file is missing or empty.

Check available ESP space before `nixos-install`; old generation entries are
not guaranteed to survive bootloader cleanup. Keep the recovery media and ext4
partition intact. Install using `/mnt/home/sciyoshi/.homelab#sci` and select the
`no-rollback` specialisation for the first boot. It adds
`impermanence.disable=1`, skipping root reset. Verify login, network profiles,
SSH/Tailscale identities and mounts, then reboot into the normal entry and
verify an unpersisted marker disappears while home/persist markers remain.

The rollback service runs in systemd initrd after the resume ordering point and
root-device discovery, before `sysroot.mount`. It checks the baseline is a
read-only subvolume, validates root is a subvolume, then uses native Btrfs
recursive deletion and snapshots `blank`. A failed rollback blocks root mount;
use `no-rollback` or recovery media to investigate. This specialisation still
boots Btrfs; it is not an ext4 fallback.

Keep ext4 during validation. Before eventual Btrfs device-add/remove
consolidation, all live data **and metadata allocations** must fit comfortably
on the former ext4 partition. That operation needs a separate review of the
actual partition geometry and Btrfs usage.

### Routine commands

Enter the dev shell first if direnv has not already done it:

```sh
nix develop
```

Format Nix files:

```sh
nixfmt <files...>
```

Evaluate the flake:

```sh
nix flake check --no-build
```

Build a NixOS host without activating:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Build Darwin without activating:

```sh
nix build .#darwinConfigurations.fellow-sci.system
```

Switch the local NixOS host from its local checkout:

```sh
sudo nixos-rebuild switch --flake ~/.homelab#<host>
```

or, on newer checkouts:

```sh
sudo nixos-rebuild switch --flake ~/.setup#<host>
```

Switch `fellow-sci`:

```sh
sudo darwin-rebuild switch --flake ~/.homelab#fellow-sci
```

Switch the WSL2/Ubuntu Home Manager profile:

```sh
home-manager switch --flake ~/.homelab#sciyoshi
```

## Deployment

The repo currently uses deploy-rs:

```sh
deploy .#<host>
deploy .
```

`nix/deploy.nix` sets:

```nix
autoRollback = false;
magicRollback = true;
```

So deploy-rs should roll back if its post-activation SSH check fails, while not
fighting activation rollbacks.

Deploy-rs has been somewhat troublesome in practice. Alternatives under
consideration:

- `nixos-rebuild --target-host`: simplest fallback for one host at a time
- Colmena: likely best fit for daily fleet deploys
- Cachix Deploy: possible pull-based model, but more moving parts

Do not assume deploy-rs is the final architecture. The intended direction is a
host inventory that can generate deploy-rs or Colmena config.

## Automation

Current/desired operating model:

- `fellow-sci` runs Claude automation that keeps flakes up to date and switches
  Darwin locally
- most edits happen on `fellow-sci` or `sci`
- `scilo` is mostly accessed over SSH for persistent services or one-off server
  work
- daily automated deployment to remote NixOS hosts is desired, but the deploy
  mechanism is still open
- `sci` should remain easy to update locally because it is an interactive desktop
  and ML machine

## Secrets

Secrets are encrypted with sops in `secrets.yaml`. Recipients live in
`.sops.yaml`.

Host age keys are derived from:

```text
/etc/ssh/ssh_host_ed25519_key
```

For a new host, add the host public key to `.sops.yaml`, then re-encrypt:

```sh
sops updatekeys secrets.yaml
```

Do not commit plaintext secrets.

## Cross-Architecture Builds

`misaki` and `scipi4` are `aarch64-linux`. Building them from `x86_64-linux`
requires binfmt emulation or a remote builder. `scilo` currently has:

```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

One way to enable qemu binfmt support on non-NixOS Linux:

```sh
sudo update-binfmts --package qemu-user-static --remove qemu-aarch64 /usr/bin/qemu-aarch64-static
sudo update-binfmts \
    --package qemu-user-static \
    --install qemu-aarch64 /usr/bin/qemu-aarch64-static \
    --magic '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00' \
    --mask '\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff' \
    --offset 0 \
    --credential yes \
    --fix-binary yes
```

## macOS Bootstrap

For `fellow-sci`, use Determinate Nix. The Darwin config enables
`determinateNix.enable = true`, so do not layer another Nix installer manager on
top of it.

Rough bootstrap:

```sh
# Install Homebrew first if needed:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Determinate Nix, then clone this repo:
git clone <repo-url> ~/.homelab
cd ~/.homelab

nix build .#darwinConfigurations.fellow-sci.system
./result/sw/bin/darwin-rebuild switch --flake .#fellow-sci
```

If `/run` is missing on a fresh macOS install:

```sh
echo "run	private/var/run" | sudo tee -a /etc/synthetic.conf
/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```

## OVH Bootstrap

The OVH hosts use tmpfs root with persistent state in `/persist`. The old manual
bootstrap flow is:

1. Reboot the VPS into Rescue Mode and SSH into the node.
2. Format the target OS partition as btrfs.
3. Create `nix` and `persist` subvolumes.
4. Mount tmpfs as `/mnt`, then mount `/mnt/nix`, `/mnt/persist`, and `/mnt/boot`.
5. Install NixOS with enough SSH/user config to get back in.
6. Switch to this flake's host config.

Anything that must survive reboot on `alpha`, `beta`, or `gamma` needs to be
listed in `environment.persistence`.

These notes should eventually be replaced with a cleaner `nixos-anywhere` or
documented install runbook.
