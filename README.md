# op-nix

1Password deployment secrets for NixOS

## Tradeoffs vs. `agenix`

`agenix` had a few major pain points for me that we attempted to solve with this project. Those pain points are:

- `age` does not support SSH agents, so I can't use the 1Password SSH agent and have to have separate SSH keys that are only on my server, on disk, although encrypted with a passphrase
- I have to duplicate the secrets; one copy in 1Password and one copy in `my-secret.age` file in my dotfiles repo.

`opnix` solves both of these pain points; SSH keys are taken out of the equation entirely, and pulls your secrets directly from your 1Password Vault(s)
using a [Service Account token](https://developer.1password.com/docs/service-accounts/). This does, however, come with the tradeoff that
_a network connection is now required to provide secrets._ For my use-case (just a simple home media server) this is a totally fine thing for me to accept,
however you'll need to use your own judgement to decide if this project is a good fit for you.
