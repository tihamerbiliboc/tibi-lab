#!/usr/bin/env bash
# Publish site/ to tibi-lab.com (Simply.com Windows webhotel, FTP host ftp.simply.com).
#
# Uploads over encrypted FTP (FTPS) as user tibi-lab.com into public_html/. Only files
# that changed since the server's copy are uploaded; files that are not in site/ are
# removed from the server (except .well-known/).
#
# Safety checks, so the live site is always what is on origin/main:
#   - publishes only from main, with no uncommitted changes, and in sync with origin/main
#   - on the Mac it first shows what would change and asks before publishing
#   - refuses if a page is missing or site/ looks broken
#
# Password (the webhotel's FTP password, Simply.com → tibi-lab.com → Loginoplysninger):
#   - in GitHub Actions: the repo secret FTP_PASSWORD, passed in as LFTP_PASSWORD
#   - on the Mac: the Keychain item "tibi-lab-ftp", which you create once with
#       security add-generic-password -a tibi-lab.com -s tibi-lab-ftp -w
#
# Usage: ./deploy.sh            check, show the changes, ask, publish
#        ./deploy.sh --dry-run  show what would change, upload nothing (no git checks)
set -euo pipefail

cd "$(dirname "$0")"

fail() { echo "✗ $*" >&2; echo "  Nothing was published." >&2; exit 1; }

DRY_RUN=false
case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=true ;;
  *) fail "Unknown option: $1 (use --dry-run or nothing)" ;;
esac

command -v lftp >/dev/null || fail "lftp is not installed (Mac: brew install lftp)"

# The site must look complete, so --delete can never wipe the server.
for f in index.html legal.html favicon.svg; do
  test -s "site/$f" || fail "Missing or empty: site/$f"
done
grep -qi '</html>' site/index.html || fail "site/index.html looks cut off (no </html>)"

# Publish only what is on origin/main.
if ! $DRY_RUN; then
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    [[ "${GITHUB_REF:-}" == "refs/heads/main" ]] || fail "GitHub deploys run only from main (this is ${GITHUB_REF:-unknown})"
  else
    branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$branch" == "main" ]] || fail "You are on '$branch'. Merge into main, push, and deploy from main."
    [[ -z "$(git status --porcelain -- site deploy.sh)" ]] || fail "site/ or deploy.sh has uncommitted changes. Commit and push them first."
    git fetch -q origin main || fail "Could not reach GitHub to check origin/main"
    [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] \
      || fail "Local main and origin/main differ. Pull or push first, so the site matches GitHub."
  fi
fi

if [[ -z "${LFTP_PASSWORD:-}" ]] && command -v security >/dev/null; then
  LFTP_PASSWORD="$(security find-generic-password -s tibi-lab-ftp -w 2>/dev/null || true)"
fi
[[ -n "${LFTP_PASSWORD:-}" ]] || fail "No FTP password: set LFTP_PASSWORD or the Keychain item tibi-lab-ftp"
export LFTP_PASSWORD

mirror() {
  lftp -c "
    set ftp:ssl-force true; set ftp:ssl-protect-data true; set ssl:verify-certificate true;
    set net:max-retries 2; set net:timeout 30; set cmd:fail-exit true;
    open --env-password -u tibi-lab.com ftp://ftp.simply.com;
    cd public_html;
    mirror --reverse --delete --only-newer --no-perms --verbose --parallel=4 $1 --exclude-glob .well-known/ site/ .
  "
}

# What would change: uploads and deletions, one per line.
changes() {
  mirror --dry-run | awk '
    /^Transferring file/ { gsub(/[`\x27]/, "", $3); up[$3]=1; print "  upload  " $3 }
    /^Removing old file/ { gsub(/[`\x27]/, "", $4); rm[$4]=1 }
    END { for (f in rm) if (!(f in up)) print "  DELETE  " f }'
}

if $DRY_RUN; then
  list="$(changes)"
  echo "${list:-  nothing to change}"
  echo "Dry run: nothing was published."
  exit 0
fi

if [[ -t 0 ]]; then
  list="$(changes)"
  [[ -n "$list" ]] || { echo "The live site already matches main. Nothing to publish."; exit 0; }
  echo "These changes will go live on https://tibi-lab.com/:"
  echo "$list"
  read -r -p "Publish? [y/N] " answer
  [[ "$answer" == [yY] ]] || { echo "Cancelled. Nothing was published."; exit 0; }
fi

mirror ""
echo "Published to https://tibi-lab.com/"
