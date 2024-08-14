![check-flake workflow](https://github.com/mrjones2014/op-nix/actions/workflows/check-flake.yml/badge.svg) [![1Password CLI](https://img.shields.io/badge/1Password-CLI-blue?logo=1password&label=1Password)](https://developer.1password.com/docs/cli/) [![1Password Service Accounts](https://img.shields.io/badge/1Password-Service%20Accounts-blue?logo=1password&label=1Password)](https://developer.1password.com/docs/service-accounts)

# op-nix

Manage secrets for NixOS with 1Password natively with a NixOS module.

> [!NOTE]
> This is _beta software._ There may be breaking changes in the future, and some things may not work.
> Please try it out and report any issues that may come up!

## Usage

Add the `opnix` module as a Flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opnix = {
      url = "/home/ivan/code/op-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, opnix, ... }:
    let system = "x86_64-linux";
    in {
      nixosConfigurations.nixos-pc = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # import the opnix NixOS module
          opnix.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
```

Then, in your configuration:

```nix
{ config, ... }: {
  opnix = {
    # This is where you put your Service Account token in .env file format, e.g.
    # OP_SERVICE_ACCOUNT_TOKEN="{your token here}"
    # See: https://developer.1password.com/docs/service-accounts/use-with-1password-cli/#get-started
    # This file should have permissions 400 (file owner read only) or 600 (file owner read-write)
    # The systemd script will print a warning for you if it's not
    environmentFile = "/etc/opnix.env";
    # Set the systemd services that will use 1Password secrets; this makes them wait until
    # secrets are deployed before attempting to start the service.
    systemdWantedBy = [ "my-systemd-service" "homepage-dashboard" ];
    # Specify the secrets you need
    secrets = {
      # The 1Password Secret Reference in here (the `op://` URI)
      # will get replaced with the actual secret at runtime
      some-secret.source = ''
        # You can put arbitrary config markup in here, for example, TOML config
        [ConfigRoot]
        SomeSecretValue="{{ op://MyVault/MySecretItem/token }}"
      '';
      # you can also specify the UNIX file owner, group, and mode
      some-secret.user = "SomeServiceUser";
      some-secret.group = "SomeServiceGroup";
      some-secret.mode = "0600";
      # If you need to, you can even customize the path that the secret gets installed to
      some-secret.path = "/some/other/path/some-secret";
      # You can also disable symlinking the secret into the installation destination
      some-secret.symlink = false;
    };
  };

  # run a systemd service
  systemd.services.my-systemd-service = {
    enable = true;
    # here, `config.opnix.secrets.some-secret.path` is the ramfs path
    # of the file with the actual secret injected
    script = ''
      some-script --env-file ${config.opnix.secrets.some-secret.path}
    '';
    wantedBy = [ "multi-user.target" ];
  };

  # or if there's a NixOS module and it has an `environmentFile` option,
  # you can provide your secrets that way
  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.opnix.secrets.some-secret.path;
    # ... the rest of your homepage config here
  };
}
```

## Tradeoffs vs. `agenix`

`agenix` had a few major pain points for me that we attempted to solve with this project. Those pain points are:

- `age` does not support SSH agents, so I can't use the 1Password SSH agent and have to have separate SSH keys that are only on my server, on disk, although encrypted with a passphrase
- I have to duplicate the secrets; one copy in 1Password and one copy in `my-secret.age` file in my dotfiles repo.

`opnix` solves both of these pain points; SSH keys are taken out of the equation entirely, and pulls your secrets directly from your 1Password Vault(s)
using a [Service Account token](https://developer.1password.com/docs/service-accounts/). This does, however, come with the tradeoff that
_a network connection is now required to provide secrets._

For my use-case (just a simple home media server) this is a totally fine thing for me to accept,
however you'll need to use your own judgement to decide if this project is a good fit for you.

## Security

With this setup, you should only need one unencrypted secret on your machine; your 1Password Service Account token.
You should set your Service Account token to have the _absolute minimum required permissions._ Usually this is read-only
access to only a single vault in which your server secrets are kept. You should set an expiration on the token and
[rotate it regularly](https://developer.1password.com/docs/service-accounts/manage-service-accounts/#rotate-token).

The Service Account token is provided to the `systemd` jobs via an `EnvironmentFile` so that the token will not appear in `systemd` logs.

Your `source` text (e.g. `opnix.secrets.my-secret.source = "{{ op://SomeVault/SomeItem/token }}";`) _**does appear**_ in the Nix store, in plaintext.
Your **actual secrets _do NOT_** appear in the Nix store at all; however they are mounted in plaintext to a temporary `ramfs` during runtime, with
strict UNIX file permissions. These files go away when the machine is powered off, and are recreated during system activation.

## Acknowledgements/Prior Art

Much of the logic in this project is very similar to that of [agenix](https://github.com/ryantm/agenix); thanks for all the hard work you've put into that project!
