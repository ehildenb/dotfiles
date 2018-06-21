{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pciutils usbutils acpi parted lm_sensors
    wpa_supplicant iw dhcpcd sudo pmutils
    gnumake gcc llvmPackages.clang binutils
    cabal-install stack ghc
    wget vim w3m zsh tmux git kakoune htop nmap
    notmuch offlineimap msmtp
    cmus alsaUtils rtorrent mpv youtube-dl
    pandoc texlive.combined.scheme-full hledger
    xorg.xinit xorg.xorgserver xorg.xf86inputevdev xorg.xf86videointel
    i3 rxvt_unicode mupdf firefox inconsolata
    python3 bc dos2unix
  ];
}
