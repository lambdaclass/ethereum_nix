let
  node = import ./vars.nix;
in {
  hostname = "eth-testnet-rpc";

  users.ssh_keys = [
    "ssh-..."
    "ssh-..."
  ];

  erigon = {
    sepolia = {
      caddy_endpoint_url = "sepolia.internal.lambdaclass.com";
      ports = {
        http = 8545;
        p2p = 30303;
        torrent = 42069;
        api = 9090;
        discovery = 4000;
        sentinel = 7777;
      };
    };
    holesky = {
      caddy_endpoint_url = "holesky.internal.lambdaclass.com";
      ports = {
        http = 8546;
        p2p = 30305;
        torrent = 42070;
        api = 9091;
        discovery = 4001;
        sentinel = 7778;
      };
    };
  };
}
