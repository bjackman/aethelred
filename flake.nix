{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
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
          # Useful for poking around for experiments
          { nix.registry.nixpkgs-unstable.flake = nixpkgs-unstable; }
        ];
      };
    });
}
