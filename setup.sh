#!/bin/bash
set -e
echo "Running repo setup for secret-scanning hooks..."

# 1) set hooks path so the template's .githooks is used
git config core.hooksPath .githooks

# 2) install pre-commit (system-wide or user)
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit (pip)..."
  python3 -m pip install --user pre-commit
fi

# 3) install detect-secrets and gitguardian if you want them locally
python3 -m pip install --user detect-secrets || true
python3 -m pip install --user ggshield || true  # optional

# 4) install pre-commit hooks into .git/hooks
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push || true

# 5) generate baseline for detect-secrets if missing
if [ ! -f .secrets.baseline ]; then
  echo "Generating .secrets.baseline using detect-secrets..."
  detect-secrets scan > .secrets.baseline || true
  git add .secrets.baseline
  git commit -m "chore: add detect-secrets baseline" || true
fi

echo "Done. pre-commit installed and hooks enabled. Run 'pre-commit run --all-files' to test."
