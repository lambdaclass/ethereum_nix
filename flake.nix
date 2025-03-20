{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    geth.url = ./geth;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, geth, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          default = pkgs.stdenv.mkDerivation {
            pname = "geth";
            name = "geth";
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
              name = "geth";
              url =
                "https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.15.5.zip";
              sha256 = "sha256-kOgsjvkEi5acv53qnbyxMrPIXkz08SqjIO0A/mj/y90=";
            };
          };
        };
      });
}
