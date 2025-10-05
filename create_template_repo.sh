#!/bin/bash
set -e
# Usage: ./create_template_repo.sh <OWNER> <REPO> [public|private]
OWNER="$1"
REPO="$2"
VISIBILITY="${3:-public}"

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  cat <<EOF
Usage: $0 <owner> <repo> [public|private]
Example: $0 my-org secret-template public
Make sure you ran: gh auth login
EOF
  exit 1
fi

echo "Creating local skeleton in ./$REPO ..."
rm -rf "$REPO"
mkdir -p "$REPO"
cd "$REPO" || exit 1

# --- Create the files (you can instead prepare them in a folder and copy) ---
cat > README.md <<'EOF'
# Template: Secret-scan + pre-commit
This template provides a pre-commit configuration (detect-secrets) and CI scanning with gitleaks.
Run ./setup.sh after cloning to install hooks locally.
EOF

# We'll create example config files (or copy your prepared ones)
cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        stages: [pre-commit]
EOF

mkdir -p .githooks .github/workflows
cat > .githooks/pre-commit <<'EOF'
#!/bin/sh
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --hook-stage pre-commit --files "$@"
else
  echo "pre-commit not installed. Run ./setup.sh"
fi
EOF
chmod +x .githooks/pre-commit

cat > setup.sh <<'EOF'
#!/bin/bash
set -e
git config core.hooksPath .githooks
python3 -m pip install --user pre-commit detect-secrets || true
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push || true
if [ ! -f .secrets.baseline ]; then
  detect-secrets scan > .secrets.baseline || true
  git add .secrets.baseline
  git commit -m "chore: add detect-secrets baseline" || true
fi
echo "Setup complete"
EOF
chmod +x setup.sh

cat > .github/workflows/secret-scan.yml <<'EOF'
name: Secret scan (gitleaks)
on: [pull_request, push]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        with:
          args: --redact --path=.
EOF

# commit
git init
git add .
git commit -m "Initial template: pre-commit secret-scan + CI" || true

# create repo on GitHub and push
echo "Creating GitHub repo $OWNER/$REPO ..."
# create repo from local source and push
gh repo create "$OWNER/$REPO" --"$VISIBILITY" --source=. --remote=origin --push

# mark repo as template and try to enable secret scanning + push protection
echo "Marking repo as template and enabling secret scanning (if allowed by your account)..."
# security_and_analysis payload: enable secret_scanning & push_protection
gh api -X PATCH /repos/"$OWNER"/"$REPO" -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}' -f is_template='true' || {
  echo "Notice: enabling secret scanning/push protection may fail if your account/org doesn't allow it. You can enable manually in repo Settings > Code security & analysis."
}

echo "Template repo created: https://github.com/$OWNER/$REPO"
echo "You can use it as a template from the GitHub UI or with:"
echo "  gh repo create new-repo --template $OWNER/$REPO --public --clone"
