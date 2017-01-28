# vyos-igw-config
Internet gateway configuration for VyOS

## Requirements

* At least one ethernet interface set up
* Enabled SSH (`set service ssh port "22"`)
* SSH client

## Deployment

**VyOS default login :** vyos/vyos

```bash
$ git clone https://github.com/BastienM/vyos-igw-config.git
$ scp vyos-igw-config vyos@<vyos_ip>:~
$ ssh vyos@<vyos_ip>

vyos@vyos:~$ cd vyos-igw-config
vyos@vyos:~$ vbash configuration
```
