{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, home-manager, nixpkgs }: {
    homeConfigurations.pandora = home-manager.lib.homeManagerConfiguration {
      modules = [ ./arost.nix ./home.nix ];
      pkgs = nixpkgs.legacyPackages.x86_64-darwin;
    };
  };
}