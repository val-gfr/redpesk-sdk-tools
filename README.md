# RedPesk LocalBuilder installer

Simply launch 

```
./install.sh create <your_container_name>
```
and follow the instructions.

You will be prompted for your host's root password to perform the installation of LXD
You will also been asked to enter the Redpesk Image Store password that you have been
given.

At the end of the script, you will also be asked for an optionnal host directory that 
you want to have to access to within the container.

Depending of your host's distribution, you may need to relaunch the script after a reboot or not.

```
./install.sh clean <your_container_name>
```

can be useful when things go bad.

Once the container is created, is is accessible through ssh:

```
ssh devel@${container_name}
passwd:*devel*
```


