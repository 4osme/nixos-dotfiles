# PipeWire (the source host runs PipeWire + WirePlumber; the shell's OSD and
# EasyEffects talk to it).
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;
}
