let
  node = import ./vars.nix;
  unstable = import <nixos-unstable> { config = {}; overlays = []; };

in { config, lib, pkgs, ... }: {  imports = [
    ./hardware-configuration.nix
    ./staking.nix
  ];

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = [ "root" "admin" "app" ];
  };

  boot.tmp.cleanOnBoot = true;

  networking.hostName = node.hostname;
  networking.domain = "";
  time.timeZone = "UTC";

  users.users.admin = {
    isNormalUser = true;
    createHome = true;
    home = "/home/admin";
    uid = 1000;
    group = "users";
    openssh.authorizedKeys.keys = node.users.ssh_keys;
  };
  users.users.app = {
    isNormalUser = true;
    createHome = true;
    linger = true;
    home = "/home/app";
    uid = 1001;
    group = "users";
    openssh.authorizedKeys.keys = node.users.ssh_keys;
  };

  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch";
    upgrade = "sudo nixos-rebuild switch --upgrade";
  };

  environment.systemPackages = with pkgs; [
    curl
    gnupg
    vim
    git
    gnumake
    zip
    unzip
    wget
    file
    openssl
    jq
    htop
    neofetch
    unstable.foundry
  ];

  networking.firewall = {
    enable = true;

    interfaces.default.allowedTCPPorts = [ node.lighthouse.beacon.ports.p2p node.geth.ports.p2p ];
    interfaces.default.allowedUDPPorts = [ node.lighthouse.beacon.ports.p2p node.geth.ports.p2p ];
  };
  
  services.openssh = {
    enable = true;
    openFirewall = false; # Disables port 22 being forcefully opened.
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowAgentForwarding = "no";
      AllowTcpForwarding = "no";
      PubkeyAuthentication = "yes";
    };
  };
  system.stateVersion = "24.11";

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/nvme0n1" ];
}
