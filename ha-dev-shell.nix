{pkgs ? import <nixpkgs> {}}: let
  python-with-packages = pkgs.python3.withPackages (p:
    with p; [
      jupyter
      pip
      setuptools
    ]);
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      python-with-packages
      stdenv.cc.cc.lib
      zlib
      libffi
      openssl
    ];
    # nix-shell ha-dev-shell.nix
    shellHook = ''
      export PIP_PREFIX=$PWD/.venv
      export PYTHONPATH="$PIP_PREFIX/${python-with-packages.sitePackages}:$PYTHONPATH"
      export PATH="$PIP_PREFIX/bin:$PATH"
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libffi}/lib:${pkgs.openssl}/lib:$LD_LIBRARY_PATH"

      # Set Jupyter paths to user directory
      export JUPYTER_CONFIG_DIR=$HOME/.jupyter
      export JUPYTER_DATA_DIR=$HOME/.local/share/jupyter
      export JUPYTER_RUNTIME_DIR=$HOME/.local/share/jupyter/runtime

      mkdir -p $PIP_PREFIX
      mkdir -p $JUPYTER_DATA_DIR/kernels


      echo "export JUPYTER_PATH='$PWD/.venv/share/jupyter:$HOME/.local/share/jupyter'"
      echo "nix-shell ha-dev-shell.nix"
      echo "jupyter lab --no-browser --ip=127.0.0.1"
    '';
  }
