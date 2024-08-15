{ lib, pkgs, config, ... }:
with lib;
let
  inherit (import ./types.nix {
    inherit lib;
    inherit config;
  })
    secretFileDeclaration;
  cfg = config.opnix;
  scripts = import ./scripts.nix {
    inherit lib;
    inherit config pkgs;
  };
in {
  options.opnix = {
    opBin = mkOption {
      type = types.str;
      default = "${pkgs._1password}/bin/op";
      description = "The 1Password CLI `op` executable to use";
    };
    environmentFile = mkOption {
      type = types.str;
      description = ''
        Path to a environment file which contains your service account token. Format should be `OP_SERVICE_ACCOUNT_TOKEN="{ your token here }"`. This is used to authorize the 1Password CLI in the systemd job.'';
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
    systemdWantedBy = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of `systemd` service names that depend on secrets from `opnix`. This option will set `after = [ "opnix.service" ]` and `wants = [ "opnix.service" ]` for each specified `systemd` unit.'';
      example = [ "homepage-dashboard" "wg-quick-vpn" ];
    };
  };
  config = let
    opnixScript = ''
      ${scripts.installSecrets}
      ${scripts.chownSecrets}
    '';
  in mkIf (cfg.secrets != { }) (mkMerge [
    {
      systemd.services.opnix = {
        wants = [ "network-online.target" ];
        after = [ "network.target" "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = cfg.environmentFile;
          ExecReload = opnixScript;
        };

        script = opnixScript;
      };
    }
    {
      systemd.services = builtins.listToAttrs (builtins.map (systemdName: {
        name = systemdName;
        value = {
          after = [ "opnix.service" ];
          wants = [ "opnix.service" ];
        };
      }) cfg.systemdWantedBy);
    }
  ]);
}
