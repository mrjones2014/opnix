toplevel @ {
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.opnix;
  scripts = import ./scripts.nix toplevel;
in {
  imports = [./common.nix];

  options.opnix = {
    systemdWantedBy = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        A list of `systemd` service names that depend on secrets from `opnix`. This option will set `after = [ "opnix.service" ]` and `wants = [ "opnix.service" ]` for each specified `systemd` unit.'';
      example = ["homepage-dashboard" "wg-quick-vpn"];
    };
  };

  config = let
    opnixScript = ''
      ${scripts.installSecrets}
      ${scripts.chownSecrets}
    '';
  in
    mkIf (cfg.secrets != {}) (mkMerge [
      {
        systemd.services.opnix = {
          wants = ["network-online.target"];
          after = ["network.target" "network-online.target"];

          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = cfg.environmentFile;
            RemainAfterExit = true;
          };

          script = opnixScript;
        };
      }
      {
        system.activationScripts.opnix-on-rebuild = {
          # if no generation already exists, rely on the systemd startup job;
          # otherwise, if there already is an existing generation, reprovision
          # secrets because we did a nixos-rebuild
          text = ''
            ${scripts.setOpnixGeneration}
            (( _opnix_generation > 1 )) && {
            source ${cfg.environmentFile}
            export OP_SERVICE_ACCOUNT_TOKEN
            ${opnixScript}
            }
          '';
          deps = ["usrbinenv"];
        };
      }
      {
        systemd.services = builtins.listToAttrs (builtins.map (systemdName: {
            name = systemdName;
            value = {
              after = ["opnix.service"];
              wants = ["opnix.service"];
            };
          })
          cfg.systemdWantedBy);
      }
    ]);
}
