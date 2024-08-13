{
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };

  outputs = { nixpkgs, ... }:
    let system = "x86_64-linux";
    in {
      # test is a hostname for our machine
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ../modules/op-secrets.nix ./configuration.nix ];
      };
    };
}
