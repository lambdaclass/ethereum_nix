{
  description = "A flake for building Geth (Go Ethereum)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        geth = pkgs.stdenv.mkDerivation {
          pname = "geth";
          version = "1.15.5";
          buildInputs = [ pkgs.go ];
          buildPhase = ''
            export HOME=$(pwd)
            make geth
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp build/bin/geth $out/bin/
          '';
          src = pkgs.fetchzip {
            url =
              "https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.15.5.zip";
            sha256 = "sha256-kOgsjvkEi5acv53qnbyxMrPIXkz08SqjIO0A/mj/y90=";
          };
        };
      in {
        packages.default = geth;
        devShell = pkgs.mkShell {
          name = "geth-shell";
          packages = [ geth ];
        };
      });
}
