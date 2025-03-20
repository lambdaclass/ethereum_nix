{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    geth.url = ./geth;
  };

  outputs = inputs@{ self, nixpkgs, geth }:
    let
      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in {      # A Nixpkgs overlay.
      
      # Provide some binary packages for selected system types.
      #packages = forAllSystems (system:
      #  {
      #    inherit (nixpkgsFor.${system}) hello;
      #  });

      #defaultPackage = forAllSystems (system: self.packages.${system}.hello);
      defaultPackage.aarch64-darwin = inputs.geth.packages.aarch64-darwin.default;
    };
}
