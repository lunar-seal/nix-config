{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    import-tree.url = "github:vic/import-tree";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-private.url = "git+ssh://git@github.com/lunar-seal/nix-private.git";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.decemberflower = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          user = "langj";
        };
        modules = [
          (inputs.import-tree ./modules/common)
          (inputs.import-tree ./modules/desktop)
          (inputs.import-tree ./modules/laptop)
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nix-private.nixosModules.default
          ./hosts/decemberflower.nix
        ];
      };

      nixosConfigurations.moonshield = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          user = "langj";
        };
        modules = [
          (inputs.import-tree ./modules/common)
          (inputs.import-tree ./modules/desktop)
          inputs.nix-private.nixosModules.default
          ./hosts/moonshield.nix
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.nixfmt-tree ];
      };
    };
}
