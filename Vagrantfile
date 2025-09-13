# -*- mode: ruby -*-
# vi: set ft=ruby :

#
# IMPORTANT:
#
# 1. Install Vagrant and VirtualBox.
# 2. Update the RHEL_ISO_PATH variable below to the absolute path of your
#    RHEL 9.3+ DVD ISO file.
#
RHEL_ISO_PATH = "/var/lib/libvirt/isos/rhel-9.3-x86_64-dvd.iso"

# This public key will be configured for SSH access for the root and student users.
RHEL_LAB_PUBLIC_KEY = File.read(File.join(File.dirname(__FILE__), "files/rhel_lab_key.pub")).strip

# Define all VMs in a single data structure for easy management.
VMS = [
  {
    hostname: "workstation",
    ip: "192.168.56.9",
    system_type: "graphical",
    cpus: 2,
    memory: 6000,
    os_disk_size: "20GB",
    data_disks: []
  },
  {
    hostname: "servera",
    ip: "192.168.56.10",
    system_type: "headless",
    cpus: 1,
    memory: 2048,
    os_disk_size: "10GB",
    data_disks: [5, 5, 5] # Sizes in GB
  },
  {
    hostname: "serverb",
    ip: "192.168.56.11",
    system_type: "headless",
    cpus: 1,
    memory: 2048,
    os_disk_size: "10GB",
    data_disks: [5, 5, 5]
  },
  {
    hostname: "serverc",
    ip: "192.168.56.12",
    system_type: "headless",
    cpus: 1,
    memory: 2048,
    os_disk_size: "10GB",
    data_disks: [5, 5, 5]
  }
]

Vagrant.configure("2") do |config|
  # Check if the ISO path has been updated.
  if RHEL_ISO_PATH == "/path/to/your/rhel-9.3-x86_64-dvd.iso"
    raise "Please update the RHEL_ISO_PATH variable in your Vagrantfile before running 'vagrant up'."
  end

  # Common configuration for all VMs
  config.vm.box = "generic/rhel9"
  config.ssh.insert_key = false # We will manage keys manually for student/root

  # Define and configure each VM based on the VMS data structure
  VMS.each do |vm_config|
    config.vm.define vm_config[:hostname] do |node|
      node.vm.hostname = "#{vm_config[:hostname]}.lab.example.com"
      node.vm.network "private_network", ip: vm_config[:ip]

      # Configure VirtualBox provider settings
      node.vm.provider "virtualbox" do |vb|
        vb.name = vm_config[:hostname]
        vb.cpus = vm_config[:cpus]
        vb.memory = vm_config[:memory]

        if vm_config[:system_type] == "graphical"
          vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
          #vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
          vb.gui = true
        end

        # Attach the RHEL ISO as a DVD
        vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", RHEL_ISO_PATH]

        # Create and attach additional data disks for servers
        vm_config[:data_disks].each_with_index do |disk_size, i|
          disk_path = "build/#{vm_config[:hostname]}-disk-#{i+1}.vdi"
          unless File.exist?(disk_path)
            vb.customize ["createhd", "--filename", disk_path, "--size", disk_size * 1024]
          end
          vb.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", i+1, "--device", "0", "--type", "hdd", "--medium", disk_path]
        end
      end

      # This shell provisioner replicates the logic from the Kickstart %post script
      node.vm.provision "shell", inline: <<-SHELL
        echo "--- Starting Provisioning for #{vm_config[:hostname]} ---"

        # Configure Yum/DNF to use the attached RHEL DVD
        #
        # Mount the DVD
        mkdir -p /mnt/dvd
        mount /dev/sr0 /mnt/dvd
        echo "/dev/sr0 /mnt/dvd iso9660 defaults,nofail 0 0" >> /etc/fstab

        # Configure the yum repositories
        cat > /etc/yum.repos.d/rhel-dvd.repo << 'EOF'
[dvd-baseos]
name=RHEL DVD - BaseOS
baseurl=file:///mnt/dvd/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[dvd-appstream]
name=RHEL DVD - AppStream
baseurl=file:///mnt/dvd/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF
        # Disable other repos
        dnf config-manager --disable '*' > /dev/null
        dnf config-manager --enable dvd-baseos,dvd-appstream > /dev/null
        dnf clean all > /dev/null

        # Install software packages based on system type
        if [ "#{vm_config[:system_type]}" = "graphical" ]; then
          # Install GUI packages
          dnf groupinstall -y "Server with GUI" --exclude gnome-tour
          # Boot to GUI automatically
          systemctl set-default graphical.target
          # Remove nomodeset from kernel command line if it exists
          grubby --update-kernel=ALL --remove-args=nomodeset
          # Disable 'System Not Registered' Nag message
          systemctl --global mask org.gnome.SettingsDaemon.Subscription.service
        else
          # If this is a headless install, just install the minimal package set
          dnf groupinstall -y "Minimal Install"
        fi
        # Install some nice-to-have extras
        dnf install -y vim bash-completion man-pages man-db

        # Set root's password to redhat
        echo "root:redhat" | chpasswd

        # Configure SSH access for root
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        echo "#{RHEL_LAB_PUBLIC_KEY}" > /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys

        # Allow root to login with password/key
        sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart sshd


        # Create 'student' user and set passwords
        useradd --groups wheel -c "Student" student
        echo "student:student" | chpasswd

        # Configure SSH access for student
        mkdir -p /home/student/.ssh
        chmod 700 /home/student/.ssh
        echo "#{RHEL_LAB_PUBLIC_KEY}" > /home/student/.ssh/authorized_keys
        chmod 600 /home/student/.ssh/authorized_keys
        chown -R student:student /home/student/.ssh

        # Configure passwordless sudo for student
        echo "Configuring passwordless sudo..."
        echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student

        # Red Hat Academy Lab scripts expect /dev/vd[a-z]. VirtualBox has /dev/sd[a-z].
        # This block uses udev to create symlinks so that the drives can be accessed
        # using either sd[a-z] OR vd[a-z].
        cat > /etc/udev/rules.d/99-persistent-disk.rules << 'EOF'
KERNEL=="sda", SYMLINK+="vda"
KERNEL=="sdb", SYMLINK+="vdb"
KERNEL=="sdc", SYMLINK+="vdc"
KERNEL=="sdd", SYMLINK+="vdd"
EOF
        udevadm trigger

        # Add RHA lab command location to path
        cat > /etc/profile.d/labs.sh << 'EOF'
#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/home/student/.venv/labs/bin
EOF
      SHELL

      # Upload and extract rha-labs.tar.gz for the student user on the workstation VM
      if vm_config[:hostname] == "workstation" && File.exist?("lab_files/rha-labs.tar.gz")
        node.vm.provision "file", source: "lab_files/rha-labs.tar.gz", destination: "/tmp/rha-labs.tar.gz"
        node.vm.provision "shell", inline: "sudo -u student tar -xvf /tmp/rha-labs.tar.gz -C /home/student"
      end
      # Reboot after provisioning
      node.vm.provision "shell", inline: "reboot"
    end
  end
end
