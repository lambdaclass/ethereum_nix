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

### Tweaks
This section explains how to tweak your configuration in order to make it just how you need it.

1. Install a newer version of a client.
   In case you need to change the version of the clients, we can do that by importing the unstable channel to our configuration file.
   1. Add the `unstable` channel to your machine.
      ```nix
      nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
      ```
   2. Declare the `unstable` channel into your configuration file.
      ```nix
      let
         unstable = import <nixos-unstable> { config = {}; overlays = []; };
         ...
      ```
   3. Change the specified package to be installed when declaring the services.
      ```nix
      services.ethereum.geth.<network-name> = {
         package = unstable.go-ethereum
         ...
      ```
      ```nix
      services.ethereum.lighthouse.<network-name> = {
         package = unstable.lighthouse
         ...
      ```
2. Install a custom version of a client
   When not even the `unstable` channel can catch up with the latest version of a client, we can create a custom package.
   1. Generate the SRI hash for the package
      ```nix
      nix hash convert --hash-algo sha256 --to sri $(nix-prefetch-url <url>)
      ```
   2. Define your custom package. Here is an exaple for lighthouse
      ```nix
      let
        ...
        lighthouse-custom = pkgs.runCommand "lighthouse-7.0.0-beta.3" {} ''
          mkdir -p $out/bin
          ${pkgs.gnutar}/bin/tar -xzf ${pkgs.fetchurl {
            url = "https://github.com/sigp/lighthouse/releases/download/v7.0.0-beta.3/lighthouse-v7.0.0-beta.3-x86_64-unknown-linux-gnu.tar.gz";
            sha256 = "sha256-CMc9sBNPEwxHEPH5ZmXHeZQfIH72+a6rSS9re28pPEo="; # Output from step 1
          }} -C $out/bin
          chmod +x $out/bin/<package>
        '';
      ```
   3. Change the `package` value inside your service definition.
      ```nix
      services.ethereum.lighthouse.<network-name> = {
         package = lighthouse-custom
         ...
      ```
