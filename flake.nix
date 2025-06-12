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
    settings = import ./settings.nix;
    args = {
      inherit inputs outputs settings;
    };
  in {
    nixosConfigurations = {
      "${settings.hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = args;

        modules = [
          # System config
          ./configuration.nix

          # Include self-defined modules.
          ./modules/os.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${settings.username} = {
              imports = [
                ./home.nix
              ];
            };

            # Pass arguments to home.nix
            home-manager.extraSpecialArgs = args;
          }
        ];
      };
    };
  };
}
