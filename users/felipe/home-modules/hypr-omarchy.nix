{
  config,
  pkgs,
  ...
}: {
  # Use Omarchy's Hyprland configuration directly from the cloned repo.
  # This assumes the repo is at ~/omarchy.
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/omarchy/config/hypr";

  # Provide the default Omarchy Hyprland config set under the path it expects.
  home.file.".local/share/omarchy/default/hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/omarchy/default/hypr";

  # Choose a theme and expose it as the current Omarchy theme.
  # You can change `catppuccin-latte` to any other directory under omarchy/themes.
  home.file.".config/omarchy/current/theme".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/omarchy/themes/catppuccin-latte";

  # Ensure a background image exists where Hyprland expects it
  home.file.".config/omarchy/current/background".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/omarchy/themes/catppuccin-latte/backgrounds/1-catppuccin-latte.png";

  # Omarchy Waybar configuration
  xdg.configFile."waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/omarchy/config/waybar";

  # Minimal Hyprland autostart overriding the default uwsm-based commands
  # so that at least a bar and background are started under NixOS.
  home.file.".config/hypr/autostart.conf".text = ''
    exec-once = waybar
    exec-once = swaybg -i ~/.config/omarchy/current/background -m fill
  '';

  # Simple, NixOS-friendly keybindings that don't depend on Omarchy's uwsm env.
  # These are layered on top of the Omarchy defaults and ensure you can start
  # essential apps even if $terminal or other variables are unset.
  home.file.".config/hypr/bindings.conf".text = ''
    # Launch terminal
    bind = SUPER, RETURN, exec, kitty

    # Launch browser
    bind = SUPER, B, exec, brave

    # Exit Hyprland
    bind = SUPER, Q, exec, hyprctl dispatch exit 0
  '';
}
