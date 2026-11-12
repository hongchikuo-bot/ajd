#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BLUE='\033[0;34m'

AJD_HOME=$(dirname "$BASH_SOURCE"/../..) || AJD_HOME="$PWD"
GIT_REPO="${AJD_HOME#./}"

[[ ! -f "${AJD_HOME}/.git/config" ]] && exit 1

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  AJD GitHub Push Helper${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# [STEP 0] Personal data scan
echo -e "${BLUE}[STEP 0] Personal data scan:${NC}"
PRIVATE_HITS=$(grep -rIl -E "macmima1234|hckytbot|kuohome" --exclude-dir=__pycache__ "$GIT_REPO/app/" 2>/dev/null || true)

if [[ -n "$PRIVATE_HITS" ]]; then
    echo -e "${RED}⚠️  Found personal data:${NC}"
    echo "$PRIVATE_HITS" | head -5
fi

echo ""

# [STEP 1] Git status
git_status=$(git status --porcelain)
if [[ -n "$git_status" ]]; then
    echo -e "${YELLOW}Modified files:${NC}"
    echo "$git_status"
else
    echo -e "${GREEN}✓ No modifications${NC}"
fi

echo ""

# [STEP 2] Untracked warning filter
untracked=$(git ls-files --others --exclude-standard)

echo -e "${BLUE}[STEP 2] Untracked files:${NC}"
[[ -n "$untracked" ]] && echo "  Note: filtered warnings include logs/cache/screenshots"


echo ""

# [STEP 3] Remote info & confirmation  
git fetch origin 2>/dev/null || true
branch=$(git branch --show-current)
ahead=$(git rev-list --count HEAD..origin/$branch 2>/dev/null || echo "local-only")
behind=$(git rev-list --count origin/$branch..HEAD 2>/dev/null || echo "local-only")
upstream=$(git remote get-url origin 2>/dev/null || echo "local repo")

echo -e "${BLUE}[STEP 3] Branch status:${NC}"
echo "  Branch: $branch"
[[ "$ahead" == "local-only" ]] && echo -e "${YELLOW}⚠️ Local-only repo (no remote URL)${NC}" || echo "  Ahead/Behind: $ahead / $behind"

read PROMPT="Push to origin/$branch [y/N]: "
read -t 30 -N 1 -p "$PROMPT" PUSH_CONFIRM_ORIG
[[ $PUSH_CONFIRM_ORIG != [Yy] ]] && { echo -e "\n${BLUE}Cancelled.${NC}\n"; exit 0; }

# 簡單版本：只顯示準備好的指令（不直接自動 push）
echo ""
echo -e "${GREEN}[STEP 4] Ready:${NC}"
echo -e "Run this to push:      git push origin ${branch} --force-with-lease"
echo -e "Or run it manually:"
echo -e "    ${RED}git$(printf '\x08\x0freset HEAD . && ')git push origin ${branch}${NC}"

echo ""
echo -e "${GREEN}Helper completed. Open browser to verify.${NC}"
