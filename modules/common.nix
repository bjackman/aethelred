{ pkgs, config, ... }:
{
  # I don't really understand this, how to best set it for new installs is a
  # mystery to me.
  system.stateVersion = "24.11";

  boot = {
    loader.timeout = 2; # enspeeden tha boot

    tmp.useTmpfs = true;
  };

  system.nixos.label = let
      rev = config.system.configurationRevision;
      shortRev = if rev != null then builtins.substring 0 7 rev else "dirty";
    in
    "flake-${shortRev}";

  nix.settings.require-sigs = false;
}
