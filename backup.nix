{ config, pkgs, ... }:

{
  imports =
  [
    ./modules/rrsync.nix
    ./modules/rsync-pull-backup.nix
  ];

  services.rrsync.paths = {
      "/Shared" = {
        key = "<place key here>";
        readOnly = true;
      };
  };

  services.rsync-pull-backup = {
    enable = true;
    key = "/root/.ssh/rsync.prvk";
  };

  services.rsync-pull-backup.jobs = {
    "ServerToBackup-daily" = {
      enable = true;
      schedule = "*-*-* 19:00:00";
      key = "/root/.ssh/rsync.prvk";
      logdir = "/var/log/rsync/ServerToBackup-daily/"; # Trailing slash (/) at the start is a must and end is a must
      logformat = "--Object: %n --Size: %l";
      emailsender  = "sender@dieschoenewolke.de";
      emailrecipient = "recipient@dieschoenewolke.de";
      emailorga = "DieSchoeneWolke";
      options = "--checksums --ignore-errors -q -azogHAXL --delete --delete-excluded";
      source = "backupper@ServerToBackup.local:/FolderToBackup";
      destination = "/mnt/Backup1";
      rules =
      ''
      - **.recycle
      '';
    };
  };

  services.rsync-pull-backup.jobs = {
    "ServerToBackup-weekly" = {
      enable = true;
      schedule = "Sun *-*-* 15:00:00";
      key = "/root/.ssh/rsync.prvk";
      logdir = "/var/log/rsync/ServerToBackup-weekly/"; # Trailing slash (/) at the start is a must and end is a must
      logformat = "--Object: %n --Size: %l";
      emailsender  = "sender@dieschoenewolke.de";
      emailrecipient = "recipient@dieschoenewolke.de";
      emailorga = "DieSchoeneWolke";
      options = "--checksums --ignore-errors -q -azogHAXL --delete --delete-excluded";
      source = "backupper@ServerToBackup.local:/FolderToBackup";
      destination = "/mnt/Backup2";
      rules =
      ''
      - **.recycle
      '';
    };
  };

   services.rsync-pull-backup.jobs = {
    "ServerToBackup-monthly" = {
      enable = true;
      schedule = "01 *-*-* 00:04:00"
      key = "/root/.ssh/rsync.prvk";
      logdir = "/var/log/rsync/ServerToBackup-monthly/"; # Trailing slash (/) at the start is a must and end is a must
      logformat = "--Object: %n --Size: %l";
      emailsender  = "sender@dieschoenewolke.de";
      emailrecipient = "recipient@dieschoenewolke.de";
      emailorga = "DieSchoeneWolke";
      options = "--checksums --ignore-errors -q -azogHAXL --delete --delete-excluded";
      source = "backupper@ServerToBackup.local:/FolderToBackup";
      destination = "/mnt/Backup2";
      rules =
      ''
      - **.recycle
      '';
    };
  };
}