{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./system.nix
    ./users.nix
    ./backup.nix
  ];
}