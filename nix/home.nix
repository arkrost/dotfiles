{ pkgs, lib, ... }:
let
  sources = import ./_sources/generated.nix { inherit (pkgs) fetchurl fetchgit fetchFromGitHub; };
in {
  home.packages = [
    pkgs.nvfetcher
    pkgs.atool
    pkgs.yt-dlp
    pkgs.ffmpeg
    pkgs.rustup

    pkgs.go_1_18
    pkgs.gopls

    pkgs.stern
    pkgs.maven
    pkgs.nodejs-16_x

    pkgs.fortune
    pkgs.bat
    pkgs.exa
    pkgs.ripgrep
    pkgs.fd
    pkgs.delta
  ];

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    initExtra = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ../zsh/zshrc)
      (builtins.readFile ../zsh/almrc)
      "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    ];

    # plugins = map ({pname, src,...}: { inherit src; name = pname; }) (with sources; [
    #   zsh-autopair
    #   zsh-z
    #   fzf-tab
    # ]);
  };

  programs.fzf.enable = true;

  programs.fish = {
    enable = true;

    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./fishrc)
      "fenv source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'"
    ];

    plugins = map ({pname, src,...}: { inherit src; name = pname; }) (with sources; [
      fish-z
      fish-dracula
      fish-foreign-env
    ]);
  };

  programs.git = {
    enable = true;
    extraConfig = {
      include = {
        path = pkgs.copyPathToStore ../git/config;
      };
    };
  };

  programs.neovim = {
    enable = true;

    extraConfig = (import ./vim-config.nix) {};

    plugins = map ({pname, src,...}: pkgs.vimUtils.buildVimPlugin { inherit src; name = pname; }) (with sources; [
      nvim-darcula
      nvim-git-blame
    ]);
  };

  xdg.configFile."nix/nix.conf".source = ./nix.conf;
  home.file.".cloud".source = ./cloud;

  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-10.24.1"
  ];

  home.stateVersion = "22.05";
}

