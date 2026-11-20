#!/usr/bin/env bash
# Publish site/ to tibi-lab.com (Simply.com Windows webhotel, FTP host ftp.simply.com).
#
# Uploads over encrypted FTP (FTPS) as user tibi-lab.com into public_html/ and mirrors it
# exactly: files that are not in site/ are removed from the server (except .well-known/).
#
# Password (the webhotel's FTP password, Simply.com → tibi-lab.com → Loginoplysninger):
#   - in GitHub Actions: the repo secret FTP_PASSWORD, passed in as LFTP_PASSWORD
#   - on the Mac: the Keychain item "tibi-lab-ftp", which you create once with
#       security add-generic-password -a tibi-lab.com -s tibi-lab-ftp -w
#
# Usage: ./deploy.sh            publish
#        ./deploy.sh --dry-run  show what would change, upload nothing
set -euo pipefail

cd "$(dirname "$0")"

DRY_RUN=""
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN="--dry-run"

command -v lftp >/dev/null || { echo "lftp is not installed (Mac: brew install lftp)"; exit 1; }

for f in index.html legal.html favicon.svg; do
  test -s "site/$f" || { echo "Missing or empty: site/$f — nothing published"; exit 1; }
done

if [[ -z "${LFTP_PASSWORD:-}" ]] && command -v security >/dev/null; then
  LFTP_PASSWORD="$(security find-generic-password -s tibi-lab-ftp -w 2>/dev/null || true)"
fi
[[ -n "${LFTP_PASSWORD:-}" ]] || { echo "No FTP password: set LFTP_PASSWORD or the Keychain item tibi-lab-ftp"; exit 1; }
export LFTP_PASSWORD

lftp -c "
  set ftp:ssl-force true; set ftp:ssl-protect-data true; set ssl:verify-certificate true;
  set net:max-retries 2; set net:timeout 30; set cmd:fail-exit true;
  open --env-password -u tibi-lab.com ftp://ftp.simply.com;
  mirror --reverse --delete --no-perms --verbose --parallel=4 $DRY_RUN --exclude-glob .well-known/ site/ public_html/
"

echo "Published to https://tibi-lab.com/${DRY_RUN:+ (dry run, nothing changed)}"
