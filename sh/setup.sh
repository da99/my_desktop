#!/usr/bin/env sh
#
#
set -u -e -x


sudo xbps-install -S \
  jq \
  i3 i3status \
  lxappearance \
  ffmpeg \
  nerd-fonts nerd-fonts-otf nerd-fonts-ttf \
  breeze-amber-cursor-theme \
  compton \
  xdotool \
  youtube-dl \
  unzip \
  gthumb \
  make \
  readline \
  readline-devel \
  zlib \
  zlib-devel

