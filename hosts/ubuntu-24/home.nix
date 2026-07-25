{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../system/home-terminal.nix
  ];

  home.username = lib.mkDefault "felipe";
  home.homeDirectory = lib.mkDefault "/home/felipe";

  # Bluetooth audio (WirePlumber 0.5+ API)
  xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-config.conf".text = ''
    monitor.bluez.properties = {
      bluez5.enable-sbc-xq = true
      bluez5.enable-msbc = true
      bluez5.enable-hw-volume = true
      bluez5.headset-roles = [ hsp_hs hsp_ag hfp_hf hfp_ag ]
      bluez5.hfp-offload-sco = false
    }
  '';

  xdg.configFile."tmuxinator/personal.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/tmuxinator/personal.yml";
  # Prefer /usr/bin/kitty with the *host* GL stack.
  home.file.".local/bin/kitty" = {
    executable = true;
    text = ''
      #!/bin/sh
      NIX_KITTY="${pkgs.kitty}/bin/kitty"
      GPU_ROOT="/nix/store/6nklad7qapmqf41pqc2f9vizivn66a5p-non-nixos-gpu"

      if [ -z "''${KITTY_FORCE_NIX:-}" ] && [ -x /usr/bin/kitty ]; then
        exec /usr/bin/kitty "$@"
      fi

      if [ -d "$GPU_ROOT" ]; then
        export LD_LIBRARY_PATH="$GPU_ROOT/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export LIBGL_DRIVERS_PATH="$GPU_ROOT/lib/dri"
        export __EGL_VENDOR_LIBRARY_DIRS="$GPU_ROOT/share/glvnd/egl_vendor.d"
      fi
      if [ -n "''${KITTY_SOFTWARE_GL:-}" ]; then
        export LIBGL_ALWAYS_SOFTWARE=1
        export GALLIUM_DRIVER=llvmpipe
      fi

      if [ -x "$NIX_KITTY" ]; then
        exec "$NIX_KITTY" "$@"
      fi
      if [ -x /usr/bin/kitty ]; then
        exec /usr/bin/kitty "$@"
      fi
      echo "kitty: no usable binary found" >&2
      exit 127
    '';
  };
}
