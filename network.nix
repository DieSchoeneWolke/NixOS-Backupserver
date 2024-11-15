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
    "194.25.0.60"
    "194.25.0.68" 
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