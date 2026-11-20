# Tibi Lab

The tibi-lab.com website. The live pages are in `site/`, early design concepts in `mockups/`.

## Publishing
Every push to `main` that changes `site/` publishes it: the GitHub Action `.github/workflows/deploy.yml` runs `deploy.sh`, which uploads changed files from `site/` to `public_html/` on Simply.com over encrypted FTP. Files that are not in `site/` are removed from the server (`.well-known/` is left alone).

From the Mac: `./deploy.sh --dry-run` lists what would change. `./deploy.sh` publishes, but only from `main` with everything committed and pushed, so the live site always matches GitHub; it shows the changes and asks before uploading. It needs `brew install lftp`.

## Setup (once)
- **tibi-lab.com** is a Windows webhotel on Simply.com (web server `nt7.unoeuro.com`); FTP host `ftp.simply.com`, user `tibi-lab.com`. The password is the webhotel password from Simply.com → tibi-lab.com → Loginoplysninger.
- GitHub: `gh secret set FTP_PASSWORD` (paste the password when asked).
- Mac: `security add-generic-password -a tibi-lab.com -s tibi-lab-ftp -w` (paste the password when asked).
- If you change the password at Simply, update both.
