# Example private hosts configuration
# Copy this file to private-hosts.nix and add your actual hosts
{
  extraHosts = ''
    # Development hosts
    # 127.0.0.1 myapp-dev.local
    # 127.0.0.1 api-dev.local

    # Production/staging server IPs (if needed)
    # 10.0.0.100 prod-server1
    # 10.0.0.101 staging-server1

    # Client development domains
    # 127.0.0.1 client-dev.local
  '';
}
