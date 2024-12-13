{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils = { url = "github:numtide/flake-utils"; };
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "shell with justfile CLI";

          packages = with pkgs; [ just ];
        };

      }) // {
        darwinModules.default = import ./modules/darwin.nix;
        nixosModules.default = import ./modules/nixos.nix;

        # test is a hostname for our machine
        nixosConfigurations.test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules =
            [ ./modules/op-secrets.nix ./test-nix-files/configuration.nix ];
        };
      };
}
