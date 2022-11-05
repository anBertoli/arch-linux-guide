# 🌐 Network

## Wireless connection

You should install and enbale `networkmanager` if not already done previously. The package 
contains a daemon, a command line interface (`nmcli`) and a curses‐based interface (`nmtui`).

```shell
# install network manager
$ pacman -Sy networkmanager
# start network manager
$ systemctl start NetworkManager
# enable network manager to start at boot
$ systemctl enable NetworkManager
```


Before proceeding, check if the driver for your network card has been loaded, check the 
output of the `lspci -k` or `lsusb -v`, something similar should appear in the drivers list:
```shell
$ lspci -k
# 06:00.0 Network controller: Intel Corporation WiFi Link 5100
#  	Subsystem: Intel Corporation WiFi Link 5100 AGN
#  	Kernel driver in use: iwlwifi
# 	Kernel modules: iwlwifi
```

Check if a corresponding network interface was created, usually the naming of the wireless 
network interfaces starts with the letter "w", e.g. wlan0 or wlp2s0:
```shell
$ ip link show
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state DOWN mode DORMANT qlen 1000
#    link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Then the network interface should be brought up with:
```shell
$ ip link set <your-interface> up
```

Check again the interface status to spot the UP keyword at the beginning of the row with `ip link`:
```shell
$ ip link show
#                                        here
#                                        | 
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> ....
```

```shell
# see a list of network devices and their state
$ nmcli device
# list nearby Wi-Fi networks
$ nmcli device wifi list

# connect to a Wi-Fi network
$ nmcli device wifi connect <SSID_or_BSSID> password <password>
# connect to a Wi-Fi on the wlan1 interface
$ nmcli device wifi connect <SSID_or_BSSID> password <password> ifname <wlan1> <profile_name>

# get a list of connections with their names, UUIDs, types and backing devices
$ nmcli connection show
# activate a connection (i.e. connect to a network with an existing profile)
$ nmcli connection up name_or_uuid
$ delete a connection
$ nmcli connection delete name_or_uuid
```

The network interface should be UP in both places in the output of the `ip link` command:
```shell
$ ip link show
#                                        here                                 here
#                                        |                                    |
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT qlen 1000
#   link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

NetworkManager has a global configuration file at `/etc/NetworkManager/NetworkManager.conf`. 
Additional configuration files can be placed in `/etc/NetworkManager/conf.d/`. Usually no 
configuration needs to be done to the global defaults. After editing a configuration file, 
the changes can be applied by running:

```shell
$ nmcli general reload
```

Note that by default NetworkManager uses its internal DHCP client. If you want to change it 
check: https://wiki.archlinux.org/title/NetworkManager#DHCP_client
