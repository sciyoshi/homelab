# AGENTS.md

Personal Nix homelab config. This is a public repo, but it is for my machines
only. Prioritize making it easy for me and future agents to change safely, not
onboarding strangers.

The human-facing runbook lives in `README.md`. This file is for agents: current
layout, conventions, commands, and operational boundaries.

The repo is normally checked out at `~/.homelab`; newer machines may use
`~/.setup`. Hosts keep local checkouts so quick local `nixos-rebuild` or
`darwin-rebuild` testing stays possible even though the long-term goal is
centralized automation and daily deployment.

## Current Operating Model

- Most editing and automation happens from `fellow-sci` or `sci`.
- `fellow-sci` is the Mac laptop and currently runs Claude automation that keeps
  flakes up to date and switches Darwin locally.
- `sci` is the home Linux desktop and has the better GPU for ML workloads.
- `scilo` is the home Linux server, usually accessed over SSH for persistent
  services or server-side work.
- `alpha`, `beta`, and `gamma` are OVH NixOS hosts.
- `misaki` is a Raspberry Pi in Montreal used as a borg backup target.
- `scipi4` likely died and is probably unused now; Home Assistant moved off it.
- `homeConfigurations.sciyoshi` is intentional: it is the standalone Home
  Manager profile for Ubuntu/WSL2 VMs, not an orphaned host.

The desired direction is centralized automation/editing, daily deployment to
remote hosts, quick local test switches where useful, and easy rollback through
Nix generations and deploy tooling.

## Layout

```text
flake.nix                  # inputs + outputs dispatcher
darwin-configuration.nix   # fellow-sci nix-darwin config
nix/
  darwin.nix               # darwinConfigurations = { fellow-sci = ...; }
  nixos.nix                # nixosConfigurations
  home-manager.nix         # standalone HM for Ubuntu/WSL2 VMs
  deploy.nix               # deploy-rs nodes, hostnames + ssh users
  shell.nix                # devShell
  sd-utils/                # custom sd-image module for misaki
hosts/                     # per-NixOS-host entrypoints for alpha/beta/gamma/misaki/scipi4/scilo
nixos/                     # shared NixOS modules and service configs
sci/                       # home Linux desktop config + hardware
scilo/                     # home Linux server config + hardware
home/                      # Home Manager modules shared across hosts/profiles
overlays/                  # custom package overlays
k3s/                       # Kubernetes-side config artifacts
secrets.yaml               # sops-encrypted, age + pgp
.sops.yaml                 # recipients
scripts/                   # one-off shell scripts
```

Hosts and outputs:

| Name | Platform | Role |
| --- | --- | --- |
| `fellow-sci` | `aarch64-darwin` | Work laptop, nix-darwin + Home Manager + Homebrew |
| `sci` | `x86_64-linux` | Home desktop, niri/hyprland, Nvidia GPU, ML workloads |
| `scilo` | `x86_64-linux` | Home server, persistent services, backups, home automation, media |
| `alpha` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `beta` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `gamma` | `x86_64-linux` | OVH VPS, k3s agent, impermanent tmpfs root |
| `misaki` | `aarch64-linux` | Montreal Raspberry Pi, borg backup target |
| `scipi4` | `aarch64-linux` | Old/dead Raspberry Pi config; likely unused |
| `sciyoshi` | `x86_64-linux` | Standalone Home Manager output for Ubuntu/WSL2 VMs |

## Conventions

### Commits

Use Conventional Commits.

Types:

- `feat` — new host, new module, new service
- `fix` — bug fix, broken build, wrong config
- `chore` — flake lock bumps, housekeeping, no behavior change
- `refactor` — moving things without changing behavior
- `docs` — README / AGENTS.md

Useful examples:

- `feat(scilo): enable jackett`
- `fix(immich): bump memory limit`
- `chore: flake update`
- `chore(flake): bump flox to 1.11.2`
- `feat(darwin): add obsidian cask`

Keep the subject <=72 chars, imperative mood, no trailing period. Add a body
when the why is not obvious from the diff.

### Nix Style

- Formatter is `nixfmt` from nixpkgs. Run it on any Nix file you touch.
- Prefer extending existing modules over creating new top-level files.
- Keep host-specific configuration in the existing host files unless the user has
  asked for a layout refactor.
- Shared NixOS bits go in `nixos/`; shared Home Manager bits go in `home/`.
- If a package needs an overlay, put it under `overlays/` and wire it into the
  host that needs it. Do not make overlays global by default.
- Do not remove `cache.flox.dev` from trusted substituters.
- On Darwin, `determinateNix.enable = true`; do not add a second Nix install
  manager.

### Secrets

`secrets.yaml` is sops-encrypted. Recipients live in `.sops.yaml`.

Host age keys are derived from:

```text
/etc/ssh/ssh_host_ed25519_key
```

New hosts need their public key added to `.sops.yaml`, then:

```sh
sops updatekeys secrets.yaml
```

Never commit plaintext secrets. Never ask for the sops passphrase; let the user
run sops commands.

## Common Commands

Assume the dev shell is available through `nix develop` or direnv.

Format Nix files:

```sh
nixfmt <files...>
```

Evaluate the flake:

```sh
nix flake check --no-build
nix flake check
```

Update flake inputs:

```sh
nix flake update
nix flake update <input-name>
```

Build one NixOS host:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Build Darwin:

```sh
nix build .#darwinConfigurations.fellow-sci.system
```

Switch local NixOS from the local checkout:

```sh
sudo nixos-rebuild switch --flake ~/.homelab#<host>
sudo nixos-rebuild switch --flake ~/.setup#<host>
```

Switch Darwin:

```sh
sudo darwin-rebuild switch --flake ~/.homelab#fellow-sci
```

Standalone Home Manager for Ubuntu/WSL2:

```sh
home-manager switch --flake ~/.homelab#sciyoshi
```

Remote deploy with deploy-rs:

```sh
deploy .#<host>
deploy .
```

`autoRollback = false; magicRollback = true` in `nix/deploy.nix`. Deploy-rs has
been troublesome, so do not assume it is final. Colmena and
`nixos-rebuild --target-host` are plausible alternatives.

## Before Finishing A Change

1. `nixfmt` any Nix files you edited.
2. Run `nix flake check --no-build` at minimum.
3. For a host change, build that host's toplevel, or the Darwin equivalent.
4. Stage only the files you meant to touch. `flake.lock` often tags along; call
   it out if it does.
5. Commit with a conventional-commits message if the user asked for a commit.

Do not deploy remote hosts or run `darwin-rebuild switch` / `nixos-rebuild
switch` without explicit user approval. Those are side-effectful and the user
wants to eyeball diffs first.

## Gotchas

- `misaki` and `scipi4` are `aarch64-linux`; cross-building from `x86_64-linux`
  needs binfmt or a remote builder.
- `scilo` has `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` so it can
  cross-build for Raspberry Pi hosts.
- `scipi4` is likely stale/dead. Do not spend time preserving it unless the user
  asks or the change explicitly concerns retired host cleanup.
- OVH hosts use tmpfs root plus `/persist`; anything that must survive reboot
  needs to be in `environment.persistence`.
- `k3s/traefik-config.yaml` is a Kubernetes-side artifact outside the Nix module
  graph.
- This repo has local uncommitted work sometimes. Never revert user changes you
  did not make.
