# Antigravity 2.0 Fedora Installer

A shell-based installation and lifecycle management utility for running Antigravity 2.0 natively under Wayland on Fedora Workstation.

## Tested Environments

* **OS:** Fedora Workstation 43
* **DE:** GNOME (Wayland)

---

## Technical Features

*   **🔒 Isolated Fetch & Extract:** Downloads official Linux tarballs from Google Cloud Storage to secure temporary directories before validation and extraction, preventing raw-stream security vulnerabilities.
*   **⚙️ Native Wayland & GPU Optimization:** Automatically injects native Chromium Wayland ozone parameters (`--ozone-platform-hint=wayland` and `--enable-features=WaylandWindowDecorations,CanvasOopRasterization`) to bypass XWayland completely, eliminating graphics lag and text blurriness.
*   **🛡️ SELinux Restorations:** Invokes `restorecon` recursively across installed application paths to maintain strict Fedora security policies.
*   **👥 Dual Install Scope Support:** Operates under system-wide paths (e.g. `/opt`, `/usr/local/bin`) or completely passwordless user-space scopes (e.g. `~/.local/share`, `~/.local/bin`).
*   **💻 Architecture Support:** Natively supports both **x86_64** and **aarch64** (ARM64) architectures.
*   **🧹 Conflicting Entries Cleanup:** Sweeps and deletes duplicate desktop launcher conflicts (like `antigravity-2.desktop`) and forces standard GNOME cache indexes to update immediately.
*   **🧪 Verification Dry-Runs:** Supports environment testing and download verification via the `--dry-run` flag without making any filesystem modifications.

---

## Quick Start (One-Liner Install)

To fetch, verify, and execute the installer:

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
*(Requires administrative privileges; you will be prompted for your `sudo` password).*\n\n### 2. User-Local Installation (Passwordless)\nInstalls completely under your home directory without requiring elevated privileges.\n```bash\n./install.sh --user\n```\n*   **Application Directory:** `~/.local/share/Antigravity-Linux/`\n*   **Executable Link:** `~/.local/bin/antigravity`\n*   **Desktop Shortcut:** `~/.local/share/applications/antigravity.desktop`\n\n### 3. Dry-Run Verification\nValidates the local environment, checks utility prerequisites, and verifies download mirrors without writing any files to your disk:\n```bash\n./install.sh --dry-run\n```\n\n### 4. Custom Archive Override\nTo install a specific version or override the GCS mirror URL:\n```bash\n./install.sh --url \"https://custom-mirror.com/path/to/Antigravity.tar.gz\"\n```\n\n---\n\n## Command-Line Arguments\n\n| Flag | Argument | Description |\n| :--- | :--- | :--- |\n| `--user` | *None* | Switch scope to user space (`~/.local`). Runs completely without root (`sudo`). |\n| `--url` | `<url>` | Override the default Google Cloud Storage download link. |\n| `--dry-run` | *None* | Perform validation checks and download package without writing system modifications. |\n| `-h, --help` | *None* | Print script usage guide and exit. |\n\n---\n\n## Dual-Version Launcher Integration (Workaround)\n\nIf you maintain both the Antigravity IDE (v1.x) and the new standalone application (v2.0) on the same machine, this installation is designed to support both working side-by-side, with dedicated launcher shortcuts:\n\n1. **Antigravity IDE (v1.x):** Registered as **\"Antigravity\"** (executes `/usr/share/antigravity/antigravity`).\n2. **Antigravity 2.0 (Standalone v2.0):** Registered as **\"Antigravity 2.0\"** (executes `/opt/Antigravity-Linux/antigravity\" or local space).`