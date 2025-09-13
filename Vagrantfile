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

        # 1. Configure Yum/DNF to use the attached RHEL DVD
        echo "Setting up DVD as a repository..."
        mkdir -p /mnt/dvd
        mount /dev/sr0 /mnt/dvd
        echo "/dev/sr0 /mnt/dvd iso9660 defaults,nofail 0 0" >> /etc/fstab

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
        echo "Disabling all other repos..."
        dnf config-manager --disable '*' > /dev/null
        dnf config-manager --enable dvd-baseos,dvd-appstream > /dev/null
        dnf clean all > /dev/null

        # 2. Install software packages based on system type
        echo "Installing packages..."
        if [ "#{vm_config[:system_type]}" = "graphical" ]; then
          dnf groupinstall -y "Server with GUI"
          # Remove nomodeset from kernel command line if it exists
          grubby --update-kernel=ALL --remove-args=nomodeset
          systemctl set-default graphical.target
        else
          dnf groupinstall -y "Minimal Install"
        fi
        dnf install -y vim bash-completion man-pages man-db

        # 3. Create 'student' user and set passwords
        echo "Configuring users and passwords..."
        useradd --groups wheel -c "Student" student
        echo "student:student" | chpasswd
        echo "root:redhat" | chpasswd

        # 4. Configure passwordless sudo for student
        echo "Configuring passwordless sudo..."
        echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student

        # 5. Configure SSH access for student and root users
        echo "Configuring SSH keys..."
        # For root
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        echo "#{RHEL_LAB_PUBLIC_KEY}" > /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys

        # For student
        mkdir -p /home/student/.ssh
        chmod 700 /home/student/.ssh
        echo "#{RHEL_LAB_PUBLIC_KEY}" > /home/student/.ssh/authorized_keys
        chmod 600 /home/student/.ssh/authorized_keys
        chown -R student:student /home/student/.ssh

        # Allow root login with password/key
        sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart sshd

        echo "--- Creating udev rules for persistent disk names ---"
        cat > /etc/udev/rules.d/99-persistent-disk.rules << 'EOF'
KERNEL=="sda", SYMLINK+="vda"
KERNEL=="sdb", SYMLINK+="vdb"
KERNEL=="sdc", SYMLINK+="vdc"
KERNEL=="sdd", SYMLINK+="vdd"
EOF
        udevadm trigger
        echo "--- udev rules created ---"

        echo "--- Provisioning Complete ---"
        reboot
      SHELL
    end
  end
end
