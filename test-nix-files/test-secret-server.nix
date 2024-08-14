{ config, pkgs, ... }:
let
  service_user = "test-secret-server-user";
  service_group = "test-secret-server-group";
in {
  users.users.${service_user} = {
    isSystemUser = true;
    group = service_group;
  };
  users.groups.${service_group} = { };

  opnix = {
    environmentFile = "/etc/opnix.env";
    # specify the systemd service name of the service that will use the secret;
    # this makes the systemd service wait for secrets to be deployed on startup
    # before starting itself
    systemdWantedBy = [ "test-secret-server" ];
    secrets = {
      test-secret = {
        source = ''
          # You can put arbitrary configuration markup here, for example, TOML
          [Config]
          SecretValue = "{{ op://opnix testing/opnix test/password }}"
        '';
        # You can specify the Linux user who will be the file owner
        # for the generated secret file in the ramfs
        user = service_user;
        # You can specify the Linux user group that will own the file
        group = service_group;
        # You can specify the file mode (default 0400)
        mode = "0400";
      };
    };
  };

  # For demo purposes, just spin up a little web server that serves the secret files
  systemd.services.test-secret-server = {
    enable = true;
    # here, `opnix.secrets.test-secret.path` is the path to the generated file in the ramfs
    # we'll just use `basename` to run `serve` on the directory it's in
    script = ''
      echo "${config.opnix.secrets.test-secret.path}"
      ${pkgs.nodePackages_latest.serve}/bin/serve $(basename ${config.opnix.secrets.test-secret.path})
    '';
    # auto start
    wantedBy = [ "multi-user.target" ];
  };
  # default port used by `serve` CLI
  networking.firewall.allowedTCPPorts = [ 3000 ];
}
