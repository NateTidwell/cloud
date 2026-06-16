## Cloud inti configuration Guidelines

## Server

## Cloud / VMware

```yaml
instance-id: ubuntu-01
local-hostname: ubuntu-01
network:
  version: 2
  ethernets:
    ens160:
      dhcp4: no
      addresses:
        - 10.0.50.10/24
      gateway4: 10.0.50.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
fs_setup:
  - label: data
    filesystem: ext4
    device: /dev/sdb

mounts:
  - [ /dev/sdb, /mnt/data ]
package_update: true
packages:
  - docker.io
  - htop
  - unzip
runcmd:
  - systemctl enable docker
  - systemctl start docker
```

## Validation
```shell
sudo cloud-init status
sudo cloud-init status --long
sudo journalctl -u cloud-init
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
sudo cloud-id ## Should output vmware
```

#### Setup config
>[!notice] Clean server
>```shell
> sudo cloud-init clean --logs --reboot
>```

