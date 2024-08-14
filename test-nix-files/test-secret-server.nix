{ config, pkgs, ... }:
let
  service_user = "test-secret-server-user";
  service_group = "test-secret-server-group";
  port = 8080;
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
      # test-secret = {
      #   source = ''
      #     # You can put arbitrary configuration markup here, for example, TOML
      #     [Config]
      #     SecretValue = "{{ op://opnix testing/opnix test/password }}"
      #   '';
      #   # You can specify the Linux user who will be the file owner
      #   # for the generated secret file in the ramfs
      #   user = service_user;
      #   # You can specify the Linux user group that will own the file
      #   group = service_group;
      #   # You can specify the file mode (default 0400)
      #   mode = "0400";
      # };

      test-env = {
        source = ''
          MY_SECRET="{{ op://opnix testing/opnix test/password }}"
        '';
      };
      test-secret-2.source = ''
        # You can put arbitrary configuration markup here, for example, TOML
        [Config]
        SecretValue = "{{ op://opnix testing/opnix test/password }}"
      '';
    };
  };

  # For demo purposes, just use netcat to serve the secret file when you ping it with an HTTP GET
  systemd.services.mydemo = {
    serviceConfig = {
      EnvironmentFile = config.opnix.secrets.test-env.path;
      Type = "oneshot";
    };
    script = ''
      set -euo pipefail
      echo the secret is $MY_SECRET
      echo the path is ${config.opnix.secrets.test-env.path}
    '';
    wantedBy = [ "multi-user.target" ];
  };

  # systemd.services.test-secret-server = {
  #   enable = true;
  #   # here, `opnix.secrets.test-secret.path` is the path to the generated file in the ramfs
  #   # for demo purposes we'll just use netcat to serve the secret file over HTTP so we can fetch
  #   # the secret via `curl`
  #   script = ''
  #     while [[ 1 ]]
  #     do
  #       { echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c <${config.opnix.secrets.test-secret.path})\r\n\r\n"; cat ${config.opnix.secrets.test-secret.path}; } | ${pkgs.netcat}/bin/nc -l ${
  #         builtins.toString port
  #       }
  #     done
  #   '';
  #   serviceConfig = {
  #     User = service_user;
  #     Group = service_group;
  #   };
  #   # auto start
  #   wantedBy = [ "multi-user.target" ];
  # };
  # default port used by `serve` CLI
  networking.firewall.allowedTCPPorts = [ port ];
}
