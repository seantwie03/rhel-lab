#
# IMPORTANT:
#
# 1. Install Vagrant and VirtualBox.
# 2. Download the RHEL 9.3 ISO using your Developer Subscription 3. Update the RHEL_ISO_PATH variable below to the absolute path of your RHEL 9.3+ DVD ISO file.
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
		config.vm.synced_folder ".", "/vagrant", type: "rsync"

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
		config.vm.define "#{vm_config[:hostname]}.lab.example.com" do |node|
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
			end

			# Configure Libvirt provider settings
			node.vm.provider "libvirt" do |libvirt|
				libvirt.driver = "kvm"
				libvirt.storage_pool_name = "rhel-lab"
				libvirt.cpus = vm_config[:cpus]
				libvirt.memory = vm_config[:memory]

				# Attach the RHEL ISO as a CD-ROM
				libvirt.storage :file, :device => :cdrom, :path => RHEL_ISO_PATH

				# Create and attach additional data disks for servers
				vm_config[:data_disks].each_with_index do |disk_size, i|
					libvirt.storage :file, size: "#{disk_size}GB", device: "vd#{('b'.ord + i).chr}"
				end
			end

			node.vm.provision "file", source: "provisioning/files/lab_rsa", destination: "/tmp/lab_rsa"
			node.vm.provision "file", source: "provisioning/files/lab_rsa.pub", destination: "/tmp/lab_rsa.pub"

			# Provisioner 1: Configure DNF and install Ansible
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

				echo "Install Ansible"
				dnf install -y ansible-core
			SHELL

			# Red Hat Academy Lab scripts expect /dev/vd[a-z]. VirtualBox has /dev/sd[a-z].
			# This section uses udev to create symlinks so that the drives can be accessed
			# using either sd[a-z] OR vd[a-z].
			node.vm.provision "shell", inline: <<-SHELL
				if [ -b /dev/sda ]; then
					echo "Configure /dev/vd[a-z] symlinks"
					cat > /etc/udev/rules.d/99-persistent-disk.rules <<-'EOF'
						KERNEL=="sda", SYMLINK+="vda"
						KERNEL=="sdb", SYMLINK+="vdb"
						KERNEL=="sdc", SYMLINK+="vdc"
						KERNEL=="sdd", SYMLINK+="vdd"
					EOF
					udevadm trigger
				fi
			SHELL

			# Provisioner 2: Run the main Ansible playbook
			hosts_entry = VMS.map { |vm| "#{vm[:ip]} #{vm[:hostname]}.lab.example.com #{vm[:hostname]}" }.join("\n")
			node.vm.provision "ansible_local" do |ansible|
				ansible.playbook = "provisioning/main.yml"
				ansible.extra_vars = {
					:system_type => vm_config[:system_type],
					:hostname => vm_config[:hostname],
					:rha_labs_file_exists => File.exist?("rha-labs.tar.gz"),
					:etc_hosts_entries => hosts_entry
				}
	
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
		config.ssh.private_key_path = "provisioning/files/lab_rsa"
	end
end

# Yes, tabs are annoying, but this file uses a LOT of HEREDOCs. 
# If I don't use tabs, then I can't indent the HEREDOCs at all.
# vi: set ft=ruby noexpandtab tabstop=2 shiftwidth=2 nolist :
