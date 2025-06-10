{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { 
    self, nixpkgs, home-manager, ...
  } @ inputs: 
  let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          # System config
          ./configuration.nix

          # Include self-defined modules.
          ./modules/os.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.gregtao = {
              imports = [
                ./home.nix
              ];
            };

            # Pass arguments to home.nix
            home-manager.extraSpecialArgs = {
              inherit inputs outputs;
            };
          }
        ];
      };
    };
  };
}
