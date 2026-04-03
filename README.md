# linux-scripts: Personal Environment Configurations

A comprehensive collection of scripts designed to automate and streamline my Linux environment setup. These tools help bridge the gap between a fresh installation and the specific personalizations I use to optimize my workflow.

---

## 🎯 Project Scope

### What this is
* A curated set of scripts to automate repetitive configuration tasks.
* A central hub for personal preferences and environment tweaks.

### What this is NOT
* **Not a "from-scratch" installer:** These scripts are not intended to replace the GUI/CLI interaction for the majority of the initial OS setup.
* **Complementary, not exhaustive:** This collection aims to work alongside standard system tools rather than providing a headless, total-automation solution.

---
## 🚀 Project Descriptions
### Home Assistant
This project contains a K8S pod comprised of the home assistant container and a matter server to integrate with matter devices like WiZ lightbulbs.
The following folder structure is expected:
```
/etc/containers/
├── k8s
│   └── home-assistant.yaml
└── systemd
    └── hass.kube
```
#### home-assistant.yaml
This file has two sections that might need to be updated:
 - **initContainers:** the SONOFF_VERSION variable has the version of a specific release from the repo [SonoffLAN](https://github.com/alexxit/sonofflan)
 - **volume(hass-pod-data):** this section must have the path for the folder that will hold the config files for Home Assistant. The init container takes care of creating the sub folders
 ⚠️ WARNING: This pod is meant to be ran using **rootful podman**. 
  - This is because Home Assistant needs **raw access to D-Bus** because of Bluetooth paring. 
  - This pod need to run in host mode networking so that device discoverability works. This has the implication that the pod needs to run on Linux because Podman runs in a virtual machine in other operating systems (Windows and macOS)
### Torrent Container
This project contains a K8S pod comprised by the [LinuxServer](https://www.linuxserver.io/) qBittorrent image and Gluetun.
Gluetun routes all the network inside a pod through a VPN. In this repository a configuration to [AirVPN](https://airvpn.org/) is already provided.
#### install.sh
This file replaces the environment variable templates in the *qbit-vpn.yaml.template* file and copies the resulting files to the destination directories. This directories are defined by the variables **DEST_SYSTEMD_DIR** and **DEST_K8S_DIR.** The first variable is the destination of the Kube [Quadlet](https://docs.podman.io/en/latest/markdown/podman-quadlet.1.html), the second is the destination of the K8S Yaml file.

 ⚠️ WARNING: This pod is meant to be ran using rootless podman.
  - The UID and GID defined inside the environment variables file must usually be 0 so that the created download files and qBittorrent config files are owned by the host OS system.