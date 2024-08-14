{ pkgs, lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "1password-cli" ];
  imports = [ ./test-secret-server.nix ];
  # customize kernel version
  boot.kernelPackages = pkgs.linuxPackages_5_15;

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };
  environment.variables.EDITOR = "nvim";

  # enable DHCP networking to get a local IP address
  networking.useDHCP = lib.mkDefault true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.groups.admin = { };
  users.users = {
    admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "oci" ];
      # only used for a VM not connected to anything, so its fine to put the password here
      password = "admin";
      group = "admin";
    };
  };

  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      memorySize = 4 * 1024; # Use 4Gb memory.
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
