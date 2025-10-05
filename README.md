# Pre-Commit Security Template

This repository template provides automated secret detection for your code commits.

## Quick Setup for Team Members

After cloning this repository, run:

```bash
./setup.sh
```

This will:
- Install pre-commit hooks
- Install detect-secrets
- Configure git hooks
- Generate secrets baseline

## What It Does

Automatically scans your commits for:
- AWS Keys
- GitHub Tokens
- API Keys (Stripe, SendGrid, etc.)
- Private Keys
- Passwords
- High-entropy strings
- And 27+ other secret types

## Usage

Just commit normally. The hook will automatically check for secrets:

```bash
git add myfile.py
git commit -m "Add feature"
```

If secrets are detected, the commit will be blocked.

## Template Status

✅ GitGuardian removed
✅ detect-secrets configured
✅ Secrets baseline ready
✅ Git hooks configured
