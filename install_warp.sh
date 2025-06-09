#!/usr/bin/env bash
set -e

# Check for sudo privileges
if ! sudo -n true 2>/dev/null; then
  echo "Error: This script requires sudo privileges to run. Please execute it with sudo or as a user with sudo access." >&2
  exit 1
fi

# Check for network connectivity
echo "Checking network connectivity..."
if ! ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
  echo "Error: No network connectivity. Please check your internet connection and try again." >&2
  exit 1
fi
echo "Network connectivity check successful."

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
  if ! command -v lsb_release >/dev/null 2>&1; then
    echo "Error: \`lsb_release\` command not found. Please install it (e.g., \`sudo apt install lsb-release\`) and try again."
    exit 1
  fi
  echo "Adding Cloudflare GPG key and repository for Debian/Ubuntu..."
  GPG_KEY_URL="https://pkg.cloudflareclient.com/pubkey.gpg"
  echo "Downloading GPG key from $GPG_KEY_URL..."
  GPG_KEY_DATA=$(curl -fsSL "$GPG_KEY_URL")
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download GPG key from $GPG_KEY_URL. Please check your network connection and try again."
    exit 1
  fi
  echo "$GPG_KEY_DATA" | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
  echo "Updating package list..."
  sudo apt-get update
  echo "Installing cloudflare-warp..."
  sudo apt-get install -y cloudflare-warp
}

install_rpm() {
  echo "Adding Cloudflare repository for RPM-based distro..."
  REPO_URL="https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo"
  echo "Downloading repository file from $REPO_URL..."
  REPO_DATA=$(curl -fsSL "$REPO_URL")
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download repository file from $REPO_URL. Please check your network connection and try again."
    exit 1
  fi
  echo "$REPO_DATA" | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
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

echo "Attempting to register Cloudflare WARP..."
echo "If this is the first time, you might be prompted to log in via a browser."
MAX_RETRIES=3
RETRY_DELAY=5
REGISTRATION_TIMEOUT=30s
CONNECTION_TIMEOUT=15s

# Retry logic for warp-cli register
for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempting to register Cloudflare WARP (attempt $i/$MAX_RETRIES)..."
  if timeout $REGISTRATION_TIMEOUT warp-cli register; then
    echo "WARP registration successful or already registered."
    break
  else
    if [ $i -lt $MAX_RETRIES ]; then
      echo "Registration attempt $i failed. Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    else
      echo "WARP registration failed after $MAX_RETRIES attempts. Please check for any error messages above."
      echo "You might need to run 'warp-cli register' manually."
      exit 1
    fi
  fi
done

# Retry logic for warp-cli connect
echo "Attempting to connect Cloudflare WARP..."
for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempting to connect Cloudflare WARP (attempt $i/$MAX_RETRIES)..."
  if timeout $CONNECTION_TIMEOUT warp-cli connect; then
    echo "WARP connected successfully."
    break
  else
    if [ $i -lt $MAX_RETRIES ]; then
      echo "Connection attempt $i failed. Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    else
      echo "WARP connection failed after $MAX_RETRIES attempts. Please check for any error messages above."
      echo "You might need to run 'warp-cli connect' manually."
      exit 1
    fi
  fi
done

echo "Cloudflare WARP has been installed and set up."
