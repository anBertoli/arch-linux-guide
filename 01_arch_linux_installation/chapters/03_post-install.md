# ⚙️ Post installation

## Install graphical environment
To run programs with graphical user interfaces on your system, you'll have to install an 
X Window System implementation. The most common one is Xorg. To install Xorg, execute the
following command.

```shell
$ pacman -S xorg-server
```

Then you need to install graphic drivers, depending on your graphic card.

```shell
# for nvidia graphics processing unit
$ pacman -S nvidia nvidia-utils
# for amd discreet and integrated graphics processing unit
$ pacman -S xf86-video-amdgpu
# for intel integrated graphics processing unit
$ pacman -S xf86-video-intel
```

Finally install the desktop environment.

```shell
$ pacman -S plasma
```

Like gdm in GNOME, Plasma comes with `sddm` as the default display manager. A display manager, 
or login manager, is typically a graphical user interface that is displayed at the end of the
boot process in place of the default shell. 

Execute the following command to enable the service.

```shell
$ systemctl enable sddm
```

Alternatively, Plasma can start at boot immediately after the X server. See:
https://wiki.archlinux.org/title/KDE#From_the_console