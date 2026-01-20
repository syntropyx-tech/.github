#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

DEFAULT_LIST="${SCRIPT_DIR}/repo_list.txt"
ENV_FILE="${SCRIPT_DIR}/.env"

usage() {
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  --list <filename>    Repo list file (default: repo_list.txt)"
    echo "  --test               Test run on ${ORG}/${TEST_REPO} only"
    echo "  --labels-only        Only run label setup"
    echo "  --workflow-only      Only run workflow migration"
    echo "  --with-tokens        Also set up REPO_PROJECTS_PAT secrets"
    echo "  -h, --help           Show this help"
    exit 1
}

check_token_status() {
    local -n repos_to_check=$1

    echo -e "${CYAN}Checking REPO_PROJECTS_PAT status...${NC}"

    local missing_repos=()
    for repo in "${repos_to_check[@]}"; do
        local repo_name="${repo##*/}"
        if ! repo_has_secret "$repo_name" "REPO_PROJECTS_PAT" 2>/dev/null; then
            missing_repos+=("$repo_name")
        fi
    done

    if [[ ${#missing_repos[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ All repos have REPO_PROJECTS_PAT configured${NC}"
        return 0
    fi

    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║              TOKEN WARNING                           ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  The following repos are missing REPO_PROJECTS_PAT:  ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${NC}"
    for repo in "${missing_repos[@]}"; do
        printf "${YELLOW}║${NC}  - %-48s ${YELLOW}║${NC}\n" "${ORG}/${repo}"
    done
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  Project automation won't work without this token.   ║${NC}"
    echo -e "${YELLOW}║                                                      ║${NC}"
    echo -e "${YELLOW}║  To fix: run with --with-tokens (requires .env)      ║${NC}"
    echo -e "${YELLOW}║  Or: ./_setup_repo_token.sh --list repo_list.txt     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check if .env exists
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        if [[ -n "$REPO_PROJECTS_PAT" && "$REPO_PROJECTS_PAT" != "ghp_xxxxxxxxxxxxxxxxxxxx" ]]; then
            echo -e "${CYAN}Note: .env is configured. Use --with-tokens to set up secrets.${NC}"
        else
            echo -e "${CYAN}Note: .env exists but PAT not configured.${NC}"
        fi
    else
        echo -e "${CYAN}Note: Copy .env.example to .env to configure token setup.${NC}"
    fi
    echo ""

    read -p "Continue without token setup? (Y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi
    echo ""
    return 1
}

LIST_FILE="$DEFAULT_LIST"
RUN_LABELS=true
RUN_WORKFLOW=true
RUN_TOKENS=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test) TEST_MODE=true; shift ;;
        --with-tokens) RUN_TOKENS=true; shift ;;
        --list)
            [[ -z "$2" || "$2" == -* ]] && { echo -e "${RED}Error: --list requires a filename${NC}"; exit 1; }
            LIST_FILE="$2"
            shift 2
            ;;
        --labels-only) RUN_WORKFLOW=false; shift ;;
        --workflow-only) RUN_LABELS=false; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

# Build repo list
REPOS=()
if $TEST_MODE; then
    REPOS=("${TEST_REPO}")
else
    [[ ! -f "$LIST_FILE" ]] && { echo -e "${RED}Error: File not found: $LIST_FILE${NC}"; exit 1; }
    read_repo_list "$LIST_FILE" REPOS false
fi

echo -e "${BLUE}Checking requirements...${NC}"
check_gh || exit 1
echo ""

# Check token status (unless running with --with-tokens)
if ! $RUN_TOKENS; then
    check_token_status REPOS || true
fi

if $TEST_MODE; then
    test_mode_banner
    echo -e "${BLUE}Repository Update (TEST)${NC}"
    echo -e "  Target: ${ORG}/${TEST_REPO}"
else
    REPO_COUNT=${#REPOS[@]}
    echo -e "${BLUE}Repository Update${NC}"
    echo -e "  List: $LIST_FILE ($REPO_COUNT repos)"
fi

echo -e "  Labels: $($RUN_LABELS && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
echo -e "  Workflow: $($RUN_WORKFLOW && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
echo -e "  Tokens: $($RUN_TOKENS && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
echo ""

if $RUN_TOKENS; then
    echo -e "${BLUE}=== Token Setup ===${NC}"
    if $TEST_MODE; then
        "${SCRIPT_DIR}/_setup_repo_token.sh" --test
    else
        "${SCRIPT_DIR}/_setup_repo_token.sh" --list "$LIST_FILE"
    fi
    echo ""
fi

if $RUN_LABELS; then
    echo -e "${BLUE}=== Label Setup ===${NC}"
    if $TEST_MODE; then
        "${SCRIPT_DIR}/_setup-labels.sh" --test
    else
        "${SCRIPT_DIR}/_setup-labels.sh" --list "$LIST_FILE"
    fi
    echo ""
fi

if $RUN_WORKFLOW; then
    echo -e "${BLUE}=== Workflow Migration ===${NC}"
    if $TEST_MODE; then
        "${SCRIPT_DIR}/_migrate_auto_labeler_workflow.sh" --test
    else
        "${SCRIPT_DIR}/_migrate_auto_labeler_workflow.sh" --list "$LIST_FILE"
    fi
    echo ""
fi

echo -e "${GREEN}All tasks complete.${NC}"
