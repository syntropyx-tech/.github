#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

ENV_FILE="${SCRIPT_DIR}/.env"
SECRET_NAME="REPO_PROJECTS_PAT"

usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 <repo>                    Set token for a single repository"
    echo "  $0 --list <filename>         Set token for all repos in file"
    echo "  $0 --test                    Test run on ${TEST_REPO} only"
    echo "  $0 --check                   Only check which repos are missing the secret"
    echo ""
    echo -e "${BLUE}Setup:${NC}"
    echo "  1. Copy .env.example to .env"
    echo "  2. Add your PAT to .env"
    echo "  3. Run this script"
    exit 1
}

# Check if a repo has the secret configured
repo_has_secret() {
    local repo="$1"
    gh secret list --repo "${ORG}/${repo}" 2>/dev/null | grep -q "^${SECRET_NAME}" && return 0 || return 1
}

# Get list of repos missing the secret
get_repos_missing_secret() {
    local repos=("$@")
    local missing=()
    for repo in "${repos[@]}"; do
        if ! repo_has_secret "$repo"; then
            missing+=("$repo")
        fi
    done
    echo "${missing[@]}"
}

setup_token_for_repo() {
    local REPO=$1
    local FULL_REPO="${ORG}/${REPO}"

    echo -e "${BLUE}Setting ${SECRET_NAME} for ${FULL_REPO}...${NC}"

    if repo_has_secret "$REPO"; then
        echo -e "  ${YELLOW}↻ Secret exists, updating...${NC}"
    fi

    if echo "$PAT_VALUE" | gh secret set "$SECRET_NAME" --repo "$FULL_REPO" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Secret configured${NC}"
    else
        echo -e "  ${RED}✗ Failed to set secret${NC}"
        return 1
    fi
}

dry_run() {
    local repos=("$@")
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}           DRY RUN SUMMARY            ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${YELLOW}Repositories (${#repos[@]}):${NC}"
    for repo in "${repos[@]}"; do
        if repo_has_secret "$repo"; then
            echo -e "  - ${ORG}/${repo} ${GREEN}(has secret)${NC}"
        else
            echo -e "  - ${ORG}/${repo} ${RED}(missing)${NC}"
        fi
    done
    echo ""
    echo -e "${YELLOW}Secret:${NC} ${SECRET_NAME}"
    echo -e "${YELLOW}Source:${NC} ${ENV_FILE}"
    echo -e "${BLUE}======================================${NC}"
}

# Parse arguments
REPOS=()
LIST_FILE=""
TEST_MODE=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TEST_MODE=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
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

echo -e "${BLUE}Checking requirements...${NC}"
check_gh || exit 1

# Check-only mode
if $CHECK_ONLY; then
    echo ""
    echo -e "${BLUE}Checking secret status...${NC}"
    missing=($(get_repos_missing_secret "${REPOS[@]}"))

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo -e "${GREEN}All repos have ${SECRET_NAME} configured.${NC}"
    else
        echo -e "${YELLOW}Repos missing ${SECRET_NAME}:${NC}"
        for repo in "${missing[@]}"; do
            echo -e "  - ${ORG}/${repo}"
        done
    fi
    exit 0
fi

# Check for .env file
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "  Copy .env.example to .env and add your PAT"
    exit 1
fi

# Load .env
source "$ENV_FILE"

if [[ -z "$REPO_PROJECTS_PAT" || "$REPO_PROJECTS_PAT" == "ghp_xxxxxxxxxxxxxxxxxxxx" ]]; then
    echo -e "${RED}Error: REPO_PROJECTS_PAT not configured in .env${NC}"
    exit 1
fi

PAT_VALUE="$REPO_PROJECTS_PAT"

dry_run "${REPOS[@]}"
confirm

for repo in "${REPOS[@]}"; do
    setup_token_for_repo "$repo"
done

echo -e "${GREEN}All repositories configured!${NC}"
