{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./brendan.nix
    ./common.nix
    ./kernel.nix
    ./aethelred-hardware-configuration.nix
  ];
  networking.hostName = "aethelred";

  # For running Firecracker tests
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
