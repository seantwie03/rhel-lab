# Red Hat Enterprise Linux (RHEL) Lab Environment

This repo contains playbooks to install and setup several Virtual Machines that can be used to study for Red Hat exams. These playbooks have been tested on Fedora but will likely work on any Enterprise Linux distribution.

## Lab Environment

This lab environment is loosely based off of the [Red Hat Academy](https://www.redhat.com/en/services/training/red-hat-academy) lab environment for the [RHCSA](https://www.redhat.com/en/services/certification/rhcsa) and [RHCE](https://www.redhat.com/en/services/certification/rhce) courses.

**Hypervisor**: Libvirt

**VM Configuration**: [kickstart](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/automated-installation-workflow)

**Network**: 172.25.250.0/24

| Name        | IP              | System Type | CPU | Memory (MB) | Disks (this provisioned)                |
|-------------|-----------------|-------------|-----|-------------|-----------------------------------------|
| workstation | 172.25.250.9    | Graphical   | 2   | 6000        | 1 × 20GB (OS)                           |
| servera     | 172.25.250.10   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |
| serverb     | 172.25.250.11   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |
| serverc     | 172.25.250.12   | Headless    | 1   | 2048        | 1 × 10GB (OS), 3 × 5GB (blank)          |

The VMs that are created are not subscribed to the Red Hat repositories, instead the DVD ISO is mounted into the VM and configured as a repository. This enables package installation without a subscription. If you wish to subscribe the VMs consider creating an account and joining the [developer program](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux).

## Setup

To use this repository perform the following steps on a Fedora or Enterprise Linux distribution:

- [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible).
- [Download the RHEL 9.3 DVD ISO image](https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.3/x86_64/product-software). Make sure you download the Binary DVD that is 9.8GB. (Requires Developer Subscription). Place the ISO in a location that it will live at permanently.
- Download this repository onto your local machine and change into the project directory.
- Review and update the variables in [vars/rhel_lab_vars.yml](vars/rhel_lab_vars.yml) as desired. Especially update the **user_name**, **os_variant**, and **iso_path** variables.
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

### Insecure Passwords

The passwords are stored in plaintext in the kickstart file. They have no special characters. They never expire.

### Insecure SSH Access

A shared SSH key is used on all machines. The root account is accessible over ssh. SSH Host Key Checking has been relaxed.

### Insecure Software Packages

The servers are not subscribed to the Red Hat repositories to receive security updates.

## Contributing

This repo is setup a bit weird. The [community.libvirt collection](https://galaxy.ansible.com/ui/repo/published/community/libvirt/) is not idempotent. This means the create and destroy playbooks are not idempotent. It felt weird to create a non-idempotent role, so I left the tasks in the playbook files.

## Alternates

Another way I could've accomplished this is with Vagrant's [Ansible Provisioners](https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_intro). This is likely the direction I would go if I needed to support other operating systems besides Fedora and Enterprise Linux. 

This approach with Vagrant would make the VMs more ephemeral. Instead of using snapshots you could just delete and recreate the VM. This opens the door to spin up VMs with specific configurations for exercises. For example, one of the Vagrantfiles could have a VM preconfigured with NFS and on the other VM you must login and mount the NFS share.

## TODO

- Add extra nics on host-only network to practice IP config
- Add ~/.terminfo/kitty.terminfo, ~/.terminfo/78/xterm-kitty and ~/.terminfo/x/xterm-kitty to root, student, and /etc/skel/
    - Also ghostty?
- Add mlocate?
    - dnf install mlocate
    - systemctl start mlocate-updatedb # force the first run
        - or
        - /usr/libexec/mlocate-run-updatedb
        - updatedb
