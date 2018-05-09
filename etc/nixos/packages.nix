{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pciutils usbutils acpi parted lm_sensors
    wpa_supplicant dhcpcd sudo pmutils
    gnumake gcc llvmPackages.clang binutils
    cabal-install stack ghc
    wget vim w3m zsh tmux git kakoune htop nmap
    cmus alsaUtils rtorrent mpv youtube-dl
    pandoc texlive.combined.scheme-full
  ];
}
