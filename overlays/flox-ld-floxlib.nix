flox: _: prev: {
  ld-floxlib = prev.ld-floxlib.overrideAttrs (_: {
    # Work around https://github.com/flox/flox/issues/4775.
    # Upstream interpolates a path before passing it to builtins.path, creating
    # an intermediate store copy that `nix flake check --no-build` cannot read
    # unless a previous evaluation materialized it. Use the input source directly.
    src = builtins.path {
      name = "ld-floxlib-src";
      path = flox.outPath + "/ld-floxlib";
    };
  });
}
