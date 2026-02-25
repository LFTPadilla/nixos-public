{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../system/hardware-configuration.nix
  ];

  # Use proprietary NVIDIA driver with PRIME offloading on the MSI laptop
  services.xserver.videoDrivers = ["nvidia"];

  # NVIDIA proprietary driver with PRIME offloading (Intel iGPU + NVIDIA dGPU)
  hardware.nvidia = {
    # Required for Xorg/GBM
    modesetting.enable = true;
    # Helpful on laptops to save power when idle
    powerManagement.enable = true;
    # Pascal (GTX 1070) does not support the open kernel module
    open = false;
    # Include nvidia-settings and ensure userland tools are present
    nvidiaSettings = true;
    # Track NVIDIA's production branch compatible with the running kernel
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # PRIME render offload (run apps on dGPU via nvidia-offload)
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0"; # 00:02.0 Intel UHD 630
      nvidiaBusId = "PCI:1:0:0"; # 01:00.0 GTX 1070 Mobile
    };
  };

  # Prevent the nouveau driver from binding the NVIDIA GPU
  boot.blacklistedKernelModules = ["nouveau"];

  # Disable NVIDIA container toolkit for now to avoid pulling CUDA compat,
  # which requires a manually provided source and breaks builds.
  hardware.nvidia-container-toolkit.enable = false;

  # Host-specific packages
  environment.systemPackages = lib.mkAfter [
    pkgs.losslesscut-bin
  ];

  # Safe automatic system updates (flake-aware) for the MSI profile
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "/home/felipe/.dotfiles#default-msi";
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "09:00";
    randomizedDelaySec = "45min";
  };
}
