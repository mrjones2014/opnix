/* {
      opnix.secrets = {
         my-secrets = {
           source = ''
             [SomeHeader]
             Value = "{{ op://ValueName/ItemName/FieldName }}"
           '';
          user = config.services.some_service.user;
          group = config.services.some_servive.group;
         };
       };

      services.some_servive.privateKeyFile = config.opnix.secrets.my-secret.path;
   }
*/
{ lib, config, ... }:
with lib;
let
  inherit (config.users) users;
  cfg = config.opnix;
in {
  secretFileDeclaration = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = config._module.args.name;
        description = "Name of the file used in {option}`opnix.secretsDir`";
      };
      source = mkOption {
        type = types.oneOf [ types.str types.lines ];
        description =
          "The file text that will be encrypted; it can be a 1Password Secret Reference URI or some text that contains one or multiple Secret References URIs.";
        example = literalExpression ''
          \'\'
            [SomeTomlHeader]
            SomeValue = "{{ op://VaultName/ItemName/FieldName }}"
          \'\'
        '';
      };
      mode = mkOption {
        type = types.str;
        default = "0400";
        description = ''
          Permissions mode of the decrypted secret in a format understood by chmod.
        '';
      };
      user = mkOption {
        type = types.str;
        default = "0";
        description = ''
          User of the decrypted secret.
        '';
      };
      group = mkOption {
        type = types.str;
        default = users.${config.owner}.group or "0";
        example = literalExpression ''
          users.''${config.owner}.group or "0"
        '';
        description = ''
          Group of the decrypted secret.
        '';
      };
      path = mkOption {
        type = types.str;
        default = "${cfg.secretsDir}/${config.name}";
        example = literalExpression ''
          "''${cfg.secretsDir}/''${config.name}"
        '';
        description = ''
          Path where the decrypted secret is installed.
        '';
      };
      symlink = mkEnableOption "symlinking secrets to their destination" // {
        default = true;
      };
    };
  });
}
