---
name: deploy
description: Deploy this flake to a host — `darwin-rebuild switch` for the laptop, or `deploy-rs` for NixOS servers. Use when the user says "deploy", "switch", "activate", "push to <host>", or similar.
---

# Deploy

This repo drives:

- **One Darwin host** (`fellow-sci`, the laptop) — activated with `darwin-rebuild switch`.
- **Six NixOS hosts** (`alpha`, `beta`, `gamma`, `scilo`, `scipi4`, `misaki`) — activated with `deploy-rs`.
- The **`sci` desktop** — full NixOS install, usually activated locally with `nixos-rebuild switch` while sitting at the machine. Not in the deploy-rs node list.

Deploys are side-effectful and touch remote systems. **Always confirm with
the user before activating.** Build first, surface the diff, then deploy.

## Pre-flight (always)

1. Check git state — clean or obvious about uncommitted changes:
   ```sh
   git status
   git diff
   ```
2. Evaluate the flake:
   ```sh
   nix flake check --no-build
   ```
3. Confirm which host(s). If ambiguous, ask.

## Darwin: `fellow-sci`

```sh
# Build first, so eval + build errors surface before activation:
nix build .#darwinConfigurations.fellow-sci.system

# Then switch (needs sudo):
sudo darwin-rebuild switch --flake .
```

After activation, a quick sanity check:

```sh
darwin-rebuild --list-generations | tail -3
```

If something goes wrong, roll back:

```sh
sudo darwin-rebuild switch --rollback
```

## NixOS via deploy-rs

`nix/deploy.nix` defines the nodes. Current hostnames/IPs:

| Node     | Address                      | Arch         |
| -------- | ---------------------------- | ------------ |
| alpha    | `alpha.sciyoshi.com`         | x86_64-linux |
| beta     | `beta.sciyoshi.com`          | x86_64-linux |
| gamma    | `gamma.sciyoshi.com`         | x86_64-linux |
| scilo    | `100.114.10.116` (tailscale) | x86_64-linux |
| scipi4   | `100.69.198.147` (tailscale) | aarch64-linux |
| misaki   | `100.119.209.24` (tailscale) | aarch64-linux |

SSH user is `root` for all of them. The tailscale-addressed hosts need the
tailnet to be up.

### Deploy one host

```sh
deploy .#<host>
```

e.g. `deploy .#scilo`. Prefer this over deploying all of them — smaller blast
radius.

### Dry-build first

For hosts where a failed activation is expensive (anything running services
people use — scilo, scipi4, misaki), build the toplevel on the local machine
first to catch errors:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

For aarch64 hosts from an x86_64 builder, this needs binfmt or a remote
builder. From `fellow-sci` (aarch64-darwin) you'd want a remote linux builder
or let deploy-rs build on the target itself (default behavior).

### Deploy-rs safety behavior

From `nix/deploy.nix`:

- `magicRollback = true` — after activation, deploy-rs waits for an SSH
  confirmation. If the host becomes unreachable (e.g. you broke networking),
  it rolls back automatically.
- `autoRollback = false` — a successful activation that *stays reachable* won't
  be rolled back even if something else is broken. Watch services after
  deploy.

### Deploy all hosts

```sh
deploy .
```

Only when the change is broad (e.g. shared module in `nixos/`). Warn the user
before doing this.

## sci (desktop) — local activation

This one isn't in deploy-rs. When working on `sci/configuration.nix`, the
expected flow is activating locally on the desktop:

```sh
# On the sci machine:
sudo nixos-rebuild switch --flake .#sci
```

If the user asks to "deploy sci" from the laptop, confirm — they might mean
build-test it here, not push it remotely. There's no deploy-rs wiring for it.

## After a deploy

- Spot-check the service(s) that were touched (e.g. `systemctl status <svc>`
  over SSH).
- If the change added/removed a sops secret, verify it decrypted
  (`systemctl status sops-nix.service` on the host).
- Commit any follow-up fixes separately with `fix(<host>):` prefix.

## What NOT to do

- Don't `deploy` without the user's explicit go-ahead.
- Don't deploy with uncommitted changes unless the user said "yes I know, just
  push it".
- Don't `--skip-checks` or `deploy -s` to bypass a failing flake check.
- Don't force-push or rewrite history on `main` to clean up a botched deploy —
  commit a fix forward.
