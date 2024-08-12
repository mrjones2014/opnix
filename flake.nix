{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "shell with nixos-shell CLI utility";

          packages = with pkgs; [ nixos-shell ];
        };

      }) // {
        nixosModules.default = import ./modules/op-secrets.nix;

        nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                # ./modules/op-secrets.nix
                ./vms/vm.nix
                # (
                #     { ... }: {
                #         nixpkgs.config.allowUnfree = true;
                #     }
                # )
            ];
        };
      };
}
