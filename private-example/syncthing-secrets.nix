# EXAMPLE FILE - DO NOT USE AS-IS
# Copy to /etc/nixos/private/syncthing-secrets.nix and customize with your devices
# Get device IDs from each device: Syncthing web UI -> Actions -> Show ID

{
  gui = {
    user = "ppb1701";  # Change to your username
    password = "CHANGE_ME_TO_STRONG_PASSWORD";
  };

  prometheus_auth = {
    username = "your-syncthing-username";
    password = "your-syncthing-password";
  };

  devices = {
    # Add your devices here
    # "my-laptop" = {
    #   id = "ABCDEFG-HIJKLMN-OPQRSTU-VWXYZAB-CDEFGHI-JKLMNOP-QRSTUVW-XYZABCD";
    # };
  };

  folders = {
    # Add your sync folders here
    # "Documents" = {
    #   path = "/home/ppb1701/Documents";
    #   devices = [ "my-laptop" ];
    # };
  };
}
