{ config, pkgs, ... }: {
networking = {
  hosts = {
  "<YourServerToBackupIPHere>" = ["ServerToBackup.local"];
    };
  hostName = "rsyncbackupserver";
  domain = "local";
  fqdn = "rsyncbackupserver.local"; 
  useDHCP = false;
  firewall = {
  enable = true;
  interfaces.<YourInterfaceHere> = {
    allowedTCPPorts = [22];
    };
  };
  nameservers = [  
    "84.200.69.80"
    "84.200.70.40" 
  ];
  enableIPv6 = false;
  interfaces.<YourInterfaceHere> = {
    wakeOnLan.enable = true;
    ipv4.addresses = [{
      address = "<IPFromTheBackupServer>";
      prefixLength = 24;
      }];
    };
  defaultGateway = {
    address = "<YourGatewayIPHere>";
    interface = "<YourInterfaceHere>";
    };
  };

  services.openssh = {
  enable = true;
  settings.PasswordAuthentication = false;
  settings.KbdInteractiveAuthentication = false;
  settings.PermitRootLogin = "no";
  };

  programs.ssh = {
  knownHosts = {
  backup = {
  extraHostNames = [ <YourServerToBackupIPHere> <ServerToBackup.local> ];
  publicKeyFile = /etc/rsync/rsync.pubk;
    };
   };
  extraConfig = ''
Host <YourServerToBackupIPHere>
ServerAliveInterval 30
ServerAliveCountMax 6
    '';
  };

  services.fail2ban = {
    enable = true;
   # Ban IP after 5 failures
    maxretry = 5;
    ignoreIP = [
      "<YourSubnetHere>/24"
      "dieschoenewolke.de" # resolve the IP via DNS
      ];
    bantime = "24h"; # Ban IPs for one day on the first ban
    bantime-increment = {
      enable = true; # Enable increment of bantime after each violation
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # Do not ban for more than 1 week
      overalljails = true; # Calculate the bantime based on all the violations
    };
  };
}