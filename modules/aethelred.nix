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
}
