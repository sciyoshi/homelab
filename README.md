# homelab

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
