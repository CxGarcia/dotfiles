#!/bin/bash
set -euo pipefail

# Setup secure SSH access over Tailscale
# - Only allows connections from Tailscale CGNAT range (100.64.0.0/10)
# - Key-only auth (no passwords)
# - Adds Moshi (iOS) public key

SSHD_CONF="/etc/ssh/sshd_config.d/200-tailscale-hardening.conf"
CURRENT_USER="$(whoami)"

# --- Preflight checks ---

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: this script is macOS-only"
  exit 1
fi

if ! command -v tailscale &>/dev/null; then
  echo "Error: tailscale is not installed"
  echo "Install from: https://tailscale.com/download/mac"
  exit 1
fi

TAILSCALE_IP="$(tailscale ip -4 2>/dev/null || true)"
if [[ -z "$TAILSCALE_IP" ]]; then
  echo "Error: tailscale is not connected (no IPv4 address)"
  echo "Open Tailscale and sign in first"
  exit 1
fi

echo "Tailscale IP: $TAILSCALE_IP"
echo "User:         $CURRENT_USER"
echo ""

# --- SSH hardening config ---

echo "Writing sshd config to $SSHD_CONF ..."
sudo tee "$SSHD_CONF" > /dev/null << EOF
# Tailscale-only SSH hardening (managed by dotfiles)

# Key-only authentication
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no

# No root login
PermitRootLogin no

# Only allow user from Tailscale CGNAT range
AllowUsers ${CURRENT_USER}@100.64.0.0/10

# Limit auth attempts
MaxAuthTries 3

# Deny everyone else
Match Address *,!100.64.0.0/10
    DenyUsers *
EOF

# --- Authorized keys ---

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo ""
echo "Paste your Moshi public key (ssh-ed25519 ...):"
read -r MOSHI_PUBKEY

if [[ ! "$MOSHI_PUBKEY" =~ ^ssh-(ed25519|rsa|ecdsa) ]]; then
  echo "Error: doesn't look like a valid public key"
  exit 1
fi

if ! grep -qF "$MOSHI_PUBKEY" ~/.ssh/authorized_keys; then
  echo "$MOSHI_PUBKEY" >> ~/.ssh/authorized_keys
  echo "Added public key to authorized_keys"
else
  echo "Public key already present"
fi

# --- Enable Remote Login ---

REMOTE_LOGIN="$(sudo systemsetup -getremotelogin 2>/dev/null | awk '{print $NF}')"
if [[ "$REMOTE_LOGIN" != "On" ]]; then
  echo "Enabling Remote Login (sshd) ..."
  sudo systemsetup -setremotelogin on
else
  echo "Remote Login already enabled, restarting sshd ..."
  sudo launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
fi

# --- Verify ---

echo ""
echo "Verifying ..."
sleep 1

if nc -z -w 3 "$TAILSCALE_IP" 22 2>/dev/null; then
  echo "OK: sshd reachable on $TAILSCALE_IP:22"
else
  echo "WARN: sshd not reachable on $TAILSCALE_IP:22 — check Tailscale connection"
fi

echo ""
echo "Done! Connect from Moshi:"
echo "  Host: $TAILSCALE_IP"
echo "  User: $CURRENT_USER"
echo "  Port: 22"
