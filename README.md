# .github

Organization-wide GitHub configuration for syntropyx-tech.

## Contents

- `.github/ISSUE_TEMPLATE/` - Issue templates (feature, bug, chore, spike, refactor)
- `.github/labels.yml` - Label definitions (reference)
- `.github/workflows/issue-automation.yml` - Reusable workflow for domain labeling
- `PULL_REQUEST_TEMPLATE.md` - Default PR template
- `CONTRIBUTING.md` - Contribution guidelines
- `SECURITY.md` - Security policy
- `setup-labels.sh` - Script to create labels in a repo

## New Repo Setup

### Labels

```bash
./setup-labels.sh syntropyx-tech/<repo-name>
```

### Issue Automation

Copy [`.github/workflows/issue-automation-caller.yml`](.github/workflows/issue-automation-caller.yml) to the repo at `.github/workflows/`.