# .github

Organization-wide GitHub configuration for syntropyx-tech.

## Contents

- `ISSUE_TEMPLATE/` - Issue templates (feature, bug, chore, spike, refactor)
- `PULL_REQUEST_TEMPLATE.md` - Default PR template
- `CONTRIBUTING.md` - Contribution guidelines
- `SECURITY.md` - Security policy
- `workflows/` - GitHub Actions workflows

## TODO

- [ ] **Org-wide PAT secret** - Owner needs to create `ORG_PROJECT_PAT` org secret with `repo` and `project` scopes. See issue for setup steps.
- [ ] **Auto-labeler workflow** - After org PAT is configured, add workflow to auto-apply domain labels (api/devops/ui) based on issue form dropdown selection.
