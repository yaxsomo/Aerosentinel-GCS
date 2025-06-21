#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  Aerosentinel-GCS ⇒ workspace skeleton generator
#  Run this from  ~/Aerosentinel-GCS   (repo root)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

## 0 · new branch --------------------------------------------------------------
git checkout -b skeleton || git switch skeleton

## 1 · directory scaffold ------------------------------------------------------
mkdir -p {apps,crates,proto,docs,scripts,.github/workflows}

## 2 · front-end desktop app  (Vite-React-TS + Tauri) --------------------------
cd apps
mkdir -p gcs-desktop
cd gcs-desktop

# 2.1  React + TS scaffold via Vite
pnpm create vite@latest . -- --template react-ts --name gcs-desktop

# 2.2  Add Tauri Rust harness (no --template flag in v2)
cargo tauri init \
  --app-name     "Aerosentinel GCS" \
  --window-title "Aerosentinel GCS" \
  --ci

# 2.3  Install Node deps once
pnpm install
cd ../..      # back to repo root

## 3 · Rust workspace member crates -------------------------------------------
for c in telemetry flash config playback; do
  cargo new --lib "crates/$c"
done

## 4 · workspace manifest ------------------------------------------------------
cat > Cargo.toml <<'EOF'
[workspace]
members = ["crates/*", "apps/gcs-desktop/src-tauri"]
resolver = "2"
EOF

## 5 · basic .gitignore --------------------------------------------------------
cat > .gitignore <<'EOF'
/target
/node_modules
.DS_Store
dist/
/.env*
EOF

## 6 · pre-commit hook (fmt + lint) -------------------------------------------
cat > scripts/pre-commit <<'EOF'
#!/usr/bin/env bash
cargo fmt --all
cargo clippy --workspace --quiet -- -D warnings
pnpm --filter ./apps/gcs-desktop lint
EOF
chmod +x scripts/pre-commit
ln -sf ../../scripts/pre-commit .git/hooks/pre-commit   # force-update if present

## 7 · GitHub Actions CI stub --------------------------------------------------
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}

    steps:
      # 1. Checkout
      - uses: actions/checkout@v4

      # 2. Rust tool-chain
      - uses: dtolnay/rust-toolchain@stable

      # 3. Node.js
      - name: Install Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      # 4. pnpm
      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8
          run_install: false

      # 5. Front-end deps
      - name: Install front-end deps
        run: pnpm install --frozen-lockfile
        working-directory: apps/gcs-desktop

      # 6. Rust tests
      - name: Cargo tests
        run: cargo test --workspace --all-features --verbose
EOF

## 8 · first commit ------------------------------------------------------------
git add .
git commit -m "feat: bootstrap workspace skeleton"
git push --set-upstream origin skeleton
