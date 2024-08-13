{
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };
  outputs = { nixpkgs, ... }:
    let system = "x86_64-linux";
    in {
      nixosModules.default = import ./modules/op-secrets.nix;

      # test is a hostname for our machine
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          [ ./modules/op-secrets.nix ./test-nix-files/configuration.nix ];
      };
    };
}
