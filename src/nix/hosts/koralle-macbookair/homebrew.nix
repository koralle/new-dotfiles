{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [ ];

    casks = [
      {
        # Ghostty
        # https://github.com/ghostty-org/ghostty
        name = "ghostty";
      }
      {
        # Google Chrome
        name = "google-chrome";
      }
      {
        # OpenCode Desktop
        name = "opencode-desktop";
      }
      {
        # Discord
        name = "discord";
      }
      {
        # Aerospace
        # https://github.com/nikitabobko/AeroSpace
        name = "nikitabobko/tap/aerospace";
      }
    ];
  };
}
