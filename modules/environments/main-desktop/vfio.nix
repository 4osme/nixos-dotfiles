# VFIO passthrough of the Intel Arc B580 (03:00.0, 8086:e20b) plus its HDMI
# audio function (04:00.0, 8086:e2f7) for the Vypr Windows VM.
#
# The Fedora image appended `intel_iommu=on iommu=pt` with rpm-ostree and left
# the vfio binding to libvirt's managed hostdev; here the IOMMU params are
# declarative and vfio-pci binds in initrd, before xe/snd_hda_intel can grab
# the card.
{ lib, ... }:
{
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=8086:e20b,8086:e2f7"
  ];
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
}
