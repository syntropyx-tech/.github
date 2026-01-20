#!/bin/bash
# Shared library for automation scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
ORG="syntropyx-tech"
TEST_REPO=".github"

# Test mode banner
test_mode_banner() {
    echo -e "${YELLOW}╔══════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           TEST MODE ENABLED          ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  Only running on: ${ORG}/${TEST_REPO}${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════╝${NC}"
    echo ""
}

# Check if a repo has a specific secret
repo_has_secret() {
    local repo="$1"
    local secret="${2:-REPO_PROJECTS_PAT}"
    gh secret list --repo "${ORG}/${repo}" 2>/dev/null | grep -q "^${secret}" && return 0 || return 1
}

# Check repos for missing REPO_PROJECTS_PAT, returns space-separated list
get_repos_missing_token() {
    local -n repos_ref=$1
    local missing=()
    for repo in "${repos_ref[@]}"; do
        # Strip org prefix if present
        local repo_name="${repo##*/}"
        if ! repo_has_secret "$repo_name" "REPO_PROJECTS_PAT"; then
            missing+=("$repo_name")
        fi
    done
    echo "${missing[*]}"
}

# Confirm prompt (Y/N)
confirm() {
    echo ""
    read -p "Do you want to proceed? (Y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi
    echo ""
}

# Check if gh CLI is installed and authenticated
check_gh() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
        echo "  Install from: https://cli.github.com/"
        return 1
    fi
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI is not authenticated${NC}"
        echo "  Run: gh auth login"
        return 1
    fi
    echo -e "${GREEN}✓ GitHub CLI installed and authenticated${NC}"
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Git is installed${NC}"
}

# Read repos from file into REPOS array
# Usage: read_repo_list "filename" REPOS
# Skips comments (#) and empty lines, adds org prefix if missing
read_repo_list() {
    local file="$1"
    local -n arr="$2"
    local add_org="${3:-true}"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if [[ "$add_org" == "true" && "$line" != *"/"* ]]; then
            arr+=("${ORG}/${line}")
        else
            arr+=("$line")
        fi
    done < "$file"
}

# Parse --list argument, returns filename or empty
# Usage: parse_list_arg "$@"
parse_list_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo -e "${RED}Error: --list requires a filename${NC}" >&2
                    return 1
                fi
                echo "$2"
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done
}
