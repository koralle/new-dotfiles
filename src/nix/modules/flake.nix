{ inputs, pkgs, ... }:
{
  imports = [
    ./neovim/flake.nix
  ];

  programs = {
    home-manager = {
      enable = true;
    };
  };

  home = {
    packages = with pkgs; [
      # https://github.com/jonas/tig
      tig
    ];
  };
}
