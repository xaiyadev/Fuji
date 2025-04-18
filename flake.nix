{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        devenv-test = self.devShells.${system}.default.config.test;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  packages = [
                    pkgs.libGL
                    pkgs.xorg.libX11
                    pkgs.fontconfig
                  ];

                  languages = {
                    kotlin.enable = true;
                    java = {
                      enable = true;
                      jdk.package = pkgs.jetbrains.jdk; # newest jdk version with better support for jetbrains products
                      gradle.enable = true;
                    };
                  };

                  scripts.run-main.exec = ''
                   LD_LIBRARY_PATH=${pkgs.libGL}/lib/ ${pkgs.jetbrains.jdk}/lib/openjdk/bin/java
                  '';
                }
              ];
            };
          });
    };
}
