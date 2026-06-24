{ config, ... }:

{
  systemd.user.services.battery-monitor = {
    Unit = {
      Description = "Monitor battery level and send notifications";
    };
    Service = {
      Type = "oneshot";
      # This assumes your dotfiles repo is in your home directory.
      # Adjust the path if that's not the case.
      ExecStart = "${config.home.homeDirectory}/.dotfiles/bin/battery-monitor";
    };
  };

  systemd.user.timers.battery-monitor = {
    Unit = {
      Description = "Run battery-monitor service every 30 seconds";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
      Unit = "battery-monitor.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
