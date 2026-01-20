#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

CLONE_DIR="${SCRIPT_DIR}/repo_workflow_migration"
WORKFLOW_SOURCE="${SCRIPT_DIR}/../.github/workflows/issue-automation-caller.yml"
BRANCH_NAME="feature/issue-auto-labeler"
COMMIT_MESSAGE="feat: add issue label automation"

usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 <repo>                    Migrate workflow to a single repository"
    echo "  $0 --list <filename>         Migrate workflow to all repos in file"
    echo "  $0 --test                    Test run on ${TEST_REPO} only"
    echo "  $0 --force                   Update existing workflows (create new PR)"
    echo ""
    echo -e "${BLUE}Requirements:${NC}"
    echo "  - Git and GitHub CLI (gh) installed and authenticated"
    echo "  - SSH key configured for GitHub (uses git@github.com:...)"
    echo ""
    echo -e "${BLUE}Notes:${NC}"
    echo "  - Repos cloned to: ${CLONE_DIR} (can delete after)"
    echo "  - Existing workflows will be skipped (unless --force)"
    exit 1
}

check_requirements() {
    echo -e "${BLUE}Checking requirements...${NC}"
    local has_error=false

    check_git || has_error=true
    check_gh || has_error=true

    if [[ -f "$WORKFLOW_SOURCE" ]]; then
        echo -e "${GREEN}✓ Workflow source file exists${NC}"
    else
        echo -e "${RED}✗ Workflow source not found: ${WORKFLOW_SOURCE}${NC}"
        has_error=true
    fi

    if [[ "$has_error" == "true" ]]; then exit 1; fi
}

migrate_workflow_to_repo() {
    local REPO_NAME=$1
    local FORCE=$2
    local FULL_REPO="${ORG}/${REPO_NAME}"
    local REPO_DIR="${CLONE_DIR}/${REPO_NAME}"
    local SSH_URL="git@github.com:${ORG}/${REPO_NAME}.git"
    local WORKFLOW_DEST=".github/workflows/issue-automation-caller.yml"
    local IS_UPDATE=false

    echo -e "${BLUE}Processing: ${FULL_REPO}${NC}"

    [[ -d "$REPO_DIR" ]] && rm -rf "$REPO_DIR"

    if ! git clone --depth 1 "$SSH_URL" "$REPO_DIR" 2>&1; then
        echo -e "${RED}  ✗ Failed to clone${NC}"
        return 1
    fi

    cd "$REPO_DIR"

    if [[ -f "$WORKFLOW_DEST" ]]; then
        if [[ "$FORCE" != "true" ]]; then
            echo -e "${YELLOW}  ⏭ Workflow exists, skipping${NC}"
            cd "$SCRIPT_DIR"
            return 2
        fi
        IS_UPDATE=true
        echo -e "${CYAN}  ↻ Workflow exists, forcing update${NC}"
    fi

    git fetch origin 2>/dev/null || true
    if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
        if [[ "$FORCE" != "true" ]]; then
            echo -e "${YELLOW}  ⏭ Branch exists, skipping${NC}"
            cd "$SCRIPT_DIR"
            return 2
        fi
        echo -e "${CYAN}  ↻ Deleting existing branch${NC}"
        git push origin --delete "$BRANCH_NAME" 2>/dev/null || true
    fi

    git checkout -b "$BRANCH_NAME"
    mkdir -p .github/workflows
    cp "$WORKFLOW_SOURCE" "$WORKFLOW_DEST"
    git add "$WORKFLOW_DEST"

    # Check if there are actual changes
    if git diff --cached --quiet; then
        echo -e "${YELLOW}  ⏭ No changes needed, skipping${NC}"
        cd "$SCRIPT_DIR"
        return 2
    fi

    local msg="feat: add issue label automation"
    local pr_body="Adds workflow for automatic issue labeling. Calls reusable workflow from \`${ORG}/.github\`."
    if $IS_UPDATE; then
        msg="feat: update issue label automation"
        pr_body="Updates workflow for automatic issue labeling. Calls reusable workflow from \`${ORG}/.github\`."
    fi

    git commit -m "$msg"
    git push --set-upstream origin "$BRANCH_NAME"

    local PR_URL
    PR_URL=$(gh pr create \
        --repo "$FULL_REPO" \
        --title "$msg" \
        --body "$pr_body" \
        --head "$BRANCH_NAME" 2>&1) || {
        echo -e "${RED}  ✗ Failed to create PR${NC}"
        cd "$SCRIPT_DIR"
        return 1
    }

    echo -e "${GREEN}  ✓ PR created: ${PR_URL}${NC}"
    PR_URLS+=("$PR_URL")
    cd "$SCRIPT_DIR"
}

dry_run() {
    local repos=("$@")
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}           DRY RUN SUMMARY            ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${YELLOW}Repositories (${#repos[@]}):${NC}"
    for repo in "${repos[@]}"; do echo "  - ${ORG}/${repo}"; done
    echo ""
    echo -e "${YELLOW}Force mode:${NC} $([[ "$FORCE_MODE" == "true" ]] && echo "${GREEN}yes${NC}" || echo "no")"
    echo -e "${YELLOW}Actions:${NC} Clone → Check workflow → Create branch → Copy workflow → Push → Create PR"
    echo -e "${CYAN}Clone dir:${NC} ${CLONE_DIR} (delete after completion)"
    echo -e "${BLUE}======================================${NC}"
}

# Parse arguments
REPOS=()
LIST_FILE=""
TEST_MODE=false
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TEST_MODE=true
            shift
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --list)
            [[ -z "$2" || "$2" == -* ]] && { echo -e "${RED}Error: --list requires a filename${NC}"; exit 1; }
            LIST_FILE="$2"
            shift 2
            ;;
        -h|--help) usage ;;
        *) REPOS+=("$1"); shift ;;
    esac
done

if $TEST_MODE; then
    test_mode_banner
    REPOS=("${TEST_REPO}")
elif [[ -n "$LIST_FILE" ]]; then
    read_repo_list "$LIST_FILE" REPOS false
fi

[[ ${#REPOS[@]} -eq 0 ]] && usage

mkdir -p "$CLONE_DIR"

# Ensure clone dir is gitignored
GITIGNORE="${SCRIPT_DIR}/.gitignore"
grep -q "repo_workflow_migration" "$GITIGNORE" 2>/dev/null || echo "repo_workflow_migration/" >> "$GITIGNORE"

check_requirements
dry_run "${REPOS[@]}"
confirm

SUCCESS=0 SKIP=0 FAIL=0
PR_URLS=()

for repo in "${REPOS[@]}"; do
    set +e
    migrate_workflow_to_repo "$repo" "$FORCE_MODE"
    ret=$?
    set -e
    case $ret in
        0) ((SUCCESS++)) || true ;;
        2) ((SKIP++)) || true ;;
        *) ((FAIL++)) || true ;;
    esac
done

echo ""
echo -e "${BLUE}Complete:${NC} ${GREEN}${SUCCESS} success${NC}, ${YELLOW}${SKIP} skipped${NC}, ${RED}${FAIL} failed${NC}"

if [[ ${#PR_URLS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}Pull Requests:${NC}"
    for url in "${PR_URLS[@]}"; do
        echo "  $url"
    done
fi

echo ""
echo -e "${CYAN}Cleanup:${NC} rm -rf ${CLONE_DIR}"
