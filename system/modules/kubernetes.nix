{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.kubernetes-tools;
in {
  options.kubernetes-tools = {
    enable = mkEnableOption "Kubernetes tooling (kubectl, minikube)";

    kubeconfigPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/felipe/.kube/config";
      description = "If set, exports KUBECONFIG system-wide to this path.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        kubectl
        minikube
      ];
      description = "Kubernetes-related packages to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkAfter cfg.packages;

    environment.sessionVariables = mkIf (cfg.kubeconfigPath != null) {
      KUBECONFIG = cfg.kubeconfigPath;
    };
  };
}
