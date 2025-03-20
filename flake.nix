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
        packages.default = geth.packages.${system}.default;
        defaultPackage.${system} = geth.packages.${system}.default;

        apps.geth = geth.apps.${system}.default;

        # Optionally, create a devShell that includes geth
        devShell = pkgs.mkShell {
          name = "Eth dev-shell";
          packages = [ geth.packages.${system}.default ];
        };
      });
}
