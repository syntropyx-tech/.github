#!/bin/bash
set -e

REPO=$1

if [ -z "$REPO" ]; then
  echo "Usage: ./setup-labels.sh <owner/repo>"
  exit 1
fi

echo "Creating labels in $REPO..."

# Issue types
gh label create bug --color d73a4a --description "Something isn't working" --repo "$REPO" 2>/dev/null || gh label edit bug --color d73a4a --description "Something isn't working" --repo "$REPO"
gh label create feature --color a2eeef --description "New feature request" --repo "$REPO" 2>/dev/null || gh label edit feature --color a2eeef --description "New feature request" --repo "$REPO"
gh label create chore --color fef2c0 --description "Maintenance task" --repo "$REPO" 2>/dev/null || gh label edit chore --color fef2c0 --description "Maintenance task" --repo "$REPO"
gh label create spike --color d4c5f9 --description "Research or investigation" --repo "$REPO" 2>/dev/null || gh label edit spike --color d4c5f9 --description "Research or investigation" --repo "$REPO"
gh label create refactor --color fbca04 --description "Code improvement" --repo "$REPO" 2>/dev/null || gh label edit refactor --color fbca04 --description "Code improvement" --repo "$REPO"

# Domains
gh label create admin --color 5319e7 --description "Administrative tasks" --repo "$REPO" 2>/dev/null || gh label edit admin --color 5319e7 --description "Administrative tasks" --repo "$REPO"
gh label create api --color 0052cc --description "API related" --repo "$REPO" 2>/dev/null || gh label edit api --color 0052cc --description "API related" --repo "$REPO"
gh label create devops --color f9a825 --description "Infrastructure or CI/CD" --repo "$REPO" 2>/dev/null || gh label edit devops --color f9a825 --description "Infrastructure or CI/CD" --repo "$REPO"
gh label create ui --color e91e63 --description "User interface" --repo "$REPO" 2>/dev/null || gh label edit ui --color e91e63 --description "User interface" --repo "$REPO"

# Remove default git labels
gh label delete documentation --repo "$REPO" --yes 2>/dev/null || true
gh label delete duplicate --repo "$REPO" --yes 2>/dev/null || true
gh label delete enhancement --repo "$REPO" --yes 2>/dev/null || true
gh label delete "good first issue" --repo "$REPO" --yes 2>/dev/null || true
gh label delete "help wanted" --repo "$REPO" --yes 2>/dev/null || true
gh label delete invalid --repo "$REPO" --yes 2>/dev/null || true
gh label delete question --repo "$REPO" --yes 2>/dev/null || true
gh label delete wontfix --repo "$REPO" --yes 2>/dev/null || true

echo "Done"
