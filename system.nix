{ config, pkgs, ... }: {

  #UEFI

  boot.loader = {
  systemd-boot.enable = true;
  timeout = 5;
  efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
	  };
  };
  
  #BIOS

  #boot.loader = {
  #timeout = 5;
  #grub = {
  #   enable = true;
  #   device = "/dev/sdX"; # replace with your disk
  #  };
  #};

  system = {
    stateVersion = "24.05";
    copySystemConfiguration = true;
    autoUpgrade.enable = false;
    autoUpgrade.allowReboot = false;
  };  

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  
   console = {
     font = "iso10.16";
     keyMap = "de";
   };
   
  environment.systemPackages = with pkgs; [
  rsync
  msmtp
  ];
}