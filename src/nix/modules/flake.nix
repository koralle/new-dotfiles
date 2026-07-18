{
  inputs,
  pkgs,
  username,
  ...
}:
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
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.11";

    packages = with pkgs; [
      # https://github.com/jonas/tig
      tig

      # https://fishshell.com/
      fish
    ];
  };
}
