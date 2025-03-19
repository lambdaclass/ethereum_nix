{ config, pkgs, ... }:
let
  node = import ./vars.nix;
  unstable = import <nixos-unstable> { config = {}; overlays = []; };

  erigon-custom = pkgs.runCommand "erigon" {} ''
    mkdir -p $out/bin
    ${pkgs.gnutar}/bin/tar --strip-components=1 -xzf ${pkgs.fetchurl {
      url = "https://github.com/erigontech/erigon/releases/download/v3.0.0-rc3/erigon_v3.0.0-rc3_linux_amd64v2.tar.gz";
      sha256 = "sha256-No7vBN0AKSCiRyqwuNXegnmbcp4eNOW/BlG8pYFj3HY=";
    }} -C $out/bin
    chmod +x $out/bin/erigon
  '';

in {
  environment.systemPackages = with pkgs; [
    erigon-custom
  ];

  programs.nix-ld.enable = true;

  services.caddy = {
    enable = true;
    package = unstable.caddy;
    virtualHosts = {
      "${toString node.erigon.sepolia.caddy_endpoint_url}" = {
        extraConfig = ''
          reverse_proxy http://localhost:${toString node.erigon.sepolia.ports.http} {
            header_up Host localhost
          }
        '';
      };
      "${toString node.erigon.holesky.caddy_endpoint_url}" = {
        extraConfig = ''
          reverse_proxy http://localhost:${toString node.erigon.holesky.ports.http} {
            header_up Host localhost
          }
        '';
      };
  };

  systemd.user.services.erigon_sepolia = {
    description = "Erigon Sepolia";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app/";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''${erigon-custom}/bin/erigon \
        --chain=sepolia \
        --port ${toString node.erigon.sepolia.ports.p2p} \
        --torrent.port ${toString node.erigon.sepolia.ports.torrent} \
        --private.api.addr 127.0.0.1:${toString node.erigon.sepolia.ports.api} \
        --caplin.discovery.port ${toString node.erigon.sepolia.ports.discovery} \
        --sentinel.port ${toString node.erigon.sepolia.ports.sentinel} \
        --http --http.addr 127.0.0.1 --http.port ${toString node.erigon.sepolia.ports.http}
      '';
    };
  };

  systemd.user.services.erigon_holesky = {
    description = "Erigon Holesky";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app/";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''${erigon-custom}/bin/erigon \
        --chain=holesky \
        --port ${toString node.erigon.holesky.ports.p2p} \
        --torrent.port ${toString node.erigon.holesky.ports.torrent} \
        --private.api.addr 127.0.0.1:${toString node.erigon.holesky.ports.api} \
        --caplin.discovery.port ${toString node.erigon.holesky.ports.discovery} \
        --sentinel.port ${toString node.erigon.holesky.ports.sentinel} \
        --http --http.addr 127.0.0.1 --http.port ${toString node.erigon.holesky.ports.http}
      '';
    };
  };
}
