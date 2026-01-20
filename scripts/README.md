# Scripts

Automation scripts for managing GitHub labels and workflows across repositories.

## Requirements

- [GitHub CLI (gh)](https://cli.github.com/) - installed and authenticated
- Git - for workflow migration script
- SSH key configured for GitHub access. Workflow migration uses `git@github.com`

## Quick Start

```bash
# Run label setup and workflow migration for all repos
./update_repos.sh

# OR, run with a custom repo list
./update_repos.sh --list my_repos.txt
```

## Scripts

### update_repos.sh

Main entry point that runs both label setup and workflow migration.

**Usage:**

```bash
# Run both tasks with default repo_list.txt
./update_repos.sh

# Use custom repo list
./update_repos.sh --list my_repos.txt

# Run only label setup
./update_repos.sh --labels-only

# Run only workflow migration
./update_repos.sh --workflow-only
```

**Options:**
- `--list <file>` - specify a custom repository list file
- `--labels-only` - skip workflow migration, only setup labels
- `--workflow-only` - skip label setup, only migrate workflows

---

### _setup-labels.sh

> Subscript - typically called via `update_repos.sh`

Creates or updates the standard label set across repositories. Removes default GitHub labels that aren't used.

**Labels Created:**

| Type | Labels |
|------|--------|
| Issue Types | `bug`, `feature`, `chore`, `spike`, `refactor` |
| Domains | `admin`, `api`, `devops`, `ui`, `quant`, `contracts` |

**Direct Usage:**

```bash
# Single repository
./_setup-labels.sh syntropyx-tech/my-repo

# Multiple repositories from file
./_setup-labels.sh --list repo_list.txt
```

**What it does:**
1. Checks that `gh` CLI is installed and authenticated
2. Shows a dry run summary of repositories and labels
3. Prompts for Y/N confirmation
4. Creates/updates labels in each repository
5. Removes default GitHub labels (documentation, duplicate, enhancement, etc.)

---

### _migrate_auto_labeler_workflow.sh

> Subscript - typically called via `update_repos.sh`

Deploys the issue auto-labeler workflow to repositories. Creates a branch, commits the workflow file, pushes, and opens a PR.

**Direct Usage:**

```bash
# Single repository
./_migrate_auto_labeler_workflow.sh my-repo

# Multiple repositories from file
./_migrate_auto_labeler_workflow.sh --list repo_list.txt
```

**What it does:**
1. Checks requirements (git, gh, SSH connectivity)
2. Shows a dry run summary
3. Prompts for Y/N confirmation
4. For each repository:
   - Clones to `scripts/repo_workflow_migration/<repo>`
   - Skips if workflow already exists
   - Creates branch `feature/issue-auto-labeler`
   - Copies `issue-automation-caller.yml` workflow
   - Commits with message `feat: add issue label automation`
   - Pushes branch via SSH
   - Creates a pull request

**Notes:**
- Requires Git SSH authentication (not HTTPS)
- Cloned repositories are stored in `repo_workflow_migration/` (gitignored)
- You can delete the clone directory after the script completes

---

## Repository List

The `repo_list.txt` file contains the list of repositories to process:

Edit this file to add or remove repositories. Lines starting with `#` are treated as comments.

## Typical Workflow

When setting up a new repository or onboarding multiple repos:

```bash
# Option 1: Run everything at once
./update_repos.sh

# Option 2: Run steps separately
./update_repos.sh --labels-only
./update_repos.sh --workflow-only

# Clean up cloned repos after workflow migration (optional)
rm -rf repo_workflow_migration/
```
