{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    kernel-guest_memfd-physmap = {
      # https://lore.kernel.org/all/20250924151101.2225820-1-patrick.roy@campus.lmu.de/
      url = "github:bjackman/linux?ref=review/patrick-guest_memfd-physmap";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixfmt-tree;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nixos-rebuild ];
        };
      }
    )
    // flake-utils.lib.eachDefaultSystemPassThrough (system: {
      nixosConfigurations.aethelred = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/aethelred.nix
          {
            # Useful for poking around for experiments
            nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable;
            nixpkgs.overlays = [ self.overlays.guest_memfd-physmap ];
          }
        ];
      };

      overlays.guest_memfd-physmap = (
        final: prev: {
          linuxPackages_guest_memfd-physmap = prev.linuxPackages_custom {
            version = "6.17-rc7";
            src = inputs.kernel-guest_memfd-physmap;
            configfile = kconfigs/v6.16_nix_based_asi.config;
          };
        }
      );
    });
}
