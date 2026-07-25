# Example private hosts configuration.
#
# Copy to private-hosts.nix and add real entries. The real file is git-crypt
# encrypted, so on a machine without the key it stays ciphertext and cannot be
# evaluated; CI substitutes this example to evaluate the hosts that import it.
#
# This must evaluate to a STRING, not an attrset. Callers use it as
# `networking.extraHosts = import ./private-hosts.nix;` (hosts/main) and as
# `${import ../../system/private-hosts.nix}` (hosts/mac).
''
  # Development hosts
  # 127.0.0.1 myapp-dev.local
  # 127.0.0.1 api-dev.local

  # Production/staging server IPs (if needed)
  # 10.0.0.100 prod-server1
  # 10.0.0.101 staging-server1

  # Client development domains
  # 127.0.0.1 client-dev.local
''
