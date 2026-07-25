{pkgs, ...}: {
  imports = [./base-cli.nix];

  home.packages = with pkgs; [
    ## Better core utils
    gping # ping with a graph
    gtrash # rm replacement, put deleted files in system trash
    # hexyl # hex viewer
    man-pages # extra man pages
    ncdu # disk space
    tldr
    tmuxinator

    ## Tools / useful cli
    aoc-cli # Advent of Code command-line tool
    asciinema
    asciinema-agg
    binsider
    bitwise # cli tool for bit / hex manipulation
    broot # tree files view
    caligula # User-friendly, lightweight TUI for disk imaging
    hyperfine # benchmarking tool
    pastel # cli to manipulate colors
    swappy # snapshot editing tool
    tdf # cli pdf viewer
    tokei # project line counter
    translate-shell # cli translator
    woomer
    yt-dlp-light

    ## TUI
    epy # ebook reader
    gtt # google translate TUI
    programmer-calculator
    toipe # typing test in the terminal
    ttyper # cli typing test

    # System Utilities (User-facing)
    inetutils

    # Disk Monitoring & Analysis
    # gsmartcontrol # GUI SMART monitoring (CrystalDiskInfo alternative)
    # smartmontools # Command-line SMART monitoring
    nvme-cli # NVMe-specific tools
    # hdparm # Hard disk parameters tool

    ## Monitoring / fetch
    # htop
    onefetch # fetch utility for git repo
    wavemon # monitoring for wireless network devices

    ## Fun / screensaver
    # asciiquarium-transparent
    cbonsai
    cmatrix
    # countryfetch
    # cowsay
    figlet
    fortune
    lavat
    lolcat
    pipes
    sl
    tty-clock

    ## Multimedia
    imv
    lowfi
    mpv

    ## Utilities
    entr # perform action when file change
    # croc # file transfer over the network
    ttyd # Terminal over HTTP
    ffmpeg
    file # Show file information
    killall
    libnotify
    mimeo
    openssl
    pamixer # pulseaudio command line mixer
    playerctl # controller for media players
    poweralertd
    wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
    cliphist # Wayland clipboard history manager

    winetricks
    wineWowPackages.waylandFull
  ];
}
