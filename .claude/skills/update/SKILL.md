---
name: update
description: Update flake inputs (nixpkgs, flox, etc.) and verify the resulting config still evaluates and builds for affected hosts. Use when the user says "update the flake", "bump nixpkgs", "update inputs", or similar.
---

# Update flake inputs

Personal homelab flake. Hosts are defined in `nix/darwin.nix` and
`nix/nixos.nix`. The goal of an "update" is:

1. Bump `flake.lock` (all inputs, or a named one).
2. Confirm the flake still evaluates.
3. Confirm affected hosts still build (at least the laptop — `fellow-sci`).
4. Commit with a conventional-commits message.

## Steps

### 1. Find out what the user wants bumped

If they said "update the flake" with no specifics, bump everything:

```sh
nix flake update
```

If they named an input (e.g. "bump nixpkgs", "update flox"):

```sh
nix flake update <input-name>
```

Input names come from `flake.nix` — current set: `nixpkgs`, `sops-nix`,
`impermanence`, `flake-utils`, `nixos-hardware`, `determinate`, `home-manager`,
`deploy-rs`, `darwin`, `flox`, `nix-ai-tools`.

### 2. See what actually changed

```sh
git diff flake.lock
```

Note which inputs moved. If the diff is huge (which it usually is), pull the
notable revs:

```sh
git diff flake.lock | grep -E '^\+.*"(rev|ref)":' | head -40
```

### 3. Verify the flake still evaluates

```sh
nix flake check --no-build
```

`--no-build` keeps this fast (seconds, not minutes). It catches eval errors
across all hosts, which is what most bumps break.

### 4. Build the laptop config

This is the host I'm on, so it's the cheapest full build:

```sh
nix build .#darwinConfigurations.fellow-sci.system
```

If the user named a specific host that's affected, build that too:

```sh
# NixOS hosts:
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Do **not** `darwin-rebuild switch` or `deploy` as part of an update — that's
the `deploy` skill and requires user sign-off.

### 5. Report back before committing

Summarize:

- Which inputs moved (name, short old rev → new rev).
- Whether `flake check` passed.
- Whether `fellow-sci` built.
- Anything that broke and how you handled it (or didn't).

Then ask whether to commit.

### 6. Commit

Conventional commits, `chore` type:

```sh
git add flake.lock
git commit -m "chore: flake update"
```

For a single-input bump:

```sh
git commit -m "chore(flake): bump nixpkgs"
```

If the bump required fixing something (e.g. a removed option, renamed
attribute), commit the fix separately with `fix(...):` first, then the lock
bump.

## If something breaks

- **Eval error referencing a removed option:** check the input's release notes
  / changelog. For nixpkgs, options often get renamed or removed between
  releases — search the diff for `mkRemovedOptionModule` mentions.
- **Build failure in a package:** pin the old rev of that input, or add the
  package to `permittedInsecurePackages` / overlay the older version. Don't
  just mask the error.
- **Insecure package warning:** if it's legit (we knowingly need it), add to
  `nixpkgs.config.permittedInsecurePackages`. Otherwise, fix the root cause.

Never `--no-verify` a commit or skip `flake check` to make a red build green.
