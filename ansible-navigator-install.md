# Install Ansible Navigator

## Download From the RHA Lab

Download `ansible-navigator` and its depdendencies from the RHA lab

```sh
cd ~/Downloads
sudo dnf download ansible-navigator --resolve --alldeps
```

## Install Packages

Install the packages in this order:

1. python3-onigurumacffi
2. python3-requirements-parser
3. python3-parsley
4. python3-pbr
5. python3-bindep
6. ansible-builder
7. python3-docutils
8. python3-lockfile
9. python3-daemon
10. python3-ansible-runner
11. ansible-runner
12. ansible-navigator

## Download Execution Environment from the RHA Lab

```sh
podman images
# locate execution environment image
podman save --output ee-supported-rhel8.tar ee-supported-rhel8:latest
```

## Import image

```sh
podman load -i ee-supported-rhel8.tar
```

## Ansible Navigator Config

Put the following YAML file at `~/.ansible-navigator.yml`

```yml
---
ansible-navigator:
  execution-environment:
    image: utility.lab.example.com/ee-supported-rhel8:latest
    pull:
      policy: missing
  mode: stdout
  playbook-artifact:
    enable: false
  logging:
    level: info
    append: true
    file: /tmp/log.txt
```
