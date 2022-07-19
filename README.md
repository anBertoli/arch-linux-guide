# Arch Linux Guide

### Network

#### Wireless connection

At this point the system should have the wpa_supplicant package (`wpa_supplicant`, `wpa_cli`, `wpa_passphrase`, to 
connect and authenticate to a wireless access point, provided by the base arch installation), `dhcpcd` (dhcp client,
installed previously).

Check if the driver for your card has been loaded, check the output of the `lspci -k` or `lsusb -v`, something 
similar should appear in the drivers list:
```shell
$ lspci -k
```
```markdown
06:00.0 Network controller: Intel Corporation WiFi Link 5100
 	Subsystem: Intel Corporation WiFi Link 5100 AGN
 	Kernel driver in use: iwlwifi
 	Kernel modules: iwlwifi
```

Check if a corresponding network interface was created, usually the naming of the wireless network interfaces starts 
with the letter "w", e.g. wlan0 or wlp2s0:
```shell
$ ip link show
```
```markdown
<your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT qlen 1000
   link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Then the network interface should be brought up with:
```shell
$ ip link set <your-interface> up
```

Check again the interface status to spot the UP keyword at the beginning of the row with `ip link`:
```shell
$ ip link show
```
```markdown
<your-interface>: <BROADCAST,MULTICAST,*UP*,LOWER_UP> ....
```