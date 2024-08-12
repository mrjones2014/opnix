{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # opnix = {
    #   url = "/home/ivan/code/op-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { nixpkgs, ... }:
    let system = "x86_64-linux";
    in {
      # test is a hostname for our machine
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          #opnix.nixosModules.default
          ../modules/op-secrets.nix
          ./configuration.nix
        ];
      };
    };
}
