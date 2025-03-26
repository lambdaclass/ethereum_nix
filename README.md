<img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/33856d7837cb8ba76c4fc9e26f91a659066ee31f/logo/nix-snowflake-colours.svg" height="100">

# Nix and Ethereum
This repository provides examples for deploying Ethereum nodes using [nix](https://nixos.org/)

### Quickstart
The [ethereum.nix](https://github.com/nix-community/ethereum.nix/) framework is meant for deploying Ethereum nodes with reproducible and declarative configurations.

Ensure you have Nix installed.
```bash
nix --version
```
> In case you do not have `nix`, we recomment the [determinate systems](https://determinate.systems/posts/determinate-nix-installer/) installer, which enables flakes and comes with some minor tweaks to make your nix journey more pleasant.

To quickly deploy an execution client like `go-ethereum`, simply run the following command.

```nix
nix run github:nix-community/ethereum.nix#geth
```

And a consensus client like `lighthouse`

```nix
nix run github:nix-community/ethereum.nix#lighthouse
```

The [official documentation](https://nix-community.github.io/ethereum.nix/nixos/installation) describes all possible client combinations. 

Beware not all clients support any Operating System and Architecture combination.

### Running on NixOS
When running this on a **NixOS machine**, these applications should run as a system service. We can again use [ethereum.nix](https://github.com/nix-community/ethereum.nix/) to quickly deploy a node.

1. Add the **ethereum-nix** derivation into your **configuration.nix**
    ```nix
    let
      ethereum-nix = import (fetchTarball "https://github.com/nix-community/ethereum.nix/archive/main.tar.gz");
      ...
    ```
2. Import the **ethereum-nix** module into your **configuration.nix**
    ```nix
    imports = [
      ethereum-nix.nixosModules.default
      ...
    ]
    ```
3. Create a **jwt.hex** file (or use a secret provisioning service)
   ```bash
   openssl rand -hex 32 | tr -d "\n" | tee /secrets/jwt.hex
   ```
4. Declare your system service, modify as you like. In this case, we can spin up a `geth` node with the following code.

    All possible `geth` nix options are listed [here](https://nix-community.github.io/ethereum.nix/nixos/modules/geth/).
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
    > Replace `<network-name>` with your desired Ethereum network, such as `mainnet`, `sepolia`, `hoodi` or any other that's supported.
5. Pair it with a consensus client like `lighthouse`:
    ```nix
    services.ethereum.lighthouse.<network-name> = {
      enable = true;
      openFirewall = true;
      args = {
        network = "<network-name>";
        execution-jwt = "/secrets/jwt.hex";
        http.enable = true;
      };
    };
    ```
   > Replace `<network-name>` with your desired Ethereum network, make sure it matches the network specified in your execution client.

