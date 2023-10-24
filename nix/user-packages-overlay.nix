# https://gist.github.com/LnL7/570349866bb69467d0caf5cb175faa74
# enable overlay and bootrap with command `nix-env -f '<nixpkgs>' -r -iA userPackages`
self: super:
{
  userPackages = super.userPackages or {} // {
    # My packages
    inherit (self)
      maven
      # gitMinimal
      gzip
      xz
      tree
      htop
      nodejs-10_x
      yarn
      stern
      direnv
      ffmpeg
    ;

    # haskellPackages
    inherit (self)
      stack
      ghcid
      ormolu
      hlint
      cabal2nix
    ;

    # ghcide = super.haskell.lib.justStaticExecutables self.haskellPackages.ghcide;
    ghcide = super.haskell.lib.justStaticExecutables self.haskell.packages.ghc8102.ghcide;

    # Default packages
    inherit (self)
      cacert
      nix
    ;

    nix-rebuild = super.writeScriptBin "nix-rebuild" ''
      #!${super.stdenv.shell}
      set -e
      if ! command -v nix-env &>/dev/null; then
        echo "warning: nix-env was not found in PATH, add nix to userPackages" >&2
        PATH=${self.nix}/bin:$PATH
      fi
      IFS=- read -r _ oldGen _ <<<"$(readlink "$(readlink ~/.nix-profile)")"
      oldVersions=$(readlink ~/.nix-profile/package_versions || echo "/dev/null")
      nix-env -f '<nixpkgs>' -r -iA userPackages "$@"
      IFS=- read -r _ newGen _ <<<"$(readlink "$(readlink ~/.nix-profile)")"
      ${self.diffutils}/bin/diff --color -u --label "generation $oldGen" $oldVersions \
        --label "generation $newGen" ~/.nix-profile/package_versions \
        || true
    '';

    packageVersions =
      let
        versions = super.lib.attrsets.mapAttrsToList (_: pkg: pkg.name) self.userPackages;
        versionText = super.lib.strings.concatMapStrings (s: s+"\n") versions;
      in
      super.writeTextDir "package_versions" versionText;
  };
}