# RedPesk LocalBuilder installer

Simply launch 

```
./install.sh
```
and follow the instructions.

You will be prompted for yout host's root password to perform the installation of LXD
You will also been asked to enter the Redpesk Image Store password that you have been
given.

At the end of the script, you woll also be asked for an optionnal host directory that 
you want to have to access to within the container.

Depending of your host's distribution, you may need to relaunch the script after a reboot.

The default container name is redpesk-builder

```
./install.sh clean
```

can be useful when things go bad.
