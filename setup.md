
---

# Complete Guide: Using Cloud‑Init on Ubuntu 24.04 with VMware Customization Specifications

## Overview

Ubuntu 24.04 cloud images support cloud-init out of the box.\ VMware provides a metadata transport called **VMware Guestinfo**, which cloud-init can read using the **VMware DataSource**.\ This allows you to configure user accounts, networking, storage, and applications during **first boot**, just like in AWS or Azure.

This guide explains:

- What cloud-init is
- How to prepare Ubuntu for VMware-based provisioning
- How to use VMware Customization Specifications (and alternatives)
- How to embed cloud-init data into VMware Guestinfo
- How to validate, test, and troubleshoot deployments

---

# 1. What You Need

Before getting started, ensure you have:

- vSphere 7 or newer (vSphere 8+ recommended)
- Ubuntu 24.04 **cloud image** (OVA or QCOW2 converted to VMDK)
- Administrator access to vCenter
- Ability to create/edit VM Customization Specifications or VMX advanced settings

---

# 2. Understanding How Cloud‑Init Works on VMware

cloud-init reads metadata and user-data from one of several "datasources."\ For VMware, Ubuntu supports:

1. **DataSourceVMware** (recommended)\ Uses VMware Guestinfo variables.
    
2. **DataSourceNoCloud**\ Requires attaching an ISO with user-data and meta-data.
    

Most enterprises using vSphere use **DataSourceVMware** because:

- No ISO needed
- Works with vCenter Customization Specs
- Integrates with automation pipelines (Terraform, Ansible, PowerCLI)

---

# 3. Preparing Ubuntu 24.04 for Cloud‑Init

## 3.1 Download the Ubuntu 24.04 Cloud Image

Download from Canonical:

[https://cloud-images.ubuntu.com/releases/24.04/release/](https://cloud-images.ubuntu.com/releases/24.04/release/)

Use:

```
ubuntu-24.04-server-cloudimg-amd64.ova
```

This OVA already includes:

- cloud-init
- VMware Guestinfo datasource enabled
- Optimized kernel and VM tools

## 3.2 Deploy the OVA into vSphere

1. In vCenter, select **Deploy OVF Template**
2. Choose the Ubuntu cloud OVA
3. Accept defaults (they are tuned for cloud-init)
4. Deploy the VM but **do not boot it yet**

---

# 4. How VMware Passes Cloud-Init Configuration

cloud-init reads special VMware Guestinfo properties.\ These values are registered in **VM → Edit Settings → VM Options → Advanced → Configuration Parameters**.

### Required keys:

```
guestinfo.userdata
guestinfo.userdata.encoding
guestinfo.metadata
guestinfo.metadata.encoding
```

### Example encoding setting:

```
guestinfo.userdata.encoding = base64
```

---

# 5. Creating a VMware Customization Specification (Supported Approach)

VMware now allows cloud-init user-data to be inserted through VM Customization Specifications **only when using cloud-init enabled images**.

## Steps:

### 5.1 Create a new Customization Specification

1. vCenter → **Policies and Profiles**
2. **Customization Specification Manager**
3. **New → Linux**
4. Name it something like:\ Ubuntu24-cloudinit

### 5.2 Select "Provide custom cloud-init configuration"

Depending on vSphere version, the UI may show:

- “Use cloud-init”
- “Provide user-data”
- “Custom cloud-config”

Paste your cloud-config YAML.

Example:

```#cloud-config
hostname: vm-cloud01
manage_etc_hosts: true


users:
  - name: nate
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    ssh_authorized_keys:
      - ssh-rsa AAAA…

package_update: true_

_package_upgrade: true

packages:

  - nginx

  - curl

  - git

  

runcmd:

  - systemctl enable nginx

  - systemctl start nginx

### 5.3 Save the spec and attach during clone

1. Right-click Ubuntu cloud template
2. **Clone to VM**
3. Select the Customization Spec
4. Finish clone
5. Power on

The VM will boot and cloud-init runs your configuration.

---

# 6. Alternative Method: Setting Guestinfo Parameters Manually

If you don’t want to use a Customization Spec, you can embed the config directly.

### Step 1 — Base64 encode your YAML

Example Linux or macOS command:

```
cat user-data.yaml | base64 -w0
```

Step 2 — Add to VM Advanced Parameters:

```
guestinfo.userdata = <base64 string>
guestinfo.userdata.encoding = base64
```

(Optional metadata):

```
guestinfo.metadata = <base64 string>
guestinfo.metadata.encoding = base64
```

Power on → cloud-init loads config.

---

# 7. Cloud-Init File Structure

You normally provide 1–2 files:

## 7.1 user-data (main configuration)

This contains all your cloud-config YAML.

## 7.2 meta-data (optional)

Defines instance ID, hostname, network config.

Example:

instance-id: ubuntu-01

local-hostname: ubuntu-01

---

# 8. Networking with Cloud-Init on VMware

Ubuntu cloud images default to DHCP.\ To set static networking in cloud-init:

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

Place this inside user-data or meta-data.

---

# 9. Storage Configuration

Cloud-init can set up partitions, filesystems, and mounts.

Example adds a second disk `/dev/sdb`:

fs_setup:

  - label: data

    filesystem: ext4

    device: /dev/sdb

  

mounts:

  - [ /dev/sdb, /mnt/data ]

---

# 10. Installing Applications

Cloud-init can install apt packages:

package_update: true

packages:

  - docker.io

  - htop

  - unzip

Or you can run commands:

runcmd:

  - systemctl enable docker

  - systemctl start docker

---

# 11. Saving This as a Template

Once you have:

- Cloud-init ready VM
- VMware Tools installed
- No user-data baked in

You can:

1. Shut down VM
2. Convert to Template

Now every clone automatically supports cloud-init userdata from:

- Customization Specification
- Guestinfo parameters
- vSphere Automation Tools

---

# 12. Testing & Troubleshooting

Check cloud-init logs:

```
sudo cloud-init status
sudo cloud-init status --long
sudo journalctl -u cloud-init
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

Check recognized datasource:

```
sudo cloud-id
```

VMware should output:

```
vmware
```

---

# 13. Reset cloud-init on an image (before templating)

```
sudo cloud-init clean --logs --reboot
```

This ensures the next clone runs fresh.

---

# 14. Summary

To use cloud-init on Ubuntu 24.04 with VMware:

1. Deploy official Ubuntu cloud image
2. Use VMware Customization Specification **or** Guestinfo parameters
3. Insert cloud-config YAML
4. Power on → cloud-init automatically configures the VM

This provides AWS-style automation on vSphere.

---

If you want, I can also create:

- A reusable enterprise **cloud-init template** tailored for your org
- A VMware golden-image pipeline using Packer
- Example scripts for PowerCLI / Terraform to automate deployments

Just tell me what direction you want to go next.