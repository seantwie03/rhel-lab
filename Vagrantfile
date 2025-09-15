#
# IMPORTANT:
#
# 1. Install Vagrant and VirtualBox.
# 2. Download the RHEL 9.3 ISO using your Developer Subscription
# 3. Update the RHEL_ISO_PATH variable below to the absolute path of your
#    RHEL 9.3+ DVD ISO file.
# 4. Download the Red Hat Academy lab files and place them in ./files
# 5. (LINUX ONLY) Run the following commands to allow the Host-Only 
#    network to have IPs outside of the 192.168.56.0/24 range.
#      sudo mkdir -p /etc/vbox
#      sudo vim /etc/vbox/networks.conf
#      # Add the following line
#      * 172.25.250.0/24
#    More details here: https://www.virtualbox.org/manual/ch06.html#network_hostonly
#

RHEL_ISO_PATH = "/var/lib/libvirt/isos/rhel-9.3-x86_64-dvd.iso"

# Define all VMs in a single data structure for easy management.
VMS = [
  {
    hostname: "workstation",
    ip: "172.25.250.9",
    system_type: "graphical",
    cpus: 2,
    memory: 6000,
    os_disk_size: "20GB",
    data_disks: []
  },
  {
    hostname: "servera",
    ip: "172.25.250.10",
    system_type: "headless",
    cpus: 1,
    memory: 2048,
    os_disk_size: "10GB",
    data_disks: [5, 5, 5] # Sizes in GB
  },
  {
    hostname: "serverb",
    ip: "172.25.250.11",
    system_type: "headless",
    cpus: 1,
    memory: 2048,
    os_disk_size: "10GB",
    data_disks: [5, 5, 5]
  },
  # {
  #   hostname: "serverc",
  #   ip: "172.25.250.12",
  #   system_type: "headless",
  #   cpus: 1,
  #   memory: 2048,
  #   os_disk_size: "10GB",
  #   data_disks: [5, 5, 5]
  # }
]

Vagrant.configure("2") do |config|
  # Check if the ISO path has been updated.
  if RHEL_ISO_PATH == "/path/to/your/rhel-9.3-x86_64-dvd.iso"
    raise "Please update the RHEL_ISO_PATH variable in your Vagrantfile before running 'vagrant up'."
  end

  # Common configuration for all VMs
  config.vm.box = "generic/rhel9"
  config.vm.box_version = "4.3.12"
  config.ssh.insert_key = false

  # Define and configure each VM based on the VMS data structure
  VMS.each do |vm_config|
    config.vm.define vm_config[:hostname] do |node|
      node.vm.hostname = "#{vm_config[:hostname]}.lab.example.com"
      node.vm.network "private_network", ip: vm_config[:ip], virtualbox__intnet: true

      # Configure VirtualBox provider settings
      node.vm.provider "virtualbox" do |vb|
        vb.name = vm_config[:hostname]
        vb.cpus = vm_config[:cpus]
        vb.memory = vm_config[:memory]

        if vm_config[:hostname] == "workstation"
          vb.gui = true
          vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
          #vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
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

        # Red Hat Academy Lab scripts expect /dev/vd[a-z]. VirtualBox has /dev/sd[a-z].
        # This section uses udev to create symlinks so that the drives can be accessed
        # using either sd[a-z] OR vd[a-z].
        node.vm.provision "shell", inline: <<-SHELL
          cat > /etc/udev/rules.d/99-persistent-disk.rules <<-'EOF'
						KERNEL=="sda", SYMLINK+="vda"
						KERNEL=="sdb", SYMLINK+="vdb"
						KERNEL=="sdc", SYMLINK+="vdc"
						KERNEL=="sdd", SYMLINK+="vdd"
					EOF
          udevadm trigger
        SHELL
      end

      # Configure Libvirt provider settings
      node.vm.provider "libvirt" do |libvirt|
        libvirt.driver = "kvm"
        libvirt.cpus = vm_config[:cpus]
        libvirt.memory = vm_config[:memory]

        # Attach the RHEL ISO as a CD-ROM
        libvirt.cdrom RHEL_ISO_PATH

        # Create and attach additional data disks for servers
        libvirt.storage :file, size: vm_config[:os_disk_size], device: "vda"
        vm_config[:data_disks].each_with_index do |disk_size, i|
          libvirt.storage :file, size: "#{disk_size}GB", device: "vd#{('b'.ord + i).chr}"
        end
      end

      node.vm.provision "file", source: "files/lab_rsa", destination: "/tmp/lab_rsa"
      node.vm.provision "file", source: "files/lab_rsa.pub", destination: "/tmp/lab_rsa.pub"

      # Configure dnf to use the attached RHEL DVD
      node.vm.provision "shell", inline: <<-SHELL
        echo "Configure dnf to use the attached RHEL DVD"
        # Mount the DVD
        mkdir -p /mnt/dvd
        mount /dev/sr0 /mnt/dvd
        echo "/dev/sr0 /mnt/dvd iso9660 defaults,nofail 0 0" >> /etc/fstab

        # Configure the yum repositories
        cat > /etc/yum.repos.d/rhel-dvd.repo <<-'EOF'
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

        # Install packages required for labs
        dnf install -y sshpass

        # Install some nice-to-have extras
        dnf install -y vim bash-completion man-pages man-db

        echo "Configure the root account"
        # Set root's password to redhat
        echo "root:redhat" | chpasswd

        # Configure SSH access for root
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        cp /tmp/lab_rsa* /root/.ssh/
        cat /tmp/lab_rsa.pub > /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys

        # Allow root to login with password/key
        sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart sshd

        echo "Configure the student account"
        # Create 'student' user and set password
        useradd --groups wheel -c "Student" student
        echo "student:student" | chpasswd

        # Configure SSH access for student
        mkdir -p /home/student/.ssh
        chmod 700 /home/student/.ssh
        cp /tmp/lab_rsa* /home/student/.ssh/
        cat /tmp/lab_rsa.pub > /home/student/.ssh/authorized_keys
        chmod 600 /home/student/.ssh/authorized_keys
        chown -R student:student /home/student/.ssh

        # Configure passwordless sudo for student
        echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student

        # Disable SSH host key checking in the lab environment
        cat > /etc/ssh/ssh_config.d/01-training.conf <<-'EOF'
					Host *
					    StrictHostKeyChecking no
					    ServerAliveInterval 100
				EOF

        # Configure the /etc/hosts file
        cat >> /etc/hosts << EOF
#{VMS.map { |vm| "#{vm[:ip]} #{vm[:hostname]}.lab.example.com #{vm[:hostname]}" }.join("\n")}
EOF
      SHELL

      # Configuration specific to graphical systems
      if vm_config[:system_type] == "graphical"
        node.vm.provision "shell", inline: <<-SHELL
          echo "Configure graphical system"
          # Install GUI packages
          dnf groupinstall -y "Server with GUI" --exclude gnome-tour

          # Boot to GUI automatically
          systemctl set-default graphical.target

          # Remove nomodeset from kernel command line if it exists
          grubby --update-kernel=ALL --remove-args=nomodeset

          # Disable 'System Not Registered' Nag message
          systemctl --global mask org.gnome.SettingsDaemon.Subscription.service

					# Configure the terminal to autostart
					mkdir -p /home/student/.config/autostart
					cp /usr/share/applications/org.gnome.Terminal.desktop /home/student/.config/autostart/
					sed -i 's/^Exec=.*$/^Exec=gnome-terminal --preferences --maximize/'  /home/student/.config/autostart/org.gnome.Terminal.desktop

        SHELL
      end

      # Configuration specific to headless systems
      if vm_config[:system_type] == "headless"
        node.vm.provision "shell", inline: <<-SHELL
          echo "Configure headless system"
          dnf groupinstall -y "Minimal Install"
        SHELL
      end

      # Add Red Hat Academy lab command to workstation system
      if vm_config[:hostname] == "workstation" && File.exist?("files/rha-labs.tar.gz")
        node.vm.provision "file", source: "files/rha-labs.tar.gz", destination: "/tmp/rha-labs.tar.gz"
        node.vm.provision "shell", inline: <<-SHELL
          echo "Add Red Hat Academy lab command to workstation system"
          # Extract lab files to student's home directory
          sudo -u student tar -xvf /tmp/rha-labs.tar.gz -C /home/student

          # Add RHA lab command location to path
          cat > /etc/profile.d/labs.sh <<-'EOF'
						#!/bin/bash
						export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/home/student/.venv/labs/bin
					EOF
        SHELL
      end

      node.vm.provision "custom_reboot", type: "shell", reboot: true, inline: <<-SHELL
				echo "----------"
				echo "| REBOOT |"
				echo "----------"
      SHELL

    end

  end

  # Enable the use of vagrant ssh with the student user
  VAGRANT_COMMAND = ARGV[0]
  if VAGRANT_COMMAND == "ssh"
    config.ssh.username = "student"
    config.ssh.private_key_path = "files/lab_rsa"
  end

end

# Yes, tabs are annoying, but this file uses a LOT of HEREDOCs. 
# If I don't use tabs, then I can't indent the HEREDOCs at all.
# vi: set ft=ruby noexpandtab tabstop=2 shiftwidth=2 :
