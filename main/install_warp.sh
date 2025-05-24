#!/usr/bin/env bash
set -e

# Function to check if warp-cli is installed
check_if_warp_installed() {
  if command -v warp-cli >/dev/null 2>&1; then
    echo "Cloudflare WARP (warp-cli) is already installed. Halting script."
    exit 0
  else
    echo "Cloudflare WARP (warp-cli) not found. Proceeding with installation."
  fi
}

# Detect package manager
if command -v apt-get >/dev/null; then
  PM="apt"
elif command -v yum >/dev/null; then
  PM="yum"
elif command -v dnf >/dev/null; then
  PM="dnf"
else
  echo "Unsupported package manager. Exiting."
  exit 1
fi

# --- Call the check function early ---
check_if_warp_installed
# ---

install_debian() {
  echo "Adding Cloudflare GPG key and repository for Debian/Ubuntu..."
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
  echo "Updating package list..."
  sudo apt-get update
  echo "Installing cloudflare-warp..."
  sudo apt-get install -y cloudflare-warp
}

install_rpm() {
  echo "Adding Cloudflare repository for RPM-based distro..."
  curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo \
    | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
  echo "Updating package list (may take a moment for new repo)..."
  if [ "$PM" = "yum" ]; then
    sudo yum clean expire-cache # Ensures new repo is picked up
    echo "Installing cloudflare-warp..."
    sudo yum install -y cloudflare-warp
  else # dnf
    sudo dnf clean expire-cache # Ensures new repo is picked up
    echo "Installing cloudflare-warp..."
    sudo dnf install -y cloudflare-warp
  fi
}

echo "Starting Cloudflare WARP installation using $PM..."

case "$PM" in
  apt)
    install_debian
    ;;
  yum|dnf)
    install_rpm
    ;;
esac

echo "Attempting to register and connect Cloudflare WARP..."
echo "If this is the first time, you might be prompted to log in via a browser."
if warp-cli register; then
  echo "WARP registration successful or already registered."
else
  echo "WARP registration failed. Please check for any error messages above."
  echo "You might need to run 'warp-cli register' manually."
  exit 1
fi

if warp-cli connect; then
  echo "WARP connected successfully."
else
  echo "WARP connection failed. Please check for any error messages above."
  echo "You might need to run 'warp-cli connect' manually."
  exit 1
fi

echo "Cloudflare WARP has been installed and set up."
