let
  node = import ./vars.nix;
  unstable = import <nixos-unstable> { config = {}; overlays = []; };

in { config, lib, pkgs, ... }: {  imports = [
    ./hardware-configuration.nix
    ./rpc.nix
  ];

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = [ "root" "admin" "app" ];
  };

  boot.tmp.cleanOnBoot = true;

  nix.optimise.automatic = true;
  networking.hostName = "eth-testnet-rpc";
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
    zip
    unzip
    wget
    file
    openssl
    jq
    htop
    neofetch
    go
  ];

  networking.firewall = {
    enable = false;
    trustedInterfaces = [ "enp9s0" ]; 

    #TODO: Change to only allow RPC-specific ports.
    #interfaces.default.allowedTCPPorts = [ ];
    #interfaces.default.allowedUDPPorts = [ ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
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
