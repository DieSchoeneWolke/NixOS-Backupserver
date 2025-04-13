# https://paul.totterman.name/posts/nixos-rsync-backup/
# ToDo: Multiple ssh keypairs for different machines

{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.services.rsync-pull-backup;
in {
  options.services.rsync-pull-backup = with types; {
    enable = mkEnableOption "pull backup with rsync";
    key = mkOption {
      type = str;
      description = "SSH keypair to use";
      example = "/root/id_backup";
    };
    jobs = mkOption {
      description = "Backup jobs";
      type = attrsOf (submodule {
        options = {
          enable = (mkEnableOption "this rsync job") // {
            default = true;
            example = false;
          };
          key = mkOption {
            type = str;
            description = "SSH keypair to use";
            default = cfg.key;
            example = "/root/id_backup";
          };
          logdir = mkOption {
            type = str;
            description = "Directory to save error logs, the path will be generated if it doens't exist and must contain a trailing slash (/) at the end";
            default = "/var/log/rsync/job1/";
          };
          logformat = mkOption {
            type = str;
            description = "Formatting options for the log output";
            default = "%i %n%L";
            example = "--Object: %n --Size: %l --User: $USER";
          };
          emailsender = mkOption {
            type = str;
            description = "Emailaddress the emails will be sent from";
            example = "backup@rsync.com";
          };
          emailrecipient = mkOption {
            type = str;
            description = "Emailaddress the emails will be sent to";
            example = "admin@example.com";
          };
          emailorga = mkOption {
            type = str;
            description = "Organization name to use";
            example = "NixCorp";
          };
          schedule = mkOption {
            type = str;
            description = "<literal>systemd.time</literal> schedule for backup";
            default = "daily UTC";
            example = "*-*-* 01:00:00";
          };
          source = mkOption {
            type = str;
            description = "rsync source, remember trailing /";
            example = "rsync@srv1.example.com:/";
          };
          destination = mkOption {
            type = str;
            description = "rsync destination, remember trailing /";
            example = "/srv/backup/srv1.example.com";
          };
          options = mkOption {
            type = str;
            description = "rsync options";
            example = "--ignore-errors -q -azHAXL --delete --delete-excluded";
          };
          rules = mkOption {
            type = str;
            description =
              "rsync filter rules, see <literal>man rsync</literal>";
            default = "";
            example = ''
              + /srv
              - *
            '';
          };
        };
      });
      default = { };
      example = literalExpression ''
        {
          "srv1.example.com" = {
            source = "root@srv1.example.com:/";
            destination = "/srv/backup/srv1.example.com/";
          };
        };
      '';
    };
  };

config.systemd = mkIf cfg.enable {
  services = mapAttrs' (name: jobcfg:
    nameValuePair "rsync-pull-backup@${name}" {
      description = "rsync pull backup ${name}";
      enable = jobcfg.enable;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${
          pkgs.writeShellApplication {
            name = "rsync-pull-backup-${name}.sh";
            runtimeInputs = [ pkgs.rsync pkgs.openssh pkgs.msmtp ];
            text = ''
              if [ ! -d ${jobcfg.logdir} ]; then
                mkdir -p ${jobcfg.logdir}
              fi
              LOG_FILE="${jobcfg.logdir}/rsync_$(date +'%d-%m-%Y_%H-%M-%S').log"
              LOG_FORMAT="${jobcfg.logformat}"

              if rsync -e 'ssh -i ${jobcfg.key}' ${jobcfg.options} --log-file="$LOG_FILE" --log-file-format="$LOG_FORMAT" ${
                if jobcfg.rules == "" then
                  ""
                else
                  "-f 'merge ${pkgs.writeText "${name}.rsync.rules" "${jobcfg.rules}"}' "
              } ${jobcfg.source} ${jobcfg.destination}; then
                RESULT=$?
                if [[ $RESULT -gt 0 ]]; then
                  MAIL_SUBJECT="ERROR - NixOS-Pullbackup ${name} - Rsync Report"
                else
                  MAIL_SUBJECT="SUCCESS - NixOS-Pullbackup ${name} - Rsync Report"
                fi
                (echo -e "Subject: $MAIL_SUBJECT\nFrom: ${jobcfg.emailsender}\nOrganization: ${jobcfg.emailorga}\nTo: ${jobcfg.emailrecipient}\n\n" && cat "$LOG_FILE") | ${pkgs.msmtp}/bin/msmtp -t --logfile=/var/log/msmtp/rsync.log
            fi
            '';
          }
        }/bin/rsync-pull-backup-${name}.sh";
      };
    }) cfg.jobs;

    timers = mapAttrs' (name: jobcfg:
      nameValuePair "rsync-pull-backup@${name}" {
        description = "rsync pull backup ${name}";
        enable = jobcfg.enable;
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Unit = "rsync-pull-backup@${name}.service";
          OnCalendar = jobcfg.schedule;
          RandomizedDelaySec = 1800;
          FixedRandomDelay = true;
          Persistent = true;
          AccuracySec = "1us";
        };
      }) cfg.jobs;
  };
}