{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    import-tree.url = "github:vic/import-tree";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-private.url = "git+ssh://git@github.com/lunar-seal/nix-private.git";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "";
    agenix.inputs.home-manager.follows = "";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      mkHost =
        name: modules:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
            user = "langj";
          };
          modules = [
            (inputs.import-tree ./modules/common)
            inputs.agenix.nixosModules.default
            # Only the ed25519 host key; never fall back to the RSA one.
            { age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; }
          ]
          ++ modules
          ++ [ ./hosts/${name}.nix ];
        };
    in
    {
      nixosConfigurations = {
        decemberflower = mkHost "decemberflower" [
          (inputs.import-tree ./modules/desktop)
          (inputs.import-tree ./modules/laptop)
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nix-private.nixosModules.default
        ];

        moonshield = mkHost "moonshield" [
          (inputs.import-tree ./modules/desktop)
          inputs.nix-private.nixosModules.default
        ];

        voices = mkHost "voices" [
          (inputs.import-tree ./modules/server)
          ./modules/store-serve
          ./modules/zed-mail
          inputs.disko.nixosModules.disko
          inputs.nix-private.nixosModules.server
        ];
      };

      packages.${system} = {
        inherit (inputs.disko.packages.${system}) disko disko-install;
      };

      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt-tree
          inputs.agenix.packages.${system}.default
        ];
      };
    };
}
