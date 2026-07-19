{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      # GitHub CLI
      # https://cli.github.com/
      "gh"

      # betterleaks
      # https://github.com/betterleaks/betterleaks
      "betterleaks"

      "direnv"

      "libsql/sqld/sqld"
      "tursodatabase/tap/turso"
    ];

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
      {
        # Firefox
        # https://github.com/mozilla-firefox/firefox
        name = "firefox";
      }
      {
        # Raycast
        # https://www.raycast.com/
        name = "raycast";
      }
      {
        # Zed
        # https://github.com/zed-industries/zed
        name = "zed";
      }
      {
        # Tailscale
        name = "tailscale-app";
      }
      {
        # Podman Desktop
        name = "podman-desktop";
      }
      {
        # Docker Sandboxes (sbx)
        # https://docs.docker.com/ai/sandboxes/
        name = "docker/tap/sbx";
      }
    ];
  };
}
