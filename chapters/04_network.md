## Network

### Wireless connection

At this point the system should have the wpa_supplicant package (`wpa_supplicant`, `wpa_cli`, `wpa_passphrase`, to 
connect and authenticate to a wireless access point, provided by the base arch installation), `dhcpcd` (dhcp client,
installed previously).

Check if the driver for your card has been loaded, check the output of the `lspci -k` or `lsusb -v`, something 
similar should appear in the drivers list:
```shell
$ lspci -k
# 06:00.0 Network controller: Intel Corporation WiFi Link 5100
#  	Subsystem: Intel Corporation WiFi Link 5100 AGN
#  	Kernel driver in use: iwlwifi
# 	Kernel modules: iwlwifi
```

Check if a corresponding network interface was created, usually the naming of the wireless network interfaces starts 
with the letter "w", e.g. wlan0 or wlp2s0:
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

Create the `/etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf` file with the following content. This will allow
_wpa_cli_ to update the config file when needed:
```bash
$ touch /etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf
```
```markdown
ctrl_interface=/run/wpa_supplicant
update_config=1
```

Now start `wpa_supplicant` on the right network interface with:
```shell
$ wpa_supplicant -B -i <your-interface> -c /etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf
```

Now `wpa_cli` can be started and used to configure the connection:
```shell
$ wpa_cli

# scan the wireless networks
> scan
> scan_results
# to associate with <my-ssid>, add the network, set the credentials and enable it
> add_network
0
> set_network 0 ssid "<my-ssid>"
> set_network 0 psk "<passphrase>"
> enable_network 0
# check for something like:
# <2>CTRL-EVENT-CONNECTED - Connection to 00:00:00:00:00:00 completed (reauth) [id=0 id_str=]

# now save the config to the file previously created
> save_config
# OK
> quit
```

The file `/etc/wpa_supplicant/wpa_supplicant_<your-interface>.conf` should have been updated with a network block 
for that wireless network. The network interface should be UP in both places in the output of the `ip link` command:
```shell
$ ip link show
#                                        here                                 here
#                                        |                                    |
# <your-interface>: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT qlen 1000
#   link/ether 00:60:64:37:4a:30 brd ff:ff:ff:ff:ff:ff
```

Now your network card/something is connected and authenticated to the wireless network, but you don't have an IP yet,
nor a valid route in the routing table or DNS servers set. The fastest way to this is to use a DHCP client as follows:
```shell
$ dhcpcd <your-interface>
```

### Wireless connection at boot

Several systemd units are provided from both `wpa_supplicant` and `dhcpcd` to automate connection at boot.

For `wpa_supplicant` the unit _wpa_supplicant@interface.service_ accepts the interface name as an argument 
and starts the _wpa_supplicant_ daemon for this interface. It reads a `/etc/wpa_supplicant/wpa_supplicant-<your-interface>.conf` 
configuration file (created previously if the steps above are followed)

Copy the template file and enable it (it could be in different places based on your system, but this should work):
```shell
$ cp /usr/lib/systemd/system/wpa_supplicant@.service /usr/lib/systemd/system/wpa_supplicant@<your-interface>.service
$ systemctl enable wpa_supplicant@<your-interface>
```

For the DHCP client is even easier, just enable the _dhcpcd_ systemd unit. Note that in some cases it could be necessary
to create and activate an interface-specific unit (template at /usr/lib/systemd/system/dhcp@.service_).  
```shell
$ systemctl enable dhcpcd
```

Reboot and check if everything works.