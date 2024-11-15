{ lib, config, pkgs, ... }:
with lib;
let cfg = config.services.rrsync;
in {
  options.services.rrsync = with types; {
    paths = mkOption {
      description = "paths to expose via rrsync";
      type = attrsOf (submodule {
        options = {
          key = mkOption {
            type = str;
            description = "SSH public key, without options";
            example = "ssh-ed25519 AAAA... user@example";
          };
          readOnly = mkOption {
            type = bool;
            description = "expose read-only";
            default = true;
            example = false;
          };
        };
      });
      default = { };
      example = literalExpression ''
        {
          "/srv" = {
            key = "ssh-ed25519 AAAA... user@example";
            readOnly = true;
          };
        };
      '';
    };
  };

config.users.users.root.openssh.authorizedKeys.keys = mapAttrsToList
  (name: share:
    ''
      command="${pkgs.rrsync}/bin/rrsync ${if share.readOnly then "-ro " else ""}${name}",restrict=${share.key}
    ''
  ) cfg.paths;
}