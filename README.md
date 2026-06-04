# Antigravity 2.0 Fedora Installer

A shell-based installation and lifecycle management utility for running Antigravity 2.0 natively under Wayland on Fedora Workstation.

## Tested Environments

* **OS:** Fedora Workstation 43
* **DE:** GNOME (Wayland)

---

## Technical Features

*   **🔒 Isolated Fetch & Extract:** Downloads official Linux x86_64 or ARM64 (aarch64) tarballs from Google Cloud Storage to secure temporary directories before validation and extraction, preventing raw-stream security vulnerabilities.
*   **⚙️ Native Wayland & GPU Optimization:** Automatically injects native Chromium Wayland ozone parameters (`--ozone-platform-hint=wayland` and `--enable-features=WaylandWindowDecorations,CanvasOopRasterization`) to bypass XWayland completely, eliminating graphics lag and text blurriness.
*   **🛡️ SELinux Restorations:** Invokes `restorecon` recursively across installed application paths to maintain strict Fedora security policies.
*   **👥 Dual Install Scope Support:** Operates under system-wide paths (e.g. `/opt`, `/usr/local/bin`) or completely passwordless user-space scopes (e.g. `~/.local/share`, `~/.local/bin`).
*   **🧹 Conflicting Entries Cleanup:** Sweeps and deletes duplicate desktop launcher conflicts (like `antigravity-2.desktop`) and forces standard GNOME cache indexes to update immediately.
*   **🧪 Verification Dry-Runs:** Supports environment testing and download verification via the `--dry-run` flag without making any filesystem modifications.

---

## Installation

There are two primary methods to run the installer: cloning the repository or using the quick one-liner.

### Option 1: Clone and Run
To clone the repository and execute the installer locally:

```bash
git clone https://github.com/jssroberto/antigravity-2-fedora-installer.git
cd antigravity-2-fedora-installer
chmod +x install.sh
./install.sh
```

### Option 2: Quick One-Liner
To download and execute the installer script directly:

```bash
curl -sSL "https://raw.githubusercontent.com/jssroberto/antigravity-2-fedora-installer/main/install.sh" -o install.sh && chmod +x install.sh && ./install.sh
```

---

## Usage & Installation Scopes

### 1. System-Wide Installation (Default)
Extracts the application folder to `/opt/Antigravity-Linux/`, symlinks the execution path to `/usr/local/bin/antigravity`, and registers system-wide launcher menus.
```bash
./install.sh
```
*(Requires administrative privileges; you will be prompted for your `sudo` password).*

### 2. User-Local Installation (Passwordless)
Installs completely under your home directory without requiring elevated privileges.
```bash
./install.sh --user
```
*   **Application Directory:** `~/.local/share/Antigravity-Linux/`
*   **Executable Link:** `~/.local/bin/antigravity`
*   **Desktop Shortcut:** `~/.local/share/applications/antigravity.desktop`

### 3. Dry-Run Verification
Validates the local environment, checks utility prerequisites, and verifies download mirrors without writing any files to your disk:
```bash
./install.sh --dry-run
```

### 4. Custom Archive Override
To install a specific version or override the GCS mirror URL:
```bash
./install.sh --url "https://custom-mirror.com/path/to/Antigravity.tar.gz"
```

## Antigravity 2.0 RPM Distribution

---

### 1. Install Build Dependencies

To build the RPM packages, you need the RPM development toolchain:

```bash
sudo dnf -y groupinstall 'RPM Development Tools'
sudo dnf install -y rpkg
sudo dnf builddep -y antigravity2.spec antigravity2-ide.spec
```

### 2. Build the Packages

Execute the build script to fetch the upstream source tarballs and build the RPM packages locally:

```bash
./build.sh
```

> [!NOTE]
> **Build Duration Note:**
> Building these packages involves downloading upstream archives and compiling files locally:
> * **`antigravity2` (Agent):** Takes ~2 minutes.
> * **`antigravity2-ide` (IDE):** Takes ~3 minutes.
> 
> *Actual build times depend on your network speed and system specifications.*

The generated RPM files will be stored in `~/rpkg/`.

### 3. Install the Packages

Once the build completes successfully, install the packages using `dnf`:

```bash
# Install the Antigravity Agent v2.0
sudo dnf install ~/rpkg/$(uname -m)/antigravity2-2.0.11-*.rpm

# Install the Antigravity IDE v2.0
sudo dnf install ~/rpkg/$(uname -m)/antigravity2-ide-2.0.4-*.rpm
```

## Usage

You can launch either package using your desktop environment launcher or via the command line:

* **Antigravity Agent v2.0:** `antigravity2`
* **Antigravity IDE v2.0:** `antigravity2-ide`

## Uninstallation

To remove the packages:

```bash
sudo dnf remove antigravity2 antigravity2-ide


```

---

## Command-Line Arguments

| Flag | Argument | Description |
| :--- | :--- | :--- |
| `--user` | *None* | Switch scope to user space (`~/.local`). Runs completely without root (`sudo`). |
| `--url` | `<url>` | Override the default Google Cloud Storage download link. |
| `--dry-run` | *None* | Perform validation checks and download package without writing system modifications. |
| `-h, --help` | *None* | Print script usage guide and exit. |

---

## Dual-Version Launcher Integration (Workaround)

If you maintain both the Antigravity IDE (v1.x) and the new standalone application (v2.0) on the same machine, this installation is designed to support both working side-by-side, with dedicated launcher shortcuts:

1. **Antigravity IDE (v1.x):** Registered as **"Antigravity"** (executes `/usr/share/antigravity/antigravity`).
2. **Antigravity 2.0 (Standalone v2.0):** Registered as **"Antigravity 2.0"** (executes `/opt/Antigravity-Linux/antigravity` or local space).

### Wayland Dock Grouping Limitation
Under native Wayland sessions, both the v1.x IDE and the v2.0 standalone executables identify using the exact same Wayland `app_id` (`"antigravity"`).
* **Workaround Mechanism:** Since GNOME Shell maps Wayland windows to launchers strictly by their `.desktop` file name matching their `app_id`, active windows for both versions will group under the primary `antigravity.desktop` (Antigravity 2.0) launcher.
* **Visual Behavior:** When you launch either version (the v1.x IDE or the new 2.0 editor), the running window's active status dot indicator will illuminate under the **Antigravity 2.0** icon in your GNOME dock. This is an upstream limitation of the shared `app_id`, but it allows both environments to work perfectly side-by-side without generating duplicate or conflicting icons in your application grid or dock.

---

## Troubleshooting

### Wayland & Graphics Performance
Fedora Workstation defaults to Wayland. If you experience performance scaling glitches or cursor lag under specific GPU architectures:
1. Open the local desktop entry shortcut file:
   * System-wide: `/usr/share/applications/antigravity.desktop`
   * User-local: `~/.local/share/applications/antigravity.desktop`
2. Verify the native Wayland flags in the `Exec` line:
   ```ini
   Exec=/usr/local/bin/antigravity --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations,CanvasOopRasterization --enable-gpu-rasterization --enable-zero-copy %F
   ```
3. Ensure that your workstation has appropriate hardware acceleration drivers configured (`mesa-dri-drivers` or proprietary GPU drivers with native Wayland support enabled).

---

## Uninstallation

To cleanly wipe all binaries, symlinks, desktop entries, and configuration caches for both scopes:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

---

## License

This project is open-source and available under the [MIT License](LICENSE).
Antigravity 2.0 and its associated branding and assets are property of Google LLC. All trademarks are property of their respective owners.
