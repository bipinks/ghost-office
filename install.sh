#!/usr/bin/env bash
set -euo pipefail

# DevOps Agent Hub — Install Script
# Usage: curl -fsSL https://raw.githubusercontent.com/bipinks/devops-agent-hub/main/install.sh | bash

REPO_URL="https://github.com/bipinks/devops-agent-hub"
INSTALL_DIR="${HOME}/.devops-agent-hub"
RULES_DIR="${HOME}/.claude/rules"

echo "🚀 Installing DevOps Agent Hub..."
echo ""

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo "❌ git is required but not installed."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js 18+ is required but not installed."; exit 1; }

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo "❌ Node.js 18+ is required. Current version: $(node -v)"
  exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
  echo "📦 Updating existing installation..."
  cd "$INSTALL_DIR" && git pull --rebase
else
  echo "📦 Cloning DevOps Agent Hub..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Install rules
echo ""
echo "📋 Installing rules..."
mkdir -p "$RULES_DIR"

for rule_dir in rules/common rules/terraform rules/kubernetes rules/docker rules/cicd rules/cloud rules/security; do
  if [ -d "$rule_dir" ]; then
    domain=$(basename "$rule_dir")
    mkdir -p "$RULES_DIR/$domain"
    cp -r "$rule_dir/"* "$RULES_DIR/$domain/" 2>/dev/null || true
    echo "  ✅ Installed $domain rules"
  fi
done

# Install as Claude Code plugin (if available)
if command -v claude >/dev/null 2>&1; then
  echo ""
  echo "🔌 Installing as Claude Code plugin..."
  claude plugin marketplace add "$INSTALL_DIR" 2>/dev/null || true
  claude plugin install "devops-agent-hub@devops-agent-hub" 2>/dev/null || \
    claude plugin update "devops-agent-hub" 2>/dev/null || \
    echo "  ℹ️  Plugin install skipped (run: claude plugin marketplace add \"$INSTALL_DIR\" && claude plugin install devops-agent-hub@devops-agent-hub)"
fi

echo ""
echo "✅ DevOps Agent Hub installed successfully!"
echo ""
echo "📍 Installation directory: $INSTALL_DIR"
echo "📋 Rules installed to: $RULES_DIR"
echo ""
echo "🎯 Quick start commands:"
echo "  /infra-plan \"Design a VPC\"       — Plan infrastructure"
echo "  /cicd-setup \"GitHub Actions\"      — Set up CI/CD"
echo "  /deploy                            — Deploy application"
echo "  /security-scan                     — Security audit"
echo "  /forge-deploy                      — Laravel Forge deploy"
echo "  /ms365-provision                   — MS365 provisioning"
echo ""
echo "🤖 Codex quick start:"
echo "  codex -C \"$INSTALL_DIR\""
echo "  codex -C \"$INSTALL_DIR\" -p devops_strict"
echo ""
