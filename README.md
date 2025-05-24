# Cloudflare WARP Installer Script

This script automates the installation of the Cloudflare WARP client on various Linux distributions. It detects the package manager, adds the necessary repositories and GPG keys, installs WARP, and attempts to register and connect the client.

## Features

*   Automatically detects your Linux distribution's package manager (APT for Debian/Ubuntu, YUM/DNF for RPM-based distros like Fedora, CentOS, RHEL).
*   Adds the official Cloudflare WARP GPG key and package repository.
*   Checks if Cloudflare WARP (`warp-cli`) is already installed and halts if it is.
*   Installs the `cloudflare-warp` package.
*   Attempts to register the WARP client (`warp-cli register`). This may require browser interaction for login.
*   Attempts to connect to the WARP network (`warp-cli connect`).

## Supported Distributions

*   Debian-based systems (e.g., Ubuntu, Mint)
*   RPM-based systems (e.g., Fedora, CentOS, RHEL, AlmaLinux, Rocky Linux)

## Prerequisites

*   `curl`: To download repository information and GPG keys.
*   `sudo` access: The script needs to run commands as root to install software and configure repositories.
*   Internet connection.
*   `lsb_release`: Required by the script for Debian/Ubuntu based systems to determine the distribution codename. (Usually pre-installed, install with `sudo apt install lsb-release` if missing).
*   `gpg`: To handle repository keys. (Usually pre-installed).

## Usage

There are two primary ways to use this script:

### Method 1: Direct Execution with `curl` (Recommended for quick use)

You can download and execute the script directly in one command.

**Important Security Note:** Only run scripts from the internet this way if you trust the source.

```bash
curl -fsSL https://raw.githubusercontent.com/dragon-Elec/warp-installer-script/main/install_warp.sh | sudo bash
```

### Method 2: Clone and Run Locally

1.  **Clone the repository (if you haven't already):**
    ```bash
    git clone https://github.com/dragon-Elec/warp-installer-script.git
    cd warp-installer-script
    ```

2.  **Make the script executable (if needed, though `sudo bash` bypasses this):**
    ```bash
    chmod +x install_warp.sh
    ```
    *(Adjust `install_warp.sh` if your script has a different name).*

3.  **Run the script:**
    ```bash
    sudo ./install_warp.sh
    ```
    Alternatively, you can run it with `sudo bash install_warp.sh`.

## Post-Installation

After the script completes:
*   If `warp-cli register` required manual browser authentication, ensure you completed that step.
*   You can check the WARP status with `warp-cli status`.
*   Other useful commands: `warp-cli disconnect`, `warp-cli disable-dns-log`.

## Contributing

Feel free to open an issue if you find a bug or have a suggestion. Pull requests are also welcome!

## License

This project is licensed under the **MIT License** - see the `LICENSE` file for details.
