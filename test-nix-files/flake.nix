{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.opnix.url = "github:mrjones2014/op-nix";

  outputs = { nixpkgs, opnix, ... }:
    let system = "x86_64-linux";
    in {
      # test is a hostname for our machine
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ opnix.nixosModules.${system}.default ./configuration.nix ];
      };
    };
}
