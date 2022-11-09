# 📚 Programming languages and IDEs

## 🦫 Go & Goland

### Install Go

Before installing Go update all system packages.
```shell
$ sudo pacman -Syu
```

Proceed cleaning the old Go installation, downloading the desired version fo Go,
extracting and installing it.

```shell
# choose the desired version
GO_VER=1.19.3

# remove old Go installation
$ rm -rf /usr/local/go

# download the Go language archive and install it 
$ curl -L --output ./go${GO_VER}.linux-amd64.tar.gz https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
$ tar -C /usr/local -xzf ./go${GO_VER}.linux-amd64.tar.gz
```

Add `/usr/local/go/bin` to the PATH environment variable. You can do this by adding the 
following line to your `$HOME/.profile` or `/etc/profile` (for a system-wide installation).

```shell
# add the line using redirection or do it manually using vim
$ echo "export PATH=${PATH}:/usr/local/go/bin" >> $HOME/.profile
$ source $HOME/.profile
```

Confirm everything is working.

```shell
$ go version
```

### Install Goland

To install Goland download it from the jetbrains.com site, decompress and extract the archive,
copy the contents into a proper directory.

```bash
GOLAND_VER="2022.2.4"
$ curl -L --output ./goland-${GOLAND_VER}.tar.gz https://download.jetbrains.com/go/goland-${GOLAND_VER}.tar.gz
$ tar xzf ./goland-${GOLAND_VER}.tar.gz -C /opt/
```

To run the IDE run the `goland.sh` script. You can eventually add this path to the PATH env 
var. During the first launch Goland will ask you to authenticate or provide the license.

```bash
$ /opt/goland-${GOLAND_VER}/bin/goland.sh
```

## 🦀 Rust & CLion

### Install Rust

The primary way that folks install Rust is through a tool called Rustup, which is a Rust 
installer and version management tool. When you install Rustup you’ll also get the latest
stable version of the Rust build tool and package manager, also known as Cargo.

```shell
# install rustup, rust and cargo
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# can be run in the future to get rustup updates
$ rustup update

# check it worked
$ cargo --version
```

In the Rust development environment, all tools are installed to the `~/.cargo/bin` directory, 
and this is where you will find the Rust toolchain, including rustc, cargo, and rustup.

During installation rustup will attempt to configure the PATH adding this folder. Because of 
differences between platforms, command shells, and bugs in rustup, the modifications to 
PATH may not take effect until the console is restarted, or the user is logged out, or it 
may not succeed at all. 

If the automatic configuration failed, add `~/.cargo/bin` to PATH manually. Add the 
following line to your `$HOME/.profile` or `/etc/profile` (for a system-wide installation).

```shell
# add the line using redirection or do it manually using vim
$ echo "export PATH=${PATH}:~/.cargo/bin" >> $HOME/.profile
$ source $HOME/.profile

# check again
$ cargo --version
```

### Install CLion

To install CLion download it from the jetbrains.com site, decompress and extract the archive,
copy the contents into a proper directory.

```bash
CLION_VER="2022.2.4"
$ curl -L --output ./clion-${CLION_VER}.tar.gz https://download.jetbrains.com/cpp/CLion-${CLION_VER}.tar.gz
$ tar xzf ./clion-${CLION_VER}.tar.gz -C /opt/
```

To run the IDE run the `clion.sh` script. You can eventually add this path to the PATH env var.
During the first launch CLion will ask you to authenticate or provide the license.

```bash
$ /opt/clion-${CLION_VER}/bin/clion.sh
```

Inside the CLion IDE you must install the Rust plugin to allow the IDE to fully support Rust.


## 🐳 Docker

Install the `docker` and `docker-compose` packages. Next start and enable the `docker.service` 
and verify it works.

```shell
$ pacman -Sy docker
$ pacman -Sy docker-compose

$ systemctl start docker
$ systemctl enable docker

$ sudo docker info
```

Next, verify that you can run containers. The following command downloads the latest Arch 
Linux image and uses it to run a _hello world_ program within a container:

```shell
$ sudo docker run -it --rm alpine sh -c "echo hello world"
```

If you want to be able to run the docker CLI command as a non-root user, add your user to 
the `docker` user group, re-login, and restart `docker.service`.

```shell
$ sudo usermod -a -G docker <user>
$ cat /etc/group # verify it worked
```