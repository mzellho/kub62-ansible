# 🚀 Bootstrapping a [K8s](https://kubernetes.io/) Cluster on [Raspberry Pi](https://www.raspberrypi.com/) with [`ansible`](https://ansible.com/)

🧠 This project automates the provisioning of a lightweight [`k3s`](https://k3s.io/) cluster
on [Raspberry Pi](https://www.raspberrypi.com/) devices using [`ansible`](https://ansible.com/). It sets up a
control‑plane node, one or more worker nodes, and optionally a kiosk node for displaying dashboards. The playbook
handles everything from system configuration to cluster bootstrapping:

- 🛠️ Base system configuration (locales, timezone, hostname, disabled peripherals)
- 📦 Package updates and cleanup
- 💾 Optional NVMe/USB boot via [`rpi-clone`](https://github.com/geerlingguy/rpi-clone) with EEPROM updates
- ⚙️ Kernel cgroup flags for container support
- 🐧 Installation of [`k3s`](https://k3s.io/) on the control-plane node (configurable via `k3s_exec_flags`)
- 🔑 Secure token retrieval and distribution for worker nodes
- 🤝 Automatic joining of workers to the cluster
- 🖥️ Optional kiosk node with X11 + Chromium in fullscreen mode
- 👆 Touchscreen gesture control via [`bodgestr`](https://github.com/mzellho/bodgestr) — swipe between tabs,
  refresh, tap, pinch to zoom, and more

## 📋 Prerequisites

Before running the playbook, make sure you have:

- 💻 A control machine with [`ansible`](https://ansible.com/) installed
- 🔐 Your SSH private key available locally (e.g. `~/.ssh/id_ed25519`)
- 🔑 SSH access to all nodes (public key added to `~/.ssh/authorized_keys`)
- 🗂️ A valid inventory file (`inventory/hosts.ini`) with IP addresses and group names
- 🍓 [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/) already installed and reachable via
  network
- 🐍 Python 3 installed on each [Raspberry Pi](https://www.raspberrypi.com) (usually pre-installed
  with [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/))
- 🌐 Internet access on the Pis to fetch [`k3s`](https://k3s.io/) and updates

## ⚙️ Usage

Copy the example inventory file `inventory/hosts.example.ini` to `inventory/hosts.ini` and customize it according to
your setup.

### Inventory Variables

| Variable                       | Scope   | Description                                                                      |
|--------------------------------|---------|----------------------------------------------------------------------------------|
| `ansible_ssh_private_key_file` | `all`   | Path to your SSH private key                                                     |
| `ansible_uid`                  | `all`   | UID of the SSH user (e.g. `1000`)                                                |
| `ansible_user`                 | `all`   | SSH user on the Pis (e.g. `pi`)                                                  |
| `clone_destination`            | `host`  | Set to `nvme` or `usb` to clone the system to the target device                  |
| `clone_label_prefix`           | `all`   | Partition label prefix for cloned media (e.g. `kub62`)                           |
| `k3s_exec_flags`               | `all`   | Flags passed to the k3s installer (e.g. `--disable traefik --disable servicelb`) |
| `kiosk_urls`                   | `kiosk` | Space-separated URLs for Chromium to open in kiosk mode                          |
| `locale`                       | `all`   | System locale (e.g. `de_AT.UTF-8`)                                               |
| `timezone`                     | `all`   | System timezone (e.g. `Europe/Vienna`)                                           |
| `bodgestr_device_usb_id`       | `kiosk` | USB vendor:product ID of the touchscreen (e.g. `27c0:0859`)                      |

### Provisioning

> ⚠️ The control-plane must be provisioned **first** — worker nodes depend on the node token it generates.

```bash
# 🖥️ Control Plane Setup
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.yaml -l control_plane playbooks/kub62.yaml --vault-password-file=.vaultpass -v

# 🧑‍💻 Worker Node Setup
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.yaml -l worker playbooks/kub62.yaml --vault-password-file=.vaultpass -v

# 🖥️ Kiosk Node Setup
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.yaml -l kiosk playbooks/kub62.yaml --vault-password-file=.vaultpass -v

```

## 🛠️ Base Role

Applied to **all** nodes (control-plane, workers, and kiosk). It configures:

- 🏷️ Hostname
- 🌍 Timezone and locale
- 📦 Package updates and cleanup
- 🔇 Disables Bluetooth, onboard audio, ACT LED, and ModemManager
- 💾 Optionally clones the system to NVMe or USB via [`rpi-clone`](https://github.com/geerlingguy/rpi-clone) (when
  `clone_destination` is set), with automatic shutdown and reconnect handling
- 🔧 Configures EEPROM boot order and runs EEPROM updates

## 💾 K3s Base Role

Applied to control-plane and worker nodes. It prepares the Pi for running [`k3s`](https://k3s.io/):

- ⚙️ Adds `cgroup_memory=1 cgroup_enable=memory` kernel flags
- 📦 Installs Longhorn dependencies

## 🖥️ Kiosk Role

Applied to kiosk nodes. It provisions a fullscreen Chromium dashboard:

- 🚫 Disables the default `getty` login on `tty1`
- 🪟 Installs a lightweight X11 environment with Openbox
- 🌐 Launches Chromium in kiosk mode with the URLs defined in `kiosk_urls`
- 🖱️ Hides the mouse cursor and disables screen blanking
- 👆 Installs [`bodgestr`](https://github.com/mzellho/bodgestr) for full touchscreen gesture control
- 🔁 Runs as a systemd service (`kiosk.service`) for automatic startup and recovery

### 👆 Touchscreen Gestures via [`bodgestr`](https://github.com/mzellho/bodgestr)

[`bodgestr`](https://github.com/mzellho/bodgestr) is a lightweight, config-driven gesture daemon for Linux
touchscreens. It translates raw touch events into arbitrary commands — no desktop environment required, perfect for
headless kiosk setups on Raspberry Pi and similar devices.

```
  Touchscreen               bodgestr                Chromium (kiosk)
  /dev/input/eventX    ──►  gesture recognition  ──►  xdotool keystrokes
                             swipe, tap, pinch         tab switch, click, zoom, …
```

Gestures are fully configurable per device — supports multi-screen setups, per-device overrides, custom thresholds,
and arbitrary shell commands as actions. For the full documentation, see the
[`bodgestr` repository](https://github.com/mzellho/bodgestr).

## 🔭 What's Next?

After successfully setting up your [Kubernetes](https://kubernetes.io/) cluster, it's time to start tinkering! You
could:

- 🧪 Deploy sample apps and test workloads
- 📦 Explore [Helm](https://helm.sh/) charts or GitOps workflows
- 🚀 [FluxCD](https://fluxcd.io/) or [ArgoCD](https://argoproj.github.io/cd/) for continuous deployment
- 🏡 Start a Home Lab project like [kub62-gitops](https://github.com/mzellho/kub62-gitops)

Your cluster is lightweight, modular, and ready for experimentation — so go ahead and make it yours!
