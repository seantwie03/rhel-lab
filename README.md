# Red Hat Enterprise Linux (RHEL) Lab Environment

This repo contains a Vagrantfile to install and setup several Virtual Machines that can be used to study for Red Hat exams.

## Lab Environment

This lab environment is loosely based off of the [Red Hat Academy](https://www.redhat.com/en/services/training/red-hat-academy) lab environment for the [RHCSA](https://www.redhat.com/en/services/certification/rhcsa) and [RHCE](https://www.redhat.com/en/services/certification/rhce) courses.

**Hypervisor**: VirtualBox or Libvirt

**VM Manager**: [Vagrant](https://developer.hashicorp.com/vagrant)

**VM Configuration**: [Vagrant Shell Provisioner](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)

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

- [Install Vagrant](https://developer.hashicorp.com/vagrant/downloads).
- [Install a Vagrant Provider](https://developer.hashicorp.com/vagrant/docs/providers). This repository has been tested with the [Libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [VirtualBox](https://www.virtualbox.org/) providers.
- [Download the RHEL 9.3 DVD ISO image](https://developers.redhat.com/products/rhel/download#exploreotherredhatproducts). Place the ISO in a location that it will live at permanently.
- Download this repository onto your local machine and change into the project directory.
    - Update the `RHEL_ISO_PATH` variable in the `Vagrantfile` with the full path to the ISO.

### Red Hat Academy Labs

By default, the Virtual Machines created by this repository do not have the Red Hat Academy (RHA) labs. 

The RHA Labs have NOT been tested on these Virtual Machines. Some may work, some may not.

If you want to test your luck you can extract the RHA Lab files and place them in this directory **before** running `vagrant up`.

#### Extracting RHA Labs

On the Workstation VM in the RHA Lab environment run the following command: `tar -cvf rha-labs.tar.gz .venv .grading`. Then download the rha-labs.tar.gz to your local machine and place it in the same folder as the Vagrantfile.

If you do this correctly, the shell provisioner inside the Vagrantfile will extract the files to the student's account in the Workstation VM. You can then use the `lab` command the same as you use it in the RHA Lab environment. Be warned, the labs have **NOT** been tested on these VMs.

## Creating the Environment

From the project directory run: `vagrant up`.

This command performs the following actions:

- Creates 172.25.250.0/24 network (lab-example-com).
- Creates virtual machines described above.
- Configures virtual machines using shell provisioners.

After the command completes the VMs will be running and ready for use.

## Connecting to the VMs

The Vagrantfile is configured for [vagrant ssh](https://developer.hashicorp.com/vagrant/docs/cli/ssh) to login as the student user.

```sh
vagrant ssh servera # Connects to student user
# You can substitute servera for any of the other hostnames
```

If you want to SSH directly without using Vagrant, you can add configure your `/etc/hosts` or `~/.ssh/config` for SSH access.

## Insecure Environment

**This lab environment is completely insecure. The code in this repository does NOT follow any security best practices.**

This lab environment intended to be used by students to learn the basics of Linux and RHEL. You can also learn the basics of Linux security by correcting the issues below:

### Insecure Passwords

The passwords are set in the Vagrantfile. They have no special characters. They never expire.

### Insecure SSH Access

A shared SSH key is used on all machines. The root account is accessible over ssh. SSH Host Key Checking has been relaxed.

### Insecure Software Packages

The servers are not subscribed to the Red Hat repositories to receive security updates.

