<img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/33856d7837cb8ba76c4fc9e26f91a659066ee31f/logo/nix-snowflake-colours.svg" height="100">

# Nix and Ethereum
This repository provides code for deploying Ethereum nodes using [ethereum.nix](https://github.com/nix-community/ethereum.nix/)

### Quickstart
To quickly deploy an execution client like `go-ethereum`, simply run the following command.

```nix
nix run github:nix-community/ethereum.nix#geth
```

And a consensus client like `lighthouse`

```nix
nix run github:nix-community/ethereum.nix#lighthouse
```

The [official documentation](https://nix-community.github.io/ethereum.nix/nixos/installation) describes all possible client combinations.

### Running on NixOS
When running this on a NixOS server, these applications should run as a system service.

1. Add the **ethereum-nix** derivation into your **configuration.nix**
   ```nix
   let
     ethereum-nix = import (fetchTarball "https://github.com/nix-community/ethereum.nix/archive/main.tar.gz");
     ...
   ```
2. Import the **ethereum-nix** module into your **confiduration.nix**
   ```nix
   imports = [
     ethereum-nix.nixosModules.default
     ...
   ]
   ```
3. Create a **jwt.hex** file.
   ```bash
   openssl rand -hex 32 | tr -d "\n" | tee /secrets/jwt.hex
   ```
5. Declare your system service, modify as your liking. 

    All possible options are listed [here](https://nix-community.github.io/ethereum.nix/nixos/modules/geth/).
    ```nix
    services.ethereum.geth.<network-name> = {
      enable = true;
      package = pkgs.go-ethereum;
      openFirewall = true;
      args = {
        syncmode = "full";
        network = "<network-name>";
        http = {
          enable = true;
          addr = "0.0.0.0";
          vhosts = ["localhost" "phoebe"];
          api = ["net" "web3" "eth"];
        };
        authrpc.jwtsecret = "/secrets/jwt.hex";
      };
    };
    ```
