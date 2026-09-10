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

## Zigbee on sci

The ConBee II USB adapter uses Home Assistant's built-in **Zigbee Home
Automation (ZHA)** integration. Its dependencies and serial-device permissions
are enabled through `services.home-assistant.extraComponents` in
`sci/configuration.nix`.

After activating the NixOS configuration, open Settings → Devices & services
in Home Assistant and configure the discovered ConBee II, or add **Zigbee Home
Automation** manually. Select this stable serial path:

```text
/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2234146-if00
```

If radio detection fails, select **deCONZ** as the radio type. Complete the
setup, then add devices through ZHA while putting each device into pairing
mode. Zigbee state is stored in Home Assistant's existing persisted directory.
Only one service can use the adapter at a time.

Upstream instructions: [Zigbee Home Automation](https://www.home-assistant.io/integrations/zha/).

## Eufy Security on sci

Home Assistant's Eufy Security integration and the `eufy-security-ws` bridge
are pinned in `overlays/eufy-security.nix`; HACS is not needed. The native bridge
listens on `127.0.0.1:3000`, with go2rtc on `127.0.0.1:1984` (API) and
`127.0.0.1:8554` (RTSP). Home Assistant handles access from browsers.

Create a separate Eufy account, share the home/devices with it with admin access,
and log into that account in the Eufy app once to accept the invitation. Provision
its credentials locally, outside Git and the Nix store:

```sh
sudo install -d -m 0700 /persist/credentials
sudo test -e /persist/credentials/eufy-security.json || \
  sudo install -m 0600 /dev/null /persist/credentials/eufy-security.json
sudoedit /persist/credentials/eufy-security.json
```

Use this JSON structure, replacing the placeholders and setting `country` to
the account's two-letter country code (`CA` for Canada):

```json
{
  "username": "EUFY_ACCOUNT_EMAIL",
  "password": "EUFY_ACCOUNT_PASSWORD",
  "country": "CA"
}
```

The service remains stopped until this file exists. After activating the NixOS
configuration and saving the credentials, run `sudo systemctl restart eufy-security`.
Systemd supplies a private credential copy; bridge tokens and station state
persist under `/persist/var/lib/eufy-security`. Credential changes require a restart.

In Home Assistant, add **Eufy Security** under Settings → Devices & services,
using host `127.0.0.1` and port `3000`. Set its GO2RTC host option to `127.0.0.1`.
Complete any CAPTCHA or two-factor challenge through the integration's
reauthentication prompt. Enable device push notifications in Eufy's app for
events. The E340 doorbell and eufyCam 3C cameras are discovered from the shared
account; live video may need the camera's Start P2P Stream action and consumes
battery while active.

Start live video with `camera.turn_on` and stop it with `camera.turn_off` on
the relevant camera entity. Leave the integration's "No stream in HA" option
disabled. P2P video is converted on demand to 1080p H.264 by go2rtc/FFmpeg for
browser compatibility; Eufy's Auto mode can otherwise deliver 4K H.265. This
uses CPU on `sci` while viewing and does not change camera recording settings.
Front Door live-stream quality is set to Low in Eufy; Auto repeatedly stalled
in testing. The compatibility patch is `overlays/eufy-security-h264.patch`.

Useful diagnostics: `journalctl -u eufy-security -u go2rtc -u home-assistant`.
Upstream setup notes: [Eufy Security integration](https://github.com/fuatakgun/eufy_security)
and [bridge](https://github.com/bropat/eufy-security-ws).

## Btrfs impermanence on sci

The Btrfs migration is complete. `sci` uses the filesystem labelled `sci-btrfs`
with separate `root`, `home`, `nix`, and `persist` subvolumes. On normal boots,
the initrd resets `root` from the read-only `blank` snapshot before mounting it.
`/home`, `/nix`, and `/persist` survive resets; system state that must persist
is listed in `environment.persistence` in `sci/configuration.nix`.

The login password hash lives in `/persist/passwords/sciyoshi`, outside Git and
the Nix store. Update this protected file when changing the password; `passwd`
changes alone will not survive a reset. Root reset refuses to proceed if the
file is missing or empty.

For troubleshooting, select the `no-rollback` boot specialisation. It adds
`impermanence.disable=1` to skip the root reset while keeping the same Btrfs
mounts. A failed reset blocks the normal root mount; use this entry or recovery
media to investigate.

## Common Commands

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
