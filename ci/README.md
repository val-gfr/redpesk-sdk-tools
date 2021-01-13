# Vagrant CI

## How to setup your Vagrant CI

### Select your OS

```bash
OS=ubuntu_18.04
OS=ubuntu_18.10
OS=ubuntu_20.04
OS=ubuntu_20.10

OS=debian_10

OS=opensuse_15.2

OS=fedora_32
OS=fedora_33
```

### Quick test

For a quick test just do:

```bash
cd ${OS_FAMILY}/${OS}
vagrant up
```

### Init your Vagrant VM

```bash
cd ${OS_FAMILY}/${OS}
vagrant up --no-provision
#Save your initial stat
vagrant snapshot save ${OS}
```

### Execute your test

In one command line exec your test

```bash
vagrant up --no-provision
vagrant provision
```

### Clean up your mess

This will reset all your change:

```bash
vagrant snapshot restore ${OS} --no-provision
vagrant halt
```

### Debug your Vagrant CI

You can easily debug your Vagrant CI with the command:

```bash
vagrant ssh
```

### Clean every thing

```bash
vagrant destroy
```
