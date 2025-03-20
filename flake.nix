{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    geth.url = ./geth;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, geth, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        geth = {
          inherit nixpkgs;
          inherit flake-utils;
        };
      in {
        packages.${system} = [ geth ];
        devShell = pkgs.mkShell {
          name = "geth-shell";
          packages = [ geth ];
        };
      });
}
