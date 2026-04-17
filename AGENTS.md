# AGENTS.md

Personal Nix homelab config — one Mac laptop (`fellow-sci`), a desktop (`sci`),
and a handful of NixOS servers. Public repo, but for my use only, so prioritize
making it easy for me (and you) to change things, not onboarding strangers.

The human-facing bootstrap notes live in `README.md` (OSX install, OVH
install, cross-arch binfmt setup). This file is for agents: layout, conventions,
and the commands you'll actually run.

## Layout

```
flake.nix              # inputs + outputs dispatcher
darwin-configuration.nix   # the one Darwin host (fellow-sci)
nix/
  darwin.nix           # darwinConfigurations = { fellow-sci = ...; }
  nixos.nix            # nixosConfigurations = { alpha, beta, gamma, scilo, sci, scipi4, misaki }
  home-manager.nix     # standalone HM for linux non-NixOS
  deploy.nix           # deploy-rs nodes, hostnames + ssh users
  shell.nix            # devShell (nix, home-manager, deploy-rs, sops, age, gnupg)
  sd-utils/            # custom sd-image module for misaki
hosts/                 # per-NixOS-host entrypoints (import ../nixos/configuration.nix + overrides)
nixos/                 # shared NixOS modules (common, tailscale, openssh, immich, frigate, etc.)
sci/                   # desktop (full NixOS install, not a server) — own configuration.nix + hardware
scilo/                 # home server (same shape as sci/)
home/                  # home-manager modules shared across hosts
overlays/              # custom package overlays (filebot, rumqttd, zigbee2mqtt, pgvecto-rs)
secrets.yaml           # sops-encrypted, age + pgp
.sops.yaml             # recipients
scripts/               # one-off shell scripts
```

Hosts and their roles:

| Host        | Platform        | Role                                                |
| ----------- | --------------- | --------------------------------------------------- |
| `fellow-sci`| aarch64-darwin  | Work laptop (nix-darwin + home-manager + homebrew)  |
| `sci`       | x86_64-linux    | Personal desktop (NixOS, niri/hyprland, nvidia)     |
| `scilo`     | x86_64-linux    | Home server (jellyfin, immich, vaultwarden, ha)     |
| `alpha/beta/gamma` | x86_64-linux  | OVH VPSes (k3s agents, impermanent tmpfs root) |
| `scipi4`    | aarch64-linux   | Pi 4, zigbee2mqtt + home assistant                  |
| `misaki`    | aarch64-linux   | Pi 4 in Montreal, borg backup target                |

## Conventions

### Commits — conventional commits

Going forward, use [Conventional Commits](https://www.conventionalcommits.org/).
Types I use:

- `feat` — new host, new module, new service
- `fix` — bug fix / broken build / wrong config
- `chore` — flake lock bumps, housekeeping, no behavior change
- `refactor` — moving things without changing behavior
- `docs` — README / AGENTS.md

Scope when it adds signal (usually host or module name):

- `feat(scilo): enable jackett`
- `fix(immich): bump memory limit`
- `chore: flake update`
- `chore(flake): bump flox to 1.11.2`
- `feat(darwin): add obsidian cask`

Keep subject ≤72 chars, imperative mood, no trailing period. Body optional —
add one when the *why* isn't obvious from the diff.

### Nix style

- Formatter is `nixfmt` (RFC style, the one in nixpkgs). Run it on any file you
  touch. It's in the devShell and in `darwin-configuration.nix`.
- Prefer extending existing modules over creating new top-level files.
- Host-specific stuff goes in `hosts/<name>.nix` (or `sci/`, `scilo/` for
  full-desktop/server setups). Shared NixOS bits go in `nixos/`. Shared
  home-manager bits go in `home/`.
- When adding a package that needs an overlay, put it under `overlays/` and
  wire it into the host that needs it, not globally.

### Secrets

`secrets.yaml` is sops-encrypted (age + pgp). Recipients in `.sops.yaml`. Host
age keys are derived from `/etc/ssh/ssh_host_ed25519_key` — new hosts need
their pubkey added to `.sops.yaml` and `secrets.yaml` re-encrypted
(`sops updatekeys secrets.yaml`).

Never commit plaintext secrets. Never ask for the sops passphrase — let me
run sops commands myself.

## Common commands

All of these assume you're in the devShell (`nix develop` or via direnv,
`.envrc` is set up).

**Format Nix files:**

```sh
nixfmt <files...>
```

**Check the flake evaluates:**

```sh
nix flake check --no-build   # evaluation only, fast
nix flake check              # also builds deploy checks — slow
```

**Update flake inputs:**

```sh
nix flake update                 # all inputs
nix flake update <input-name>    # one input (e.g. nixpkgs, flox)
```

**Darwin (this laptop):**

```sh
# Build only (no activation):
nix build .#darwinConfigurations.fellow-sci.system

# Switch:
sudo darwin-rebuild switch --flake .
```

**NixOS remote hosts (deploy-rs):**

```sh
# Deploy one host (safer — magic rollback on failure):
deploy .#<host>

# Deploy all:
deploy .

# Dry-run / build without activating:
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

`autoRollback = false; magicRollback = true` in `nix/deploy.nix` — so a broken
deploy rolls itself back once the SSH check fails, but we don't fight
activation rollbacks.

**Home-manager standalone (non-NixOS linux):**

```sh
home-manager switch --flake .#sciyoshi
```

## Before finishing a change

1. `nixfmt` any files you edited.
2. `nix flake check --no-build` at minimum.
3. For a host change, build that host's toplevel (`nix build
   .#nixosConfigurations.<host>.config.system.build.toplevel` or the darwin
   equivalent) to catch eval + build errors before trying to activate.
4. Stage only the files you meant to touch (`flake.lock` often tags along — that's
   fine, but call it out in the commit).
5. Commit with a conventional-commits message.

Do **not** deploy remote hosts or `darwin-rebuild switch` without my say-so —
those are side-effectful and I want to eyeball the diff first.

## Gotchas

- `misaki` and `scipi4` are aarch64; cross-building from x86_64 needs the
  binfmt setup in `README.md`. From `fellow-sci` (aarch64 Darwin), misaki can
  build natively but you still need a linux-builder or remote builder.
- `scilo` has `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` so it can
  cross-build for the Pis.
- Flox's cache (`cache.flox.dev`) is in trusted substituters on every host;
  keep it there when touching nix settings.
- `determinate.enable = true` on Darwin — do NOT layer a second nix install
  manager on top.
- OVH hosts (`alpha`, `beta`, `gamma`) use tmpfs root + `/persist` —
  anything that needs to survive a reboot has to be in
  `environment.persistence`.
