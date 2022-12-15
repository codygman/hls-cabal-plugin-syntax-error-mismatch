{
  description = "Single file Lambda Calculus implementations and presentation slides.";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
    amazonka = {
      url = "https://github.com/brendanhay/amazonka/archive/0d70474d888c5e5a43417ac9f7b408e7890ff853.tar.gz";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    amazonka
  }: let
    utils = flake-utils.lib;
  in
    utils.eachDefaultSystem (system: let
      compilerVersion = "ghc925";
      pkgs = nixpkgs.legacyPackages.${system};
      
      amazonkaLib = hpkgs: name:
        hpkgs.callCabal2nix name "${amazonka}/lib/${name}";
      amazonkaService = hpkgs: name:
        hpkgs.callCabal2nix name "${amazonka}/lib/services/${name}";
      
      hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
        overrides = hfinal: hprev: {
          hithere = hfinal.callCabal2nix "hithere" ./. {};

          # adding a complicated dependency from git that consists of multiple haskell projects in a monorepo
          amazonka = amazonkaLib hfinal "amazonka" { };
          amazonka-core = amazonkaLib hprev "amazonka-core" { };
          amazonka-test = amazonkaLib hprev "amazonka-test" { };
          amazonka-sso = amazonkaService hfinal "amazonka-sso" { };
          amazonka-sts = amazonkaService hfinal "amazonka-sts" { };

          # disabling testing of a certain package from your compilers version of pkgs.haskellPackages
          ## ex. ListLike is getting compiled and taking *forever*
          ListLike = pkgs.haskell.lib.dontCheck hprev.ListLike;

          # unbreaking a package in nixpkgs and jailbreaking/loosening bounds
          evoke = pkgs.haskell.lib.markUnbroken (pkgs.haskell.lib.doJailbreak hprev.evoke);

          # TODO adding a package from hackage directly, but jailbreaking
        };
      };
    in rec {
      packages =
        utils.flattenTree
        {hithere = hsPkgs.hithere;};

      # nix develop
      devShell = hsPkgs.shellFor {
        withHoogle = true;
        packages = p: [
          p.hithere
        ];
        buildInputs = with pkgs;
          [
            hsPkgs.haskell-language-server
            hsPkgs.cabal-install
            # cabal2nix
            hsPkgs.ghcid
            hsPkgs.fourmolu
            haskellPackages.cabal-fmt
          ];
      };

      # nix build
      defaultPackage = packages.hithere;
    });
}
