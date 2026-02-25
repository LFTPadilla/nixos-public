{pkgs ? import <nixpkgs> {}}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      pip
      virtualenv
      setuptools
      wheel
    ]);
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      pythonEnv
      pulumi-bin
      nodejs
      awscli2
      postgresql_15
      gcc
      pkg-config
      openssl
    ];

    shellHook = ''
      # Create a project-specific virtual environment in .venv
      if [ ! -d .venv ]; then
        python -m venv .venv
        echo "Created new virtual environment"
      fi

      # Activate the virtual environment
      source .venv/bin/activate

      # Upgrade pip and essential tools
      python -m pip install --upgrade pip setuptools wheel --quiet

      # Set environment variables
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
      export PATH="${pkgs.pulumi-bin}/bin:$PWD/.venv/bin:$PATH"
      export PYTHONPATH=""
      export PIP_DISABLE_PIP_VERSION_CHECK=1

      # Set up Pulumi environment
      export PULUMI_HOME=$HOME/.pulumi
      export XDG_CACHE_HOME=$HOME/.cache
      mkdir -p $PULUMI_HOME
      mkdir -p $XDG_CACHE_HOME/pulumi

      # Install Pulumi SDK first
      pip install 'pulumi>=3.0.0,<4.0.0' 'pulumi-aws>=6.0.2,<7.0.0' --quiet
      pip install pulumi_command

      export AWS_PROFILE=nixos-deployer

      # Then install other requirements (from aws/requirements.txt)
      if [ -f aws/requirements.txt ]; then
        # Filter out pulumi packages as they're already installed
        grep -v -E "^(pulumi|aws-cli|#)" aws/requirements.txt | grep -v "^$" > .requirements.clean.txt || true

        if [ -s .requirements.clean.txt ]; then
          pip install -r .requirements.clean.txt --quiet
          rm .requirements.clean.txt
        fi
      fi

      # Verify Pulumi installation
      if python -c "import pulumi" 2>/dev/null; then
        echo "✓ Pulumi SDK installed successfully"
      else
        echo "⚠ Pulumi SDK installation failed"
        exit 1
      fi

      echo "Development environment ready!"
      echo "AWS CLI: $(aws --version)"
      echo "Pulumi: $(pulumi version)"
      echo "Node.js: $(node --version)"
      echo "Python: $(python --version)"
    '';

    # Preserve these environment variables
    NIX_SHELL_PRESERVE_PROMPT = 1;
  }
