{
  pkgs,
  lib,
  specialArgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  codexAcp = specialArgs.inputs.nix-ai-tools.packages.${system}.codex-acp;
in
{
  home.packages = [
    codexAcp
  ];

  home.activation.linkCodexAcpForZed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_acp="${codexAcp}/bin/codex-acp"

    for agent_root in "$HOME/.local/share/zed/external_agents/codex" "$HOME/.local/share/zed-preview/external_agents/codex"; do
      if [ -d "$agent_root" ]; then
        for version_dir in "$agent_root"/*; do
          if [ -d "$version_dir" ]; then
            $DRY_RUN_CMD ln -sfn "$codex_acp" "$version_dir/codex-acp"
          fi
        done
      fi
    done
  '';
}
