{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs = { self, nixpkgs }: 
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in {
      packages.aarch64-darwin.default = pkgs.stdenv.mkDerivation {
        pname = "geth";
        name = "geth";
        
        buildInputs = with pkgs;[ 
          go
        ];
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
          url = "https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.15.5.zip";
          sha256 = "sha256-kOgsjvkEi5acv53qnbyxMrPIXkz08SqjIO0A/mj/y90=";
        };
    };
  };
}
