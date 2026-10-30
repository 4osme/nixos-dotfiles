# PipeWire (the source host runs PipeWire + WirePlumber; the Dux Shell OSD
# and EasyEffects talk to it). The quantum/buffer tuning follows the audio
# thread instead of the power-saving clock: the min/max bracket matches
# pulse.min/max.quantum so PipeWire can ride the source's sample rate
# (44.1k/48k/96k) with a stable 2048-sample quantum.
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    wireplumber.extraConfig = {
      "10-disable-suspension" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                "node.name" = "~alsa_output.*";
              }
            ];
            apply_properties = {
              # 0 = never suspend the device (kills click/pops after idle).
              "session.suspend-timeout-seconds" = 0;
            };
          }
        ];
      };
    };

    extraConfig.pipewire = {
      "10-clock-rate" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          # Ride the source's sample rate instead of resampling.
          "default.clock.allowed-rates" = [
            44100
            48000
            96000
          ];
          "default.clock.quantum" = 2048;
          "default.clock.min-quantum" = 512; # low enough for latency-sensitive apps
          "default.clock.max-quantum" = 2048;
        };
      };
    };

    extraConfig.pipewire-pulse = {
      "10-pulse-buffer" = {
        "pulse.properties" = {
          "pulse.min.req" = "2048/48000";
          "pulse.min.quantum" = "2048/48000";
          "pulse.max.quantum" = "2048/48000";
        };
      };
    };
  };

  security.rtkit.enable = true;

  # Audio threads get real-time priority and never mlock-fail.
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@wheel";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
  ];

  # Keep USB audio interfaces awake — power saving shows up as xrun clicks.
  boot.kernelParams = [ "snd_usb_audio.power_save=0" ];
}
