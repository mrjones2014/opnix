{ lib, pkgs, ... }:
with lib;
let inherit (import ./types.nix) secretFileDeclaration;
in {
  options = {
    opBin = mkOption {
      type = types.str;
      default = "${pkgs._1password}/bin/op";
      description = "The 1Password CLI `op` executable to use";
    };
    secrets = mkOption {
      type = types.attrsOf secretFileDeclaration;
      description = "The secrets you want to use in your NixOS deployment";
      example = literalExpression ''
        {
          my-secret = {
            source = "op://VaultName/ItemName/FieldName";
            user = "SomeServiceUser";
            group = "SomeServiceGroup";
            mode = "0400";
          };
          another-secret.source = \'\'
            [SomeTomlHeader]
            SomeValue = "op://AnotherVault/AnotherItem/AnotherField"
          \'\';
        }
      '';
    };
  };
}
