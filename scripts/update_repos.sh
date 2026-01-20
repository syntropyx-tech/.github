#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

DEFAULT_LIST="${SCRIPT_DIR}/repo_list.txt"

usage() {
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  --list <filename>    Repo list file (default: repo_list.txt)"
    echo "  --test               Test run on ${ORG}/${TEST_REPO} only"
    echo "  --labels-only        Only run label setup"
    echo "  --workflow-only      Only run workflow migration"
    echo "  -h, --help           Show this help"
    exit 1
}

LIST_FILE="$DEFAULT_LIST"
RUN_LABELS=true
RUN_WORKFLOW=true
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
        --labels-only) RUN_WORKFLOW=false; shift ;;
        --workflow-only) RUN_LABELS=false; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

if $TEST_MODE; then
    test_mode_banner
    echo -e "${BLUE}Repository Update (TEST)${NC}"
    echo -e "  Target: ${ORG}/${TEST_REPO}"
    echo -e "  Labels: $($RUN_LABELS && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
    echo -e "  Workflow: $($RUN_WORKFLOW && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
    echo ""

    if $RUN_LABELS; then
        echo -e "${BLUE}=== Label Setup ===${NC}"
        "${SCRIPT_DIR}/_setup-labels.sh" --test
        echo ""
    fi

    if $RUN_WORKFLOW; then
        echo -e "${BLUE}=== Workflow Migration ===${NC}"
        "${SCRIPT_DIR}/_migrate_auto_labeler_workflow.sh" --test
        echo ""
    fi
else
    [[ ! -f "$LIST_FILE" ]] && { echo -e "${RED}Error: File not found: $LIST_FILE${NC}"; exit 1; }

    REPO_COUNT=$(grep -cv '^\s*#\|^\s*$' "$LIST_FILE" || echo 0)

    echo -e "${BLUE}Repository Update${NC}"
    echo -e "  List: $LIST_FILE ($REPO_COUNT repos)"
    echo -e "  Labels: $($RUN_LABELS && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
    echo -e "  Workflow: $($RUN_WORKFLOW && echo "${GREEN}yes${NC}" || echo "${YELLOW}skip${NC}")"
    echo ""

    if $RUN_LABELS; then
        echo -e "${BLUE}=== Label Setup ===${NC}"
        "${SCRIPT_DIR}/_setup-labels.sh" --list "$LIST_FILE"
        echo ""
    fi

    if $RUN_WORKFLOW; then
        echo -e "${BLUE}=== Workflow Migration ===${NC}"
        "${SCRIPT_DIR}/_migrate_auto_labeler_workflow.sh" --list "$LIST_FILE"
        echo ""
    fi
fi

echo -e "${GREEN}All tasks complete.${NC}"
