#!/bin/bash
set -e
echo "Running repo setup for secret-scanning hooks..."

# 2) install pre-commit (system-wide or user)
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit (pip)..."
  python3 -m pip install --user pre-commit --break-system-packages
  
  # Add Python user bin to PATH for this session
  export PATH="$HOME/Library/Python/$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')/bin:$PATH"
  
  # Verify pre-commit is now available
  if ! command -v pre-commit >/dev/null 2>&1; then
    echo "ERROR: pre-commit still not found after installation. Please add the following to your shell profile:"
    echo "export PATH=\"\$HOME/Library/Python/$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')/bin:\$PATH\""
    exit 1
  fi
fi

# 3) install detect-secrets for local secret scanning
python3 -m pip install --user detect-secrets --break-system-packages || true

# 4) install pre-commit hooks into .git/hooks
echo "Installing pre-commit hooks..."
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push || true

# 5) set hooks path so the template's .githooks is used (after pre-commit install)
echo "Setting up git hooks path..."
if git config core.hooksPath >/dev/null 2>&1; then
  echo "core.hooksPath is already set to: $(git config core.hooksPath)"
  echo "Unsetting it first..."
  git config --unset-all core.hooksPath
fi
git config core.hooksPath .githooks

# 6) generate baseline for detect-secrets if missing
if [ ! -f .secrets.baseline ]; then
  echo "Generating .secrets.baseline using detect-secrets..."
  detect-secrets scan > .secrets.baseline || true
  git add .secrets.baseline
  git commit -m "chore: add detect-secrets baseline" || true
fi

echo "Done. pre-commit installed and hooks enabled. Run 'pre-commit run --all-files' to test."
