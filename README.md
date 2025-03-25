# Nix and Ethereum

This repository provides scripts for deploying Ethereum execution and consensus clients on **NixOS** and, soon, as **Nix Flakes**.

## Supported Configurations

### NixOS

- **Geth + Lighthouse**
- **Erigon** (with its internal consensus client)
- **Geth + Lighthouse as a validator**
  - Supported on **Holesky** testnet
  - Coming soon to **Hoodi** and **Mainnet**

### Nix (Flakes)

- Flake under development: [PR #3](https://github.com/lambdaclass/ethereum_nix/pull/3)
  - Currently supports **Geth**
  - **Lighthouse** support is in progress
  - Future plans to support additional clients

## Why Not [ethereum.nix](https://github.com/nix-community/ethereum.nix/)?

We are aware of this existing repository, but we found it not appropiate for our needs, we at lambda
are used to build our own opinionated tools.

We appreciate the Nix community for their work on ethereum.nix, which helped pave the way for this project and the broader Ethereum Nix ecosystem.

## Project Status

This project is still a **work in progress**, and some values are currently hardcoded. We are actively improving flexibility and expanding support for additional execution and consensus client combinations, including **Nethermind**, **Prysm**, and **Ethrex**.

## License

This repository is licensed under the **MIT License**.
