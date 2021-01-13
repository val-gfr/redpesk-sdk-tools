# RedPesk LocalBuilder installer

```bash
# To configure Lxc on your host
./install.sh config_host
# To Install the container
./install.sh create -c <your_container_name>
```

and follow the instructions.

You will be prompted for your host's root password to perform the installation of LXD
You will also been asked to enter the Redpesk Image Store password that you have been
given.

At the end of the script, you will also be asked for an optional host directory that
you want to have to access to within the container.

Depending of your host's distribution, you may need to relaunch the script after a reboot or not.

```bash
./install.sh clean -c <your_container_name>
```

can be useful when things go bad.

Once the container is created, is is accessible through ssh:

```bash
ssh devel@${container_name}
passwd:*devel*
```

To set the environnement to compile for aarch64, do:

```bash
. /usr/aarch64-linux-gnu/cross-profile-setup-aarch64.sh
```
