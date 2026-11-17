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
| `koi` | `x86_64-linux` | OVH VPS replacing alpha, Btrfs root rollback, Tailscale |
| `scipi4` | `aarch64-linux` | Old Raspberry Pi config; likely unused/dead after Home Assistant moved off it |

`alpha`, `beta`, and `gamma` no longer exist. Their NixOS configurations remain
as historical references, but they are not deploy-rs targets.

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

### Desk Knob

The managed automation in `sci/configuration.nix` uses a single press of Desk
Knob (`8c:65:a3:ff:fe:ba:75:5b`) to control Floor Lamp
(`light.office_floor_lamp`), Asano Lamp
(`light.kajplats_e12_cws_globe_800lm`), and Casper Glow (`light.jar_0_fe6e`).
If any reports on, it turns all three off; otherwise it turns all three on.
Unavailable lights cannot be controlled and do not count as on.

Before enabling this automation, remove Floor Lamp from the ZHA **Office
Lights** group (group 2), and remove any direct on/off binding from Desk Knob
to the outlet. Direct control would change the outlet before HA evaluates the
three lights. Keep both devices paired to ZHA.

In Developer tools → Events, listen for `zha_event` and press the knob once.
The automation accepts `toggle` (command mode) or `remote_button_short_press`
(event mode), from endpoint 1, cluster 6. HA must receive this event; group
membership alone does not establish that. Confirm event delivery and the
absence of direct outlet control before switching the NixOS configuration.
Then test a press with all three off, and again with only one on. This path
requires Home Assistant to be running. Rotation and long presses are not
handled by this automation.

## Thread and Matter on sci

The ZG-808Z USB stick (CC2652P1 + CH340C) is dedicated to Thread. It was flashed
with `CC1352P2_CC2652P_launchpad_ot_rcp_2025_3_1.hex` from
[Koenkk's OpenThread RCP release 2025.3.1](https://github.com/Koenkk/OpenThread-TexasInstruments-firmware/releases/tag/2025.3.1).
The write passed CRC verification. The stock dump in
`~/zigbee-firmware-backup/zg808z-stock.bin` did **not** pass subsequent CRC
verification; it is not a verified recovery image. Keep firmware backups out
of this repository.

NixOS runs `otbr-agent` with this radio at **460800 baud**, without hardware
flow control, using wired LAN interface `enp5s0`. The radio URL must include
`uart-init-deassert`; without it, this adapter fails Spinel initialization.
With it, the radio version probe reports `OPENTHREAD/1.4.0-Koenkk-2025.3.1`.
The serial device is:

```text
/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
```

This CH340 adapter has no unique USB serial number. Revisit the device path if
another identical adapter is added. Do not configure this stick in ZHA; the
ConBee II continues to handle Zigbee.

After reviewing and switching the NixOS configuration:

1. Check `systemctl status otbr-agent matter-server` and
   `journalctl -u otbr-agent -u matter-server -b`.
2. In Home Assistant, add **OpenThread Border Router** under Settings → Devices
   & services with URL `http://127.0.0.1:5583`. On first setup, HA creates a new
   Thread network if no preferred dataset exists; network keys belong in service
   state, not Nix configuration.
3. Add **Matter**, choose an existing/custom Matter server rather than an
   automatically installed app, and enter `ws://127.0.0.1:5580/ws`.
4. In the Thread settings, make the new network preferred. Check that
   `sudo ot-ctl state` reports `leader` or `router` before pairing.
5. For pairing directly from `sci`, open `http://127.0.0.1:5580` in its browser.
   Matter Server's dashboard has **Commission node → Commission new Thread
   device**. Local Bluetooth commissioning is enabled on adapter `hci0`.
6. Obtain the active Thread dataset with `sudo ot-ctl dataset active -x`.
   Copy only the hexadecimal line into **Thread dataset**, then select **Set
   Thread Dataset**. This value contains network keys; keep it out of the repo.
7. Put the KAJPLATS bulb in pairing mode near the desktop, enter its printed
   Matter setup code in **Pairing code**, and select **Commission**. After
   commissioning, the bulb should appear in HA's Matter integration. This
   desktop pairing path has been verified with the Asano Lamp KAJPLATS bulb.

Phone pairing is also available through the Companion app. First send the
preferred Thread network credentials to the phone: Android uses Settings →
Companion app → Troubleshooting → Sync Thread credentials; iPhone uses the
Thread settings → Send credentials to phone. Then use **Add Matter device**
and scan the bulb's QR code while connected to the home LAN.

The host-scoped `overlays/matter-server.nix` skips malformed PAA certificates
during the startup download. The current DCL contains an NXP certificate that
Cryptography rejects; without this patch the server remains running but never
opens port 5580. IKEA's root parses successfully. The patch leaves device
attestation enabled and does not add the rejected certificate to the trust store.

OTBR and Matter Server expose their control APIs only on localhost. The wired
LAN permits UDP 5353 (mDNS) and 5540 (Matter); `wpan0` also permits UDP 53 for
Thread DNS. Working local IPv6 and multicast are required; an IPv6 internet
connection is not. `sci` must remain awake for its border router to operate.

`/var/lib/thread`, `/var/lib/matter-server`, and Home Assistant's configuration
are persisted under `/persist`. These contain the Thread network and Matter
pairing credentials; losing them may require pairing devices again. Matter
Server uses a dedicated static service user so its state has stable ownership
across root resets.

References: [OpenThread Border Router integration](https://www.home-assistant.io/integrations/otbr/),
[Thread setup](https://www.home-assistant.io/integrations/thread/),
[Matter pairing](https://www.home-assistant.io/integrations/matter/).

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
disabled. P2P video is converted on demand to H.264, capped at 1080 pixels high,
by go2rtc/FFmpeg for browser compatibility; Eufy's Auto mode can otherwise
deliver 4K H.265. This uses CPU on `sci` while viewing and does not change
camera recording settings.
The scale filter keeps an even width for the E340's portrait video and avoids
upscaling lower-resolution streams. An odd width makes the H.264 encoder fail
with `width not divisible by 2`.
The `eufy` FFmpeg input preset in `sci/configuration.nix` bounds startup probing
to reduce the delay before video appears.
The integration inspects video headers rather than Eufy's sometimes stale
codec metadata. If a camera switches between H.265 and H.264, it reconnects
the go2rtc input so the transcoder sees the correct format. It also waits for
a complete codec header when joining an existing stream.
Front Door live-stream quality is set to Low in Eufy; Auto repeatedly stalled
in testing. If it sends a brief 4K burst and then the bridge reports no data,
reapply Low even if the integration already displays that value, then start a
fresh stream. The compatibility patch is `overlays/eufy-security-h264.patch`.

Useful diagnostics: `journalctl -u eufy-security -u go2rtc -u home-assistant`.
Upstream setup notes: [Eufy Security integration](https://github.com/fuatakgun/eufy_security)
and [bridge](https://github.com/bropat/eufy-security-ws).

## Home Assistant Funnel on sci

The `ha-tailscale` NixOS container provides a dedicated personal-tailnet node
named `ha-sci`. The desktop's normal Tailscale client can switch accounts
independently. The container uses userspace networking, an automatically chosen
UDP port, and the host's network namespace so Funnel can reach HA at
`http://127.0.0.1:8123`. It does not install a VPN interface, routes, or DNS
settings. The host's Internet connection, DNS, and any selected exit node still
affect its outbound connectivity.

The container's root is ephemeral, but its `/var/lib/tailscale` is bound to
the host's root-only `/var/lib/ha-tailscale`, persisted under
`/persist/var/lib/ha-tailscale`. This contains the node identity and must survive
reboots. No Tailscale auth key is needed: authenticate once in a browser and
Tailscale reuses its saved identity. `sci` has no `/run/secrets`; it includes the
sops-nix module but does not declare SOPS secrets.

Initial setup, after reviewing and switching the NixOS configuration:

1. In HA **Settings → System → Network → HTTP server**, enable **Trust
   X-Forwarded-For** and add **127.0.0.1** to **Trusted proxies**. Save and confirm
   the settings after HA restarts, within the five-minute confirmation window.
   HA 2026.8+ stores these settings in the UI; adding an `http:` YAML block is
   no longer the supported way to manage them.
2. Authenticate the dedicated node using your **personal** Tailscale account:

   ```sh
   sudo nixos-container run ha-tailscale -- tailscale up \
     --hostname=ha-sci --accept-dns=false --accept-routes=false
   ```

   Open the printed login URL, choose the personal tailnet, and approve the
   device if required. For unattended operation, disable key expiry for
   **ha-sci** in Tailscale's Machines page; otherwise reauthentication will be
   needed when the node key expires.
3. The `ha-funnel` service retries until the node is connected. View its output:

   ```sh
   sudo nixos-container run ha-tailscale -- journalctl -u ha-funnel -n 30
   ```

   If it prints a Funnel enablement URL, open it and approve HTTPS/Funnel for
   the personal tailnet. That tailnet needs MagicDNS, HTTPS certificates, and
   the `funnel` node attribute. The service retries automatically; it can also
   be restarted with:

   ```sh
   sudo nixos-container run ha-tailscale -- systemctl restart ha-funnel
   sudo nixos-container run ha-tailscale -- tailscale funnel status
   ```

4. Use the actual HTTPS URL printed by Funnel, normally
   `https://ha-sci.<personal-tailnet>.ts.net`, for Google Home's authorization,
   token, and fulfillment URLs. Test the HA login page from a phone on cellular
   with Tailscale disabled, then verify it still works after switching the
   desktop client to work. Funnel exposes the HA web service publicly; normal
   HA authentication still applies.

Funnel runs in the foreground under systemd, so stopping `ha-funnel` removes
the endpoint. It restarts on container boot. To stop public access temporarily:

```sh
sudo nixos-container run ha-tailscale -- systemctl stop ha-funnel
```

To disable it persistently, remove the container's `ha-funnel` service from
`sci/configuration.nix` and switch. Do not run `tailscale logout` or delete its
state unless deliberately replacing this node's identity.

References: [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel),
[Funnel CLI](https://tailscale.com/docs/reference/tailscale-cli/funnel), and
[HA HTTP settings](https://www.home-assistant.io/integrations/http/).

## Google Home on sci

The manual Google Home integration uses project `saint-hubert-0dba4` and the
public endpoint `https://ha-sci.platypus-locrian.ts.net`. It exposes all entities
supported by HA's Google Assistant integration and reports their state to
Google. Each additional HA installation should use its own project.

In Google Cloud, select that same project, enable the **HomeGraph API**, and
create a service account under **IAM & Admin → Service Accounts**. Following
the HA setup guide, give it **Service Account Token Creator**, then create a
JSON key under **Keys → Add key → Create new key**.

Install the downloaded file **before switching this configuration**:

```sh
sudo install -d -m 0700 /persist/credentials
sudo install -o root -g root -m 0600 "$HOME/Downloads/YOUR_DOWNLOADED_KEY.json" \
  /persist/credentials/google-home.json
```

The HA service requires that file at startup. Systemd supplies it privately as
`/run/credentials/home-assistant.service/google-home.json`; neither the key nor
its contents belong in Git or a Nix expression. This uses systemd credentials,
not SOPS or `/run/secrets`.

After switching, check `journalctl -u home-assistant` for setup errors. In the
Google Home app, use **Add → Works with Google Home**, select the integration
listed as `[test] <integration name>`, and log in to HA. Assign the imported
devices to the appropriate Google Home and rooms, then try “Hey Google, close
the Living Room curtains.” On Android Gemini, enable Google Home in its
Connected Apps settings if it is not already enabled.

After changing exposure settings and switching, say “Hey Google, sync my
devices” or run `google_assistant.request_sync` in HA's Developer Tools →
Actions to refresh the devices available in Google Home.

`overlays/home-assistant-google.nix` works around HA returning the previous
state in a successful Google command response when `report_state` is enabled
([upstream issue](https://github.com/home-assistant/core/issues/125793)). It
waits for device service handlers, including lights and covers, while keeping
background state reports enabled. This does not wait for a blind to finish
moving; its later position updates still go through Report State. HA's existing
two-second command deadline remains, so slow handlers can still return stale
state. Recheck this workaround when upgrading HA.

Reference: [Home Assistant's manual Google Assistant setup](https://www.home-assistant.io/integrations/google_assistant/#manual-setup-if-you-dont-have-home-assistant-cloud).

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

## koi: OVH VPS

`koi` replaces alpha at `149.56.135.22` (IPv6 `2607:5300:205:200::b755`).
`hosts/koi.nix` defines its hardware, provider network, disko layout, and base
services. IPv4 uses DHCP on `ens3`; IPv6 has a static address and an on-link
gateway. The VPS boots with BIOS GRUB; an ESP also supports removable UEFI boot.

The 40 GiB `/dev/sda` contains a BIOS boot partition, a 1 GiB ESP, and Btrfs
labelled `koi-btrfs`. The Btrfs subvolumes are `root`, `home`, `nix`, and
`persist`. Disko creates a read-only `blank` snapshot before installing NixOS.
The initrd restores `root` from `blank` on each boot, following the same pattern
as `sci`. `/home`, `/nix`, and `/persist` survive. Root's home, SSH host keys,
machine ID, NixOS/systemd state, Tailscale identity, and logs are persisted.

Rollback refuses to delete root if the blank snapshot is invalid or the
persistent ED25519 host key is missing. Choose GRUB's `no-rollback`
specialisation (or append `impermanence.disable=1` to the kernel command line)
for recovery. New service state must be added to `environment.persistence`.

SSH accepts the existing homelab key for `root` and `sciyoshi`; password login
is disabled. `sciyoshi` has passwordless sudo. Tailscale is enabled with manual
enrollment; run `sudo tailscale up` once and follow its login URL. Its identity
survives reboots. The base installation does not enable k3s or require SOPS
secrets. Before adding encrypted secrets, add koi's host-derived age recipient
to `.sops.yaml` and run `sops updatekeys secrets.yaml` locally.

For a fresh installation, first inspect the target disk and network, authorize
the homelab SSH key, and complete any provider-mandated password change. Keep
the temporary password outside Git (`passwd` is ignored). Stage the SSH host
keys and machine ID in a private directory with this layout:

```text
<extra-files>/persist/etc/ssh/ssh_host_ed25519_key{,.pub}
<extra-files>/persist/etc/ssh/ssh_host_rsa_key{,.pub}
<extra-files>/persist/etc/machine-id
```

Validate and build, then install with
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md):

```sh
nix flake check --no-build
nix build .#nixosConfigurations.koi.config.system.build.toplevel
# Destructive: repartitions /dev/sda on the target VPS.
nix run github:nix-community/nixos-anywhere -- \
  --flake .#koi --target-host debian@149.56.135.22 \
  --extra-files <extra-files>
```

Keep the homelab key available through `ssh-agent`. Nixos-anywhere generates
its own temporary installation key; passing an encrypted private key with
`-i` instead requires its passphrase separately.

After installation, verify SSH access, `systemctl --failed`, and mounts for
`/`, `/home`, `/nix`, and `/persist`. Reboot with disposable marker files in
root and persistent storage to check that root resets and persistent state
survives. Future updates use `deploy .#koi`, after reviewing the configuration.

Installed and reboot-tested on 2026-11-17: the root marker disappeared while
markers in `/persist`, `/home`, `/nix`, and `/root` survived; machine ID and SSH
host identity were unchanged. IPv4/IPv6 Internet connectivity and passwordless
sudo were verified, with no failed services. The original installation checkout
is retained at `/home/sciyoshi/.homelab`; use `~/.setup` for the Comin workflow below.

### Comin on koi

Only koi runs [Comin](https://github.com/nlewo/comin). Both remotes use Comin's
default branches: `main` and `testing-koi`. Comin fetches GitHub every 300 seconds
and switches successful builds from `main` automatically, including
the next boot's configuration. No GitHub credentials are needed for this public
repository. Its repository, deployment history, and state live in
`/var/lib/comin`, persisted under `/persist`.

`/home/sciyoshi/.setup` is a separate editable checkout, owned by sciyoshi and
already persistent under `/home`. Comin polls it every 5 seconds. Commits on its
`testing-koi` branch take precedence while based on the latest `main` commit.
If there is no eligible local test, Comin checks GitHub's `testing-koi` branch,
then falls back to `main`. Testing branches activate with `test`, leaving the
boot default unchanged. Unsaved
or uncommitted edits do not deploy; switching the checkout's current branch does
not disable an existing `testing-koi` override. Comin fetches into its own
repository and never pulls, rebases, or overwrites this working tree.
If `~/.setup` is absent, Comin logs local fetch failures and uses the GitHub
remote; it does not create the checkout.

To edit on koi:

```sh
cd ~/.setup
git fetch origin
git switch testing-koi
git rebase origin/main
# Edit hosts/koi.nix, format, and validate before committing.
nixfmt hosts/koi.nix
sudo systemd-run --scope -p MemoryMax=2G -p MemorySwapMax=256M \
  nix eval --raw .#nixosConfigurations.koi.config.system.build.toplevel.drvPath
git add hosts/koi.nix
git commit -m 'feat(koi): describe the local change'
# Comin picks up the commit automatically; no push needed.
comin status
journalctl -u comin -f
```

Run the full `nix flake check --no-build` on the editing workstation, not this
4 GiB VPS: evaluating every host can exhaust its memory. Comin's service has a
2 GiB memory limit and 256 MiB swap limit to bound its own evaluations. These
limits do not cover builds performed separately by `nix-daemon`.

Upstream advancement can supersede a local testing branch; rebase the local
branch to test it again. Keep the local `main` branch as a clean
upstream baseline and make local changes on `testing-koi`. To return to upstream
while preserving the local experiment (start with a clean working tree):

```sh
cd ~/.setup
git fetch origin
git branch saved-koi-experiment testing-koi
git switch main
git merge --ff-only origin/main
git branch -f testing-koi origin/main
sudo systemctl restart comin
```

Use a fresh backup branch name each time. Reset the testing ref to the baseline
rather than deleting it: Comin's fetched refs can outlive deleted remote branches.
If GitHub's `testing-koi` has additional eligible commits, it will take over
instead; returning to `main` requires resetting that remote testing branch to
`main` too, after preserving any wanted work.
The restart works around a behavior observed with the pinned Comin 0.14.0:
after a local test, selecting an upstream commit that produces an earlier
system store path can be skipped as "already deployed", leaving the test
configuration active. Restarting Comin makes it compare against the active
deployment and reapply upstream. Check `comin status` and `/run/current-system`
after returning from a test. Resolve this behavior before expanding the rollout.
`comin fetch` requests an immediate fetch; `comin suspend` / `comin resume` pause
and resume builds and deployments. Before manual rebuilds or deploy-rs updates,
suspend Comin so the two deployers do not race. The local checkout is trusted
configuration that Comin activates as root; sciyoshi already has passwordless
sudo on this machine.

Push regular deployment changes to `main`. To test from another machine, push
commits based on the latest `main` to GitHub's `testing-koi`; an eligible local
testing branch still takes precedence. Other hosts retain their existing
deployment workflows.

Trial validation on 2026-11-17: local `testing-koi` commits were fetched and
activated with `test`, with the GRUB configuration unchanged. The five-minute
GitHub poll fetched and evaluated a newer upstream commit; this exposed the
already-deployed-path behavior above. The local smoke-test commit is saved on
`comin-smoke-test-2026-11-17` in koi's checkout.
