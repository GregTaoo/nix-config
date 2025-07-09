{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = { 
    self, 
    nixpkgs, 
    home-manager, 
    nix-darwin,
    nixos-wsl,
    ...
  } @ inputs: 
  let
    inherit (self) outputs;
    settings = import ./settings.nix;
    arguments = { inherit inputs outputs settings; };
  in {
    nixosConfigurations = {
      "${settings.hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = arguments;

        modules = [
          # System config
          ./nixos/configuration.nix

          # Include self-defined modules.
          ./nixos/os-modules.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${settings.username} = {
              imports = [ ./nixos/home.nix ];
            };

            # Pass arguments to home.nix
            home-manager.extraSpecialArgs = arguments;
          }
        ];
      };
      "${settings.wslHostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = arguments;

        modules = [
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.05";
            wsl.enable = true;
          }
          ./wsl/configuration.nix

          ./wsl/os-modules.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${settings.username} = {
              imports = [ ./wsl/home.nix ];
            };

            # Pass arguments to home.nix
            home-manager.extraSpecialArgs = arguments;
          }
        ];
      };
    };

    darwinConfigurations = {
      "${settings.darwinHostName}" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = arguments;

        modules = [ 
          ./darwin/configuration.nix

          ./darwin/os-modules.nix

          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${settings.username} = {
              imports = [ ./darwin/home.nix ];
            };

            # Pass arguments to home.nix
            home-manager.extraSpecialArgs = arguments;
          }
        ];
      };
    };
  };
}
