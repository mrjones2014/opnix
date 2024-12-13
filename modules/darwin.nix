toplevel @ {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkAfter
    mkIf
    mkMerge
    ;

  cfg = config.opnix;
  scripts = import ./scripts.nix toplevel;
in {
  imports = [./common.nix];

  config = let
    opnixScript = ''
      ${scripts.installSecrets}
      ${scripts.chownSecrets}
    '';
  in
    mkIf (cfg.secrets != {}) (mkMerge [
      {
        launchd.daemons.activate-opnix = {
          script = ''
            set -euo pipefail
            export PATH="${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:@out@/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            source ${cfg.environmentFile}
            export OP_SERVICE_ACCOUNT_TOKEN
            ${opnixScript}
          '';
          serviceConfig = {
            RunAtLoad = true;
            KeepAlive.SuccessfulExit = false;
          };
        };
      }
      {
        system.activationScripts = {
          # if no generation already exists, rely on the launchd startup job;
          # otherwise, if there already is an existing generation, reprovision
          # secrets because we did a darwin-rebuild
          preActivation.text = ''
            ${scripts.setOpnixGeneration}
            (( _opnix_generation > 1 )) && {
            # shellcheck disable=SC1091
            source ${cfg.environmentFile}
            export OP_SERVICE_ACCOUNT_TOKEN
            ${scripts.installSecrets}
            }
          '';

          users.text = mkAfter ''
            ${scripts.setOpnixGeneration}
            (( _opnix_generation > 1 )) && {
            ${scripts.chownSecrets}
            }
          '';
        };
      }
    ]);
}
