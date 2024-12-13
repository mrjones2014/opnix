{ lib, pkgs, config, ... }:
with lib;
let
  inherit (import ./types.nix {
    inherit lib;
    inherit config;
  })
    secretFileDeclaration;
in {
  options.opnix = {
    opBin = mkOption {
      type = types.str;
      default = "${pkgs._1password-cli}/bin/op";
      description = "The 1Password CLI `op` executable to use";
    };
    environmentFile = mkOption {
      type = types.str;
      description = ''
        Path to a environment file which contains your service account token. Format should be `OP_SERVICE_ACCOUNT_TOKEN="{ your token here }"`. This is used to authorize the 1Password CLI.'';
    };
    secretsDir = mkOption {
      type = types.path;
      default = "/run/opnix";
      description = ''
        Directory where secrets are symlinked to
      '';
    };
    secretsMountPoint = mkOption {
      type = types.addCheck types.str (s:
        (trim s) != "" # non-empty
        && (builtins.match ".+/" s) == null) # without trailing slash
        // {
          description =
            "${types.str.description} (with check: non-empty without trailing slash)";
        };
      default = "/run/opnix.d";
    };
    secrets = mkOption {
      type = types.attrsOf secretFileDeclaration;
      description = "The secrets you want to use in your NixOS deployment";
      default = { };
      example = {
        my-secret = {
          source = "{{ op://VaultName/ItemName/FieldName }}";
          mode = "0400";
          inherit (config.services.some_service) user;
          inherit (config.services.some_service) group;
        };
        another-secret.source = ''
          [SomeTomlHeader]
          SomeValue = "{{ op://AnotherVault/AnotherItem/AnotherField }}"
        '';
      };
    };
    debug = mkOption {
      type = types.bool;
      description = "Whether to enable debug logs";
      default = false;
    };
  };
}
