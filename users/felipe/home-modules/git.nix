{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./git-security.nix
  ];

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.delta = {
    enable = true;
    options = {
      features = "side-by-side line-numbers";
      side-by-side = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = lib.mkDefault "Felipe Tejada";
        email = "felipe.tejada@kommit.co";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      url."git@github.com:".insteadOf = "https://github.com/";
      alias = {
        lol = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit";
        rails-console = ''docker exec -it $(docker ps -q -f name=showcase_web | head -n 1) bash -c "cd /app && bundle exec rails console"'';
        ci = "commit";
        co = "checkout";
        st = "status";
        br = "branch";
      };
      pager = {
        diff = "${pkgs.delta}/bin/delta";
        log = "${pkgs.delta}/bin/delta";
        reflog = "${pkgs.delta}/bin/delta";
        show = "${pkgs.delta}/bin/delta";
      };
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };
}
