# Nix Ethereum
Nix flakes and NixOS modules for the Ethereum ecosystem.

### Nix
We provide Nix flakes for quickly deploying Ethereum execution and consensus clients in a reproducible and declarative manner.

#### Execution clients
Currently supported execution clients.
- [go-ethereum](https://github.com/ethereum/go-ethereum)

#### Consensus clients
We are working hard to support consensus clients.

### NixOS
Our NixOS configuration files simplify setting up an Ethereum validator and RPC on NixOS, currently supporting **Geth + Lighthouse** on any network. Additionally, we offer built-in **monitoring** with Grafana and Loki.

### Installation
We encourage installing `nix` using the installation method provided by [determinate.systems](https://determinate.systems/posts/determinate-nix-installer)

### Usage
To spin up a terminal with **geth**, run the following command:
```
nix run github:lambdaclass/ethereum_nix
```
> Ensure that Nix flakes are enabled before running this command. 
> 
> You can enable flakes by adding `experimental-features = nix-command flakes` in your `/etc/nix/nix.conf` configuration file.

experimental-features = nix-command flakes

### Project Status 🚧
This project is a work in progress. Some configurations are currently hardcoded or untidy, but we are actively improving flexibility. 
Future updates will expand support to additional execution and consensus client combinations, including Ethrex.

- [x] Test on MacOS
- [ ] Test on Linux
- [ ] Add more execution clients
- [ ] Add more consensus clients

### License
This repo is under the MIT license.
