nix-ai-tools: final: prev: {
  # Upstream includes the macOS Finder bundle.
  herdr-app = nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.herdr-app;
}
