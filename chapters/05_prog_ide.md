# 📚 Programming languages and IDEs

## 🦫 Go

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

Add /usr/local/go/bin to the PATH environment variable. You can do this by adding the 
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

## 🦀 Rust


```shell

```

```shell

```