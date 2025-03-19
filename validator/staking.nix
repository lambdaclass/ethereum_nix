{ config, pkgs, ... }:

let
  node = import ./vars.nix;
  unstable = import <nixos-unstable> { config = {}; overlays = []; };

  lighthouse-custom = pkgs.runCommand "lighthouse-7.0.0-beta.3" {} ''
    mkdir -p $out/bin
    ${pkgs.gnutar}/bin/tar -xzf ${pkgs.fetchurl {
      url = "https://github.com/sigp/lighthouse/releases/download/v7.0.0-beta.3/lighthouse-v7.0.0-beta.3-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-CMc9sBNPEwxHEPH5ZmXHeZQfIH72+a6rSS9re28pPEo=";
    }} -C $out/bin
    chmod +x $out/bin/lighthouse
  '';

  geth-custom = pkgs.runCommand "go-ethereum-1.15.5" {} ''
    mkdir -p $out/bin
    ${pkgs.gnutar}/bin/tar -xzf ${pkgs.fetchurl {
      url = "https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.15.5-4263936a.tar.gz";
      sha256 = "sha256-6zRKGjk1HAAV+QkMHkwAkf0Oinc46fadaSyPDKrtM3w=";
    }}
    mv geth-linux-amd64-*/geth $out/bin/geth
    chmod +x $out/bin/geth
  '';

in {
  imports = [
    ./monitoring.nix
  ];

  environment.systemPackages = with pkgs; [
    geth-custom
    lighthouse-custom
    mev-boost
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    gcc.cc.lib
  ];

  systemd.services.generate-jwt = {
    description = "Generate JWT secret for Staking Services";
    wantedBy = [ "multi-user.target" ];
    before = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils-full}/bin/mkdir -p /secrets";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.openssl}/bin/openssl rand -hex 32 | tr -d \"\\n\" | tee /secrets/jwt.hex'";
      RemainAfterExit = true;
    };
  };

  systemd.user.services.geth = {
    description = "Geth";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app/";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''
        ${geth-custom}/bin/geth \
        --log.vmodule "rpc=5" \
        --${toString node.network} \
        --gcmode full \
        --http --http.addr 0.0.0.0 --http.port ${toString node.geth.ports.http} --http.vhosts "*" --http.corsdomain "*" \
        --ws --ws.addr 0.0.0.0 --ws.port ${toString node.geth.ports.ws} \
        --authrpc.addr 0.0.0.0 --authrpc.port ${toString node.geth.ports.authrpc} --authrpc.jwtsecret /secrets/jwt.hex  \
        --nat none \
        --port ${toString node.geth.ports.p2p} \
        --metrics --metrics.addr 0.0.0.0 --metrics.port ${toString node.geth.ports.metrics}
      '';
    };
  };

  systemd.user.services.lighthouse = {
    description = "Lighthouse Beacon Node";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''
        ${lighthouse-custom}/bin/lighthouse bn \
        --disable-log-timestamp \
        --network ${toString node.network} \
        --execution-endpoint http://localhost:${toString node.geth.ports.authrpc} \
        --execution-jwt /secrets/jwt.hex \
        --checkpoint-sync-url ${toString node.lighthouse.beacon.sync_url} \
        --port ${toString node.lighthouse.beacon.ports.p2p} \
        --http --http-address 0.0.0.0 --http-port ${toString node.lighthouse.beacon.ports.http} --http-allow-origin "*" \
        --metrics --metrics-address 0.0.0.0 --metrics-port ${toString node.lighthouse.beacon.ports.metrics} \
        --validator-monitor-auto \
        --builder http://127.0.0.1:${toString node.mev.port}
      '';
    };
  };

  systemd.user.services.lighthouse_validator = {
    description = "Lighthouse Validator";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''
        ${unstable.lighthouse}/bin/lighthouse vc \
        --disable-log-timestamp \
        --network ${toString node.network} \
        --enable-doppelganger-protection \
        --beacon-nodes http://localhost:${toString node.lighthouse.beacon.ports.http} \
        --unencrypted-http-transport \
        --suggested-fee-recipient ${toString node.fee_recepient} \
        --http --http-address 0.0.0.0 --http-port ${toString node.lighthouse.validator.ports.http} --http-allow-origin "*" \
        --metrics --metrics-address 0.0.0.0 --metrics-port ${toString node.lighthouse.validator.ports.metrics} \
        --builder-proposals
      '';
    };
  };

  systemd.user.services.mev = {
    description = "MEV Boost";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "app";
    unitConfig.After = [ "network-online.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/app";
      Restart = "on-failure";
      ExecReload = "/bin/kill -HUP $MAINPID";
      KillSignal = "SIGTERM";
      ExecStart = ''
        ${pkgs.mev-boost}/bin/mev-boost \
        --${toString node.network} \
        --addr localhost:${toString node.mev.port} \
        --min-bid 0.03 \
        --relay-check \
        --relay https://0xaa58208899c6105603b74396734a6263cc7d947f444f396a90f7b7d3e65d102aec7e5e5291b27e08d02c50a050825c2f@holesky.titanrelay.xyz \
        --relay https://0xb1559beef7b5ba3127485bbbb090362d9f497ba64e177ee2c8e7db74746306efad687f2cf8574e38d70067d40ef136dc@relay-stag.ultrasound.money \
        --relay https://0xab78bf8c781c58078c3beb5710c57940874dd96aef2835e7742c866b4c7c0406754376c2c8285a36c630346aa5c5f833@holesky.aestus.live
      '';
    };
  };
}

