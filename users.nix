{ config, pkgs, ... }: {
  users.mutableUsers = true;

# Define a user account and don't forget to change the initial password afterwards with "passwd"!
  users.users = { 
    backupper = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "RemoteBackupsByDieSchoeneWolke.de";
    openssh.authorizedKeys.keys = [
    "<place key here>"
      ];
    };
  };
}