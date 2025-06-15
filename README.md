# Red Hat Enterprise Linux (RHEL) Lab Environment

This repo contains playbooks to install and setup several Virtual Machines that can be used to study for Red Hat exams. These playbooks have been tested on Fedora but will likely work on any Enterprise Linux distribution.

## Lab Environment

This lab environment is loosely based off of the [Red Hat Academy](https://www.redhat.com/en/services/training/red-hat-academy) lab environment for the [RHCSA](https://www.redhat.com/en/services/certification/rhcsa) and [RHCE](https://www.redhat.com/en/services/certification/rhce) courses.

**Network**: 172.25.250.0/24

| Name        | IP              | System Type | CPU | Memory (MB) | Disks (this provisioned)                |
|-------------|-----------------|-------------|-----|-------------|-----------------------------------------|
| workstation | 172.25.250.9    | Graphical   | 2   | 6000        | 1 × 20GB (OS)                           |
| servera     | 172.25.250.10   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |
| serverb     | 172.25.250.11   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |
| serverc     | 172.25.250.12   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |

## Setup

To use this repository perform the following steps on a Fedora or Enterprise Linux distribution:

- [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible). 
- Download this repository onto your local machine and change into the project directory.
- Review and update the variables in [vars/rhel_lab_vars.yml](vars/rhel_lab_vars.yml) as desired.
- Run `ansible-galaxy install -r collections/requirements.yml` to install the [community.libvirt collection](https://galaxy.ansible.com/ui/repo/published/community/libvirt/)


## Creating the Environment

From the project directory run: `ansible-playbook --ask-become-pass create_vms.yml`. You will be prompted for your sudo password.

This playbook performs the following actions:

- Installs libvirt.
- Stages kickstart files.
- Creates 172.25.250.0/24 network (lab-example-com).
- Creates virtual machines described above.
- Configures virtual machines using kickstart files.
- Configures your host for easy access to the lab environment.

After the playbook completes the VMs will still be installing via Kickstart. Wait for them to automatically shut off.

After the VMs shut down it is recommend to take a snapshot of each one with a command like the following:

```sh
sudo virsh snapshot-create-as workstation "$(date --iso-8601=seconds) - fresh install"
sudo virsh snapshot-create-as servera "$(date --iso-8601=seconds) - fresh install"
sudo virsh snapshot-create-as serverb "$(date --iso-8601=seconds) - fresh install"
sudo virsh snapshot-create-as serverc "$(date --iso-8601=seconds) - fresh install"
```

The lab environment is now created and ready for use. If you wish to modify the lab environment, use the methods described in the [RHEL Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_managing_linux_virtual_machines/index). Do not attempt to update the VMs by re-running the `create_vms.yml` playbook. These playbooks are **NOT idempotent.** Running the `create_vms.yml` playbook a second time is likely to cause problems. If you want to undo the changes from `create_vms.yml` you can run `ansible-playbook --ask-become-pass destroy_vms.yml`. This will undo all changes from `create_vms.yml` except it will not remove libvirt from your host.

## Connecting to the VMs

The `create_vms.yml` playbook adds lines in your `/etc/hosts` file for each server. It also adds entries into your `~/.ssh/config` for easy SSH access using one of the commands below:

```sh
ssh servera # Connect to student user
ssh servera-root # Connect to root user
# You can substitute servera for any of the other hostnames
```

## Insecure Environment

**This lab environment is completely insecure. The code in this repository does NOT follow any security best practices.**

This lab environment intended to be used by students to learn the basics of Linux and RHEL. You can also learn the basics of Linux security by correcting the issues below:

- The passwords are stored in plaintext.
- A shared SSH key is used on all machines.
- SSH Host Key Checking has been relaxed.
- The root account allows ssh access.
- The servers are not subscribed to the Red Hat repositories to receive security updates.

## Contributing

This repo is setup a bit weird. The [community.libvirt collection](https://galaxy.ansible.com/ui/repo/published/community/libvirt/) is not idempotent. This means the create and destroy playbooks are not idempotent. It felt weird to create a non-idempotent role, so I left the tasks in the playbook files.