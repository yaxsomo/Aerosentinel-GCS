# ── System packages required by Rust, Tauri & USB work ─────────────────────────
sudo apt update && sudo apt install -y \
  build-essential curl git cmake pkg-config libssl-dev \
  libgtk-3-dev libsoup3-dev webkit2gtk-4.0 libwebkit2gtk-4.0-dev \
  libusb-1.0-0-dev protobuf-compiler

# ── Rust (stable) + common targets ─────────────────────────────────────────────
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add x86_64-pc-windows-gnu aarch64-apple-darwin

# ── Node LTS + pnpm (preferred) ────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pnpm

# ── Tauri CLI (generates scaffolding & bundles installers) ─────────────────────
cargo install tauri-cli
