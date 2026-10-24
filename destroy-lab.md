# Destroy the Lab Environment

These steps delete the VMs, their snapshots, and the lab network, and undo the
host changes made by `create_vms.yml`. Run them before rebuilding the lab with
`create_vms.yml`, which is not idempotent.

**Everything below is permanent.** Every VM and every snapshot is deleted.

## Remove the VM Definitions

```sh
for vm in workstation servera serverb serverc; do
    sudo virsh destroy "$vm" 2>/dev/null
    sudo virsh undefine "$vm" --snapshots-metadata
done
sudo virsh list --all
```

No lab VMs should be listed.

## Delete the Disk, Overlay, and Memory Files

The snapshots are external, so each one is a set of overlay files plus a memory
file. `virsh undefine --remove-all-storage` would only delete the newest
overlay, and `create_vms.yml` would then collide with the base images left
behind. Delete every file explicitly instead.

Some overlays and all the memory files live in the `isos` pool beside the DVD
image. The patterns below keep `rhel-10.0-x86_64-dvd.iso` itself.

List the files first:

```sh
cd /var/lib/libvirt/images
ls -d {workstation,servera,serverb,serverc}{,-1,-2,-3}.* \
      isos/*-mem.* isos/rhel-10.0-x86_64-dvd.[0-9]* 2>/dev/null
```

Check that `rhel-10.0-x86_64-dvd.iso` is not in the list, then delete them:

```sh
sudo rm -f {workstation,servera,serverb,serverc}{,-1,-2,-3}.* \
           isos/*-mem.* isos/rhel-10.0-x86_64-dvd.[0-9]*
cd -
sudo virsh pool-refresh default
sudo virsh pool-refresh isos
sudo virsh vol-list default
ls /var/lib/libvirt/images/isos
```

The `default` pool should list only `isos`, and the `isos` directory should
hold only the `.iso`.

## Remove the Lab Network

`create_vms.yml` defines and creates the network from scratch.

```sh
sudo virsh net-destroy lab-example-com
sudo virsh net-undefine lab-example-com
```

## Undo the Host Configuration

From the project directory:

```sh
ansible-playbook --ask-become-pass remove_host_configs.yml
```

This removes the staged kickstarts, the `/etc/hosts` entries, the lab SSH keys,
and the `~/.ssh/config` blocks. It does not remove libvirt.

Also clear the old host keys, since the rebuilt VMs generate new ones:

```sh
for h in workstation servera serverb serverc; do
    ssh-keygen -R "$h"
    ssh-keygen -R "$h.lab.example.com"
done
```

The lab is now ready to rebuild with `create_vms.yml`.
