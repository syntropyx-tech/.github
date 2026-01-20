#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

declare -A LABELS=(
    ["bug"]="d73a4a|Something isn't working"
    ["feature"]="a2eeef|New feature request"
    ["chore"]="fef2c0|Maintenance task"
    ["spike"]="d4c5f9|Research or investigation"
    ["refactor"]="fbca04|Code improvement"
    ["admin"]="5319e7|Administrative tasks"
    ["api"]="0052cc|API related"
    ["devops"]="f9a825|Infrastructure or CI/CD"
    ["ui"]="e91e63|User interface"
    ["quant"]="17a2b8|Quantitative analysis or data"
    ["contracts"]="6f42c1|Smart contracts"
)

DEFAULT_LABELS=(
    "documentation" "duplicate" "enhancement" "good first issue"
    "help wanted" "invalid" "question" "wontfix"
)

usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 <owner/repo>              Setup labels for a single repository"
    echo "  $0 --list <filename>         Setup labels for all repos in file"
    echo "  $0 --test                    Test run on ${ORG}/${TEST_REPO} only"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 syntropyx-tech/my-repo"
    echo "  $0 --list repo_list.txt"
    echo "  $0 --test"
    exit 1
}

setup_labels_for_repo() {
    local REPO=$1
    echo -e "${BLUE}Setting up labels for ${REPO}...${NC}"

    for label in "${!LABELS[@]}"; do
        IFS='|' read -r color description <<< "${LABELS[$label]}"
        if gh label create "$label" --color "$color" --description "$description" --repo "$REPO" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Created:${NC} $label"
        else
            gh label edit "$label" --color "$color" --description "$description" --repo "$REPO" 2>/dev/null && \
                echo -e "  ${YELLOW}↻ Updated:${NC} $label" || \
                echo -e "  ${RED}✗ Failed:${NC} $label"
        fi
    done

    for label in "${DEFAULT_LABELS[@]}"; do
        gh label delete "$label" --repo "$REPO" --yes 2>/dev/null && \
            echo -e "  ${YELLOW}✗ Removed:${NC} $label" || true
    done

    echo -e "${GREEN}Done with ${REPO}${NC}"
    echo ""
}

dry_run() {
    local repos=("$@")
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}           DRY RUN SUMMARY            ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${YELLOW}Repositories (${#repos[@]}):${NC}"
    for repo in "${repos[@]}"; do echo "  - $repo"; done
    echo ""
    echo -e "${YELLOW}Labels to create/update:${NC} bug, feature, chore, spike, refactor, admin, api, devops, ui, quant, contracts"
    echo -e "${YELLOW}Labels to remove:${NC} documentation, duplicate, enhancement, etc."
    echo -e "${BLUE}======================================${NC}"
}

# Parse arguments
REPOS=()
LIST_FILE=""
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TEST_MODE=true
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
    REPOS=("${ORG}/${TEST_REPO}")
elif [[ -n "$LIST_FILE" ]]; then
    read_repo_list "$LIST_FILE" REPOS true
fi

[[ ${#REPOS[@]} -eq 0 ]] && usage

echo -e "${BLUE}Checking requirements...${NC}"
check_gh || exit 1

dry_run "${REPOS[@]}"
confirm

for repo in "${REPOS[@]}"; do
    setup_labels_for_repo "$repo"
done

echo -e "${GREEN}All repositories configured!${NC}"
