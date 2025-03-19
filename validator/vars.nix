let
  node = import ./vars.nix;
in {
  hostname = "nixos-baremetal";

  users.ssh_keys = [
    "ssh-..."
    "ssh-..."
  ];

  network = "holesky";
  fee_recepient = "...";

  geth = {
    network = "holesky";
    ports = {
      p2p = 30303;
      http = 8545;
      ws = 8546;
      authrpc = 8551;
      metrics = 6060;
    };
  };

  lighthouse = {
    beacon = {
      network = "holesky";
      execution_endpoint = "localhost:${toString node.geth.ports.authrpc}"; 
      sync_url = "https://checkpoint-sync.holesky.ethpandaops.io";
      ports = {
        p2p = 9000;
        http = 5052;
        metrics = 5054;
      };
    };
    validator = {
      ports = {
        http = 5062;
        metrics = 5064;
      };
    };
  };

  mev = {
    port = 18550;
  };

  grafana.address = "0.0.0.0";
}
