# 🚀 Bootstrapping a [K8s](https://kubernetes.io/) Cluster on [Raspberry Pi](https://www.raspberrypi.com/) with [`ansible`](https://ansible.com/)

🧠 This project automates the provisioning of a lightweight [`k3s`](https://k3s.io/) cluster
on [Raspberry Pi](https://www.raspberrypi.com/) devices using [`ansible`](https://ansible.com/). It sets up one or more
control‑plane nodes, worker nodes, and optionally a kiosk node for displaying dashboards. The playbook handles
everything from system configuration to cluster bootstrapping with GitOps support:

- 🛠️ Base system configuration (locales, timezone, hostname, disabled peripherals)
- 📦 Package updates and cleanup
- 💾 Optional NVMe/USB boot via [`rpi-clone`](https://github.com/geerlingguy/rpi-clone) with EEPROM updates
- ⚙️ Kernel cgroup flags for container support
- 🐧 Installation of [`k3s`](https://k3s.io/) with optional multi-node control-plane support
- 🔑 Shared `k3s` join token via inventory variables
- 🤝 Automatic joining of workers to the cluster
- 🌐 Optional [`Cilium CLI`](https://cilium.io/) installation
- 🔐 Optional standalone [`SOPS`](https://github.com/mozilla/sops) + [`age`](https://github.com/FiloSottile/age) secret
  provisioning
- 🔄 Optional [`Flux`](https://fluxcd.io/) for GitOps-based deployment and cluster management
- 🖥️ Optional kiosk node with X11 + Chromium in fullscreen mode
- 👆 Touchscreen gesture control via [`bodgestr`](https://github.com/mzellho/bodgestr) — swipe between tabs,
  refresh, tap, pinch to zoom, and more

## 📋 Prerequisites

Before running the playbook, make sure you have:

- 💻 A control machine with [`ansible`](https://ansible.com/) installed
- 🧩 Required Ansible collections available (notably `community.general`)
- 🔐 Your SSH private key available locally (e.g. `~/.ssh/id_ed25519`)
- 🔑 SSH access to all nodes (public key added to `~/.ssh/authorized_keys`)
- 🗂️ A valid inventory file (`inventory/hosts.yaml`) with IP addresses and group names
- 🍓 [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/) already installed and reachable via
  network
- 🐍 Python 3 installed on each [Raspberry Pi](https://www.raspberrypi.com) (usually pre-installed
  with [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/))
- 🌐 Internet access on the Pis to fetch [`k3s`](https://k3s.io/) and updates
- 💾 If `clone_destination` is set to `nvme` or `usb`: target storage must be physically attached and prepared
  (valid partition table / partition layout for `rpi-clone`)

## ⚙️ Usage

Copy the example inventory file `inventory/hosts.example.yaml` to `inventory/hosts.yaml` and customize it according to
your setup.

### Inventory Variables

| Variable                       | Scope        | Description                                                                                       |
|--------------------------------|--------------|---------------------------------------------------------------------------------------------------|
| `ansible_python_interpreter`   | `all`        | Python interpreter path on target hosts (e.g. `/usr/bin/python3`)                                 |
| `ansible_ssh_private_key_file` | `all`        | Path to your SSH private key                                                                      |
| `ansible_uid`                  | `all`        | UID of the SSH user (e.g. `1000`)                                                                 |
| `ansible_user`                 | `all`        | SSH user on the Pis (e.g. `pi`)                                                                   |
| `clone_label_prefix`           | `all`        | Partition label prefix for cloned media (e.g. `kub62`)                                            |
| `k3s_server_common_flags`      | `all`        | Common k3s server flags shared by all control-plane nodes                                         |
| `k3s_token`                    | `all`        | Pre-shared secret used to join nodes to the cluster                                               |
| `k3s_url`                      | `all`        | API server URL of the primary control-plane (used by secondary nodes and workers)                 |
| `locale`                       | `all`        | System locale (e.g. `de_AT.UTF-8`)                                                                |
| `timezone`                     | `all`        | System timezone (e.g. `Europe/Vienna`)                                                            |
| `cilium`                       | `group`      | Enables the Cilium CLI add-on on control-plane nodes                                              |
| `flux_enabled`                 | `group`      | Enables the Flux add-on (CLI install + optional bootstrap); default: `false`                      |
| `k3s_server_cilium_flags`      | `group`      | Extra k3s server flags when Cilium is enabled (`--flannel-backend=none --disable-network-policy`) |
| `sops_namespace`               | `group`      | Namespace for the `sops-age` secret (default: `flux-system`)                                      |
| `bodgestr_device_usb_id`       | `host`       | USB vendor:product ID of the touchscreen (e.g. `1234:5678`)                                       |
| `clone_destination`            | `host`       | Set to `nvme` or `usb` to clone the system to the target device (prepared target medium required) |
| `flux_bootstrap`               | `host`       | If `true`, runs `flux bootstrap github` on that node                                              |
| `flux_branch`                  | `host`       | Git branch Flux should track                                                                      |
| `flux_owner`                   | `host`       | GitHub user or org that owns the GitOps repository                                                |
| `flux_pat`                     | `host`       | GitHub personal access token used during bootstrap                                                |
| `flux_path`                    | `host`       | Path inside the repository where cluster manifests live                                           |
| `flux_personal`                | `host`       | Set to `true` for personal (non-org) GitHub accounts                                              |
| `flux_repository`              | `host`       | GitHub repository name for Flux to bootstrap from                                                 |
| `k3s_exec_flags`               | `host/group` | Full k3s installer flags for each node (can also be defined as group var, e.g. workers = `agent`) |
| `kiosk_urls`                   | `host`       | Space-separated URLs for Chromium to open in kiosk mode                                           |
| `sops_key`                     | `host`       | Path to the age private key file used to create the `sops-age` Kubernetes secret                  |

### Provisioning

`control_plane` runs in two phases: first k3s control-plane setup, then add-ons (`Cilium`, `SOPS`, `Flux`).

```bash
# 🚀 Full Cluster Setup (provisions all roles automatically)
ansible-playbook -i inventory/hosts.yaml playbooks/kub62.yaml -v

# Or provision specific groups:

# 🖥️ Control Plane(s) Only (includes Cilium, SOPS & Flux)
ansible-playbook -i inventory/hosts.yaml -l control_plane playbooks/kub62.yaml -v

# 🧑‍💻 Worker Node(s) Only
ansible-playbook -i inventory/hosts.yaml -l worker playbooks/kub62.yaml -v

# 🖥️ Kiosk Node Setup
ansible-playbook -i inventory/hosts.yaml -l kiosk playbooks/kub62.yaml -v

```

> 💡 **Tip:** Use `--vault-password-file=.vaultpass` if SOPS/age encryption is enabled for secrets management.

## 🛠️ Base Role

Applied to **all** nodes (control-plane, workers, and kiosk). It configures:

- 💾 Optional clone to NVMe/USB via [`rpi-clone`](https://github.com/geerlingguy/rpi-clone) is executed first (when
  `clone_destination` is set), including shutdown and reconnect handling
- 🏷️ Hostname
- 🌍 Timezone and locale
- 🔇 Disables Bluetooth, onboard audio, ACT LED, and ModemManager
- 📦 Package updates and cleanup
- 🔧 Configures EEPROM boot order and runs EEPROM updates

## 💾 K3s Base Role

Applied to control-plane and worker nodes. It prepares the Pi for running [`k3s`](https://k3s.io/):

- ⚙️ Adds `cgroup_memory=1 cgroup_enable=memory` kernel flags
- 📦 Installs Longhorn dependencies
- 🧰 Deploys `kub62-node.sh` helper script to the node user's home directory

## 🖥️ K3s Control-Plane Role

Applied to control-plane nodes. It installs and configures [`k3s`](https://k3s.io/) server:

- 🔧 Initializes the first control-plane with `--cluster-init`
- 🤝 Joins additional control-planes via the established cluster token
- 📝 Configures kubeconfig access and permissions
- 🧩 Runs control-plane add-ons in a dedicated follow-up phase

### 🌐 Cilium Add-on

Runs on control-plane nodes in the Control Plane Add-ons phase (when enabled via `cilium: true` in inventory). It
prepares [`Cilium CLI`](https://cilium.io/) prerequisites and tooling. The actual Cilium CNI deployment is handled by
your GitOps repository:

- ⚙️ Requires k3s server flags `--flannel-backend=none --disable-network-policy` (set via `k3s_exec_flags` in inventory)
- 🧰 Installs the Cilium CLI on control-plane nodes
- ⌨️ Adds shell completion for `cilium`
- 🔄 Leaves CNI rollout and policy management to GitOps

### 🔄 Flux Add-on

Runs on control-plane nodes in the Control Plane Add-ons phase (when enabled via `flux_enabled: true` in inventory):

- 📦 Installs the Flux CLI
- ⌨️ Adds shell completion for `flux`
- 🚀 Bootstraps Flux controllers into the cluster when `flux_bootstrap: true` (only runs on the designated node)

### 🔐 SOPS Add-on

Runs on control-plane nodes in the Control Plane Add-ons phase. It provisions an age key secret independently of Flux:

- 🗂️ Ensures the target namespace exists (default: `flux-system`)
- 🔑 Creates/updates the `sops-age` Kubernetes secret from `sops_key`
- 🔄 Can be used with Flux or any other GitOps/controller workflow

## 🧑‍💻 K3s Worker Role

Applied to worker nodes. It installs [`k3s`](https://k3s.io/) agents:

- 🤖 Joins workers to the control-plane cluster
- 🔌 Uses secure tokens from control-plane for authentication

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

Gestures are fully configurable per device — supports multi-screen setups, per-device overrides, custom thresholds,
and arbitrary shell commands as actions.

For the full documentation, see the [`bodgestr` repository](https://github.com/mzellho/bodgestr).

## 🔭 What's Next?

After successfully setting up your [Kubernetes](https://kubernetes.io/) cluster, you have a production-ready foundation
for GitOps workflows and workload management:

- 🔄 **GitOps with Flux:** Use [`Flux`](https://fluxcd.io/) to manage your entire cluster declaratively via Git
- 🔐 **Secrets Management:** Leverage [`SOPS`](https://github.com/mozilla/sops) + [
  `age`](https://github.com/FiloSottile/age) for encrypted secrets in Git
- 📦 **Helm Charts:** Deploy applications via Helm repositories or custom charts
- 🧪 **Testing & Validation:** Run workloads, test networking policies, and validate cluster health
- 📊 **Monitoring:** Set up observability with Prometheus, Loki, or similar tools
- 🏠 **Home Lab Project:** Check out [kub62-gitops](https://github.com/mzellho/kub62-gitops) for a complete GitOps
  reference setup

Your cluster is lightweight, modular, and ready for production use — leverage Flux to keep it declarative and
version-controlled!
