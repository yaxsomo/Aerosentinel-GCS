#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  Aerosentinel-GCS ⇒ workspace skeleton generator
#  run this from  ~/Aerosentinel-GCS   (repo root)
# ──────────────────────────────────────────────────────────────────────────────

## 0. new branch --------------------------------------------------------------
git checkout -b skeleton      # <— no-op if it already exists

## 1. directory scaffold ------------------------------------------------------
mkdir -p {apps,crates,proto,docs,scripts,.github/workflows}

## 2. front-end desktop app (Tauri + React) -----------------------------------
cd apps
# NOTE: “cargo tauri” is the correct v2 CLI entry-point
cargo tauri init gcs-desktop \
  --app-name "Aerosentinel GCS" \
  --window-title "Aerosentinel GCS" \
  --template react-ts \
  --ci
cd ..

## 3. Rust workspace member crates -------------------------------------------
for c in telemetry flash config playback; do
  cargo new --lib "crates/$c"
done

## 4. workspace manifest ------------------------------------------------------
cat > Cargo.toml <<'EOF'
[workspace]
members = ["crates/*", "apps/gcs-desktop/src-tauri"]
resolver = "2"
EOF

## 5. basic .gitignore --------------------------------------------------------
cat > .gitignore <<'EOF'
/target
/node_modules
.DS_Store
dist/
/.env*
EOF

## 6. pre-commit hook (fmt + lint) -------------------------------------------
cat > scripts/pre-commit <<'EOF'
#!/usr/bin/env bash
cargo fmt --all
cargo clippy --workspace --quiet -- -D warnings
pnpm --filter ./apps/gcs-desktop lint
EOF
chmod +x scripts/pre-commit
ln -sf ../../scripts/pre-commit .git/hooks/pre-commit   # force-update if present

## 7. GitHub Actions CI stub ---------------------------------------------------
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
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - name: Install Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: pnpm install --frozen-lockfile
        working-directory: apps/gcs-desktop
      - run: cargo test --workspace --all-features --verbose
EOF

## 8. first commit ------------------------------------------------------------
git add .
git commit -m "feat: bootstrap workspace skeleton"
git push --set-upstream origin skeleton
