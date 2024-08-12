{ pkgs, ... }: {
  imports = [ ./homepage.nix ];
  environment.etc."op_service_account_token" = {
    text = ''
      ops_eyJzaWduSW5BZGRyZXNzIjoibXkuMXBhc3N3b3JkLmNvbSIsInVzZXJBdXRoIjp7Im1ldGhvZCI6IlNSUGctNDA5NiIsImFsZyI6IlBCRVMyZy1IUzI1NiIsIml0ZXJhdGlvbnMiOjY1MDAwMCwic2FsdCI6IlU4TGlJWWJxeTdZZUtVRmRSWUE5blEifSwiZW1haWwiOiJ5bzU1bnFmaGhyMm5rQDFwYXNzd29yZHNlcnZpY2VhY2NvdW50cy5jb20iLCJzcnBYIjoiNmJiN2FlOTg2YzI0YmQyZTc1MGQxYTNkNzk4M2M1NWNjOTFmMzBmYjMzNTYyYmE4NjU4NzdiNjgxOTc3MmQ3YiIsIm11ayI6eyJhbGciOiJBMjU2R0NNIiwiZXh0Ijp0cnVlLCJrIjoiZDNVVE8xUmpvSjJSbTk2eUFZTEpZMkUyUm1aU3BTRHJ4MkRhS3libGdBYyIsImtleV9vcHMiOlsiZW5jcnlwdCIsImRlY3J5cHQiXSwia3R5Ijoib2N0Iiwia2lkIjoibXAifSwic2VjcmV0S2V5IjoiQTMtTERWOEFELUMzWTRLTi1ZM1I0NC1NQ1czVC1aR0haNS1WOFlOTSIsInRocm90dGxlU2VjcmV0Ijp7InNlZWQiOiI1MGJkZjE1MzE4OGU1YjAyM2FkOWViZGI2MTNjNWNmY2UwNDY2NzU1YTFhZTU0Nzk1M2E5ZjNlM2QzYzMwYjE4IiwidXVpZCI6IkVNSFVYTFNTUVJEMkJHNlZMTEo1N05aN1ZVIn0sImRldmljZVV1aWQiOiJ3NG9iZTRxYXQ1dWJqYmNkdHlwZWZla3FobSJ9
    '';
    mode = "0400";
  };
  # customize kernel version
  boot.kernelPackages = pkgs.linuxPackages_5_15;

  users.groups.admin = { };
  users.users = {
    admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      # only used for a VM not connected to anything, so its fine to put the password here
      password = "admin";
      group = "admin";
    };
  };

  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      memorySize = 2048; # Use 2048MiB memory.
      cores = 3;
      graphics = false;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "23.05";
}
